import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class GameController {
    private let modelContext: ModelContext
    private let gatheringService: GatheringService
    private let craftingService = CraftingService()
    private let combatService = CombatService()
    private let workerProductionService = WorkerProductionService()
    private var workerProgress: [ResourceSpotKind: TimeInterval] = [:]
    private var yieldRemainders: [String: Double] = [:]
    private var workerTask: Task<Void, Never>?
    private var cooldownTask: Task<Void, Never>?

    private(set) var inventory: InventoryService
    private(set) var skills: [SkillKind: SkillProgress] = [:]
    private(set) var workerPool: WorkerPool
    private(set) var playerCombat: PlayerCombatState
    private(set) var playerRecord: PlayerRecord
    private(set) var lastGatherResult: GatheringResult?
    private(set) var lastCombatResult: CombatResult?
    private(set) var liveBattle: LiveBattle?
    private(set) var goldNotice: Int?
    private(set) var statusNotice: String?
    private var goldNoticeGeneration = 0
    private var statusNoticeGeneration = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        InventoryService.migrateRetiredItems(in: modelContext)
        let rewardManager = RewardManager()
        self.gatheringService = GatheringService(rewardManager: rewardManager)
        self.inventory = InventoryService(
            modelContext: modelContext,
            storedEntries: InventoryService.loadEntries(from: modelContext)
        )
        self.skills = Self.loadOrCreateSkills(in: modelContext)
        self.workerPool = Self.loadOrCreateWorkerPool(in: modelContext)
        self.playerCombat = Self.loadOrCreateCombatState(in: modelContext)
        self.playerRecord = Self.loadOrCreatePlayerRecord(in: modelContext)
        self.workerPool.sanitizeStorage()
        forgetRetiredTasks()
        detachEquippedCopiesFromInventory()
        if workerPool.gardenAssigned > 0 {
            workerPool.gardenAssigned = 0
        }
    }

    func bootstrap() {
        if ResourceSpotKind.allCases.contains(where: { workerPool.assignedCount(for: $0) > 0 }) {
            playerRecord.hasAssignedWorker = true
        }
        startWorkerLoop()
        startCooldownLoopIfNeeded()
        save()
    }

    func stop() {
        workerTask?.cancel()
        cooldownTask?.cancel()
        workerTask = nil
        cooldownTask = nil
        save()
    }

    var equippedWeapon: InventoryItemID? {
        playerCombat.equippedItem(in: .weapon)
    }

    var inventoryCapacity: Int {
        playerRecord.inventoryCapacity
    }

    var playerAttackPower: Int {
        let gear = equippedWeapon.flatMap { EquipmentCatalog.definition(for: $0) }?.bonuses
        return CombatDamage.meleeMaxHit(
            attackLevel: skillLevel(for: .attack),
            strengthLevel: skillLevel(for: .strength),
            weaponAttack: gear?.attack ?? 0,
            weaponStrength: gear?.strength ?? 0,
            attackBoost: isBoostActive(playerRecord.attackBoostEnd) ? FarmingCatalog.attackBonus : 0,
            strengthBoost: isBoostActive(playerRecord.strengthBoostEnd) ? FarmingCatalog.strengthBonus : 0
        )
    }

    var skinTone: CharacterSkinTone { CharacterSkinTone(rawValue: playerRecord.skinToneRaw ?? "") ?? .warm }
    var clothingTone: CharacterClothingTone { CharacterClothingTone(rawValue: playerRecord.clothingToneRaw ?? "") ?? .forest }

    func customizeCharacter(skin: CharacterSkinTone, clothing: CharacterClothingTone) {
        playerRecord.skinToneRaw = skin.rawValue
        playerRecord.clothingToneRaw = clothing.rawValue
        save()
    }

    var combatLevel: Int { skillLevel(for: .combat) }
    var playerCombatHealth: Int { 20 + combatLevel * 2 }
    var playerCombatDefense: Int {
        let slots: [EquipmentSlot] = [.helmet, .chest, .legs, .boots, .shield]
        let bonus = slots.reduce(0) { total, slot in
            total + (equippedItem(in: slot).flatMap { EquipmentCatalog.definition(for: $0) }?.bonuses.defense ?? 0)
        }
        var defense = bonus + max(0, skillLevel(for: .defense) / 3)
        if isBoostActive(playerRecord.defenseBoostEnd) { defense += FarmingCatalog.defenseBonus }
        return defense
    }

    var currentHitPoints: Int {
        let maxHP = playerCombatHealth
        guard let stored = playerCombat.currentHealth else { return maxHP }
        return min(maxHP, max(0, stored))
    }

    var combatStyle: CombatStyle {
        CombatStyle(rawValue: playerCombat.combatStyleRaw ?? "") ?? .melee
    }

    var selectedSpell: SpellDefinition? {
        if let id = playerCombat.selectedSpellRaw, let spell = MagicCatalog.spell(id: id) {
            return spell
        }
        return MagicCatalog.spells.first
    }

    var isCombatOnCooldown: Bool {
        combatCooldownRemaining > 0
    }

    var combatCooldownRemaining: TimeInterval {
        guard let end = playerCombat.combatCooldownEndTimestamp else { return 0 }
        return max(0, end.timeIntervalSinceNow)
    }

    var combatCooldownLabel: String {
        let remaining = Int(ceil(combatCooldownRemaining))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func progress(for skill: SkillKind) -> SkillLevelProgress {
        let totalXP = skills[skill]?.totalXP ?? 0
        return SkillProgressService.progress(forTotalXP: totalXP)
    }

    func skillLevel(for skill: SkillKind) -> Int {
        progress(for: skill).level
    }

    func canGather(_ resource: ResourceDefinition) -> Bool {
        resource.isPlayable && skillLevel(for: resource.skill) >= resource.requiredLevel
    }

    func ownedWorkerCount(for listing: StoreListing) -> Int {
        guard listing.product == .worker else { return 0 }
        return workerPool.ownedCount
    }

    func price(for listing: StoreListing) -> Int {
        listing.price(backpackTier: playerRecord.backpackTier)
    }

    var totalLevel: Int {
        SkillKind.allCases.reduce(0) { total, skill in
            total + skillLevel(for: skill)
        }
    }

    var workerCap: Int {
        totalLevel >= WorkerBalance.expandedUnlockTotalLevel
            ? WorkerBalance.expandedWorkerCap
            : WorkerBalance.baseWorkerCap
    }

    var workerCapNotice: String? {
        guard workerCap == WorkerBalance.baseWorkerCap else { return nil }
        return "Reach Total Level \(WorkerBalance.expandedUnlockTotalLevel) to unlock \(WorkerBalance.expandedWorkerCap) workers."
    }

    func storeStatus(for listing: StoreListing) -> String? {
        if let required = listing.requiredTotalLevel {
            return "Total Level \(totalLevel) / \(required)"
        }
        return switch listing.product {
        case .worker:
            "Workers: \(workerPool.ownedCount) / \(workerCap)"
        case .backpackUpgrade:
            "Capacity \(playerRecord.inventoryCapacity)"
        case .inventoryItem:
            nil
        }
    }

    func purchaseCost(_ listing: StoreListing, quantity: Int) -> Int {
        guard quantity > 0 else { return 0 }
        switch listing.product {
        case .backpackUpgrade:
            var total = 0
            for offset in 0..<quantity {
                total += listing.goldCost * (playerRecord.backpackTier + offset + 1)
            }
            return total
        default:
            return price(for: listing) * quantity
        }
    }

    func maxPurchaseQuantity(for listing: StoreListing) -> Int {
        guard meetsStoreRequirements(listing) else { return 0 }
        let gold = inventory.quantity(of: .gold)
        switch listing.product {
        case .backpackUpgrade:
            var remaining = gold
            var tier = playerRecord.backpackTier
            var count = 0
            while true {
                let nextPrice = listing.goldCost * (tier + 1)
                guard nextPrice > 0, remaining >= nextPrice else { break }
                remaining -= nextPrice
                tier += 1
                count += 1
            }
            return count
        case .worker:
            let unit = price(for: listing)
            guard unit > 0 else { return 0 }
            let affordable = gold / unit
            let slots = max(0, workerCap - workerPool.ownedCount)
            return min(affordable, slots)
        case .inventoryItem:
            let unit = price(for: listing)
            guard unit > 0 else { return 0 }
            return gold / unit
        }
    }

    func canPurchase(_ listing: StoreListing, quantity: Int) -> Bool {
        quantity > 0 && quantity <= maxPurchaseQuantity(for: listing)
    }

    func purchase(_ listing: StoreListing, quantity: Int) {
        let qty = min(quantity, maxPurchaseQuantity(for: listing))
        guard qty > 0 else { return }
        let cost = purchaseCost(listing, quantity: qty)
        guard inventory.remove(.gold, amount: cost) else { return }

        switch listing.product {
        case .worker:
            workerPool.ownedCount += qty * listing.quantity
        case .inventoryItem(let item):
            inventory.add(item, amount: qty * listing.quantity)
            noteAcquired(item)
            playerRecord.hasPurchasedNonWorkerItem = true
        case .backpackUpgrade:
            playerRecord.backpackTier += qty * listing.quantity
            playerRecord.inventoryCapacity += PlayerProgression.backpackCapacityPerTier * qty * listing.quantity
            playerRecord.hasPurchasedNonWorkerItem = true
        }

        save()
    }

    private func meetsStoreRequirements(_ listing: StoreListing) -> Bool {
        if let skill = listing.requiredSkill, let level = listing.requiredSkillLevel {
            guard skillLevel(for: skill) >= level else { return false }
        }
        if let requiredTotal = listing.requiredTotalLevel {
            guard totalLevel >= requiredTotal else { return false }
        }
        if let prerequisiteID = listing.prerequisiteID {
            guard owns(prerequisiteID: prerequisiteID) else { return false }
        }
        return true
    }

    private func owns(prerequisiteID: String) -> Bool {
        guard let listing = StoreCatalog.listing(id: prerequisiteID) else { return false }
        switch listing.product {
        case .worker:
            return workerPool.ownedCount > 0
        case .inventoryItem(let item):
            return inventory.quantity(of: item) > 0
        case .backpackUpgrade:
            return playerRecord.backpackTier > 0
        }
    }

    var unassignedWorkerCount: Int {
        workerPool.unassignedCount
    }

    func selectedWorkerResource(for spot: ResourceSpotKind) -> ResourceDefinition? {
        workerPool.selectedResource(for: spot)
    }

    func selectWorkerResource(_ resource: ResourceDefinition) {
        guard canGather(resource), selectedWorkerResource(for: resource.spot)?.id != resource.id else { return }
        workerPool.selectResource(resource)
        workerProgress[resource.spot] = 0
        save()
    }

    func assignedWorkers(for spot: ResourceSpotKind) -> Int {
        workerPool.assignedCount(for: spot)
    }

    func canAssignWorker(to spot: ResourceSpotKind) -> Bool {
        workerPool.unassignedCount > 0
    }

    func assignWorker(to spot: ResourceSpotKind) {
        guard canAssignWorker(to: spot) else { return }
        guard workerPool.assignedCount(for: spot) < gatheringNodes(for: spot).count else { return }
        workerPool.setAssignedCount(workerPool.assignedCount(for: spot) + 1, for: spot)
        playerRecord.hasAssignedWorker = true
        save()
    }

    func canRemoveWorker(from spot: ResourceSpotKind) -> Bool {
        workerPool.assignedCount(for: spot) > 0
    }

    func removeWorker(from spot: ResourceSpotKind) {
        guard canRemoveWorker(from: spot) else { return }
        workerPool.setAssignedCount(workerPool.assignedCount(for: spot) - 1, for: spot)
        save()
    }

    func performManualGather(_ resource: ResourceDefinition) {
        guard canGather(resource) else { return }

        var generator = SystemRandomNumberGenerator()
        let result = gatheringService.performManualGather(
            resource: resource,
            inventory: inventory,
            using: &generator
        )

        for drop in result.itemDrops {
            noteAcquired(drop.item)
        }
        if isBoostActive(playerRecord.gatherBoostEnd) {
            inventory.add(resource.primaryOutput, amount: resource.primaryAmount)
            noteAcquired(resource.primaryOutput)
        }
        if let skill = skills[resource.skill] {
            SkillProgressService.addXP(result.xpGained, to: skill)
        }

        lastGatherResult = result
        recordGoldGain(goldAmount(in: result.itemDrops))
        save()
    }

    func canCraft(_ recipe: CraftingRecipeDefinition) -> Bool {
        craftingService.canCraft(recipe, inventory: inventory, skills: skills)
    }

    @discardableResult
    func craft(_ recipe: CraftingRecipeDefinition) -> Bool {
        guard craftingService.craft(recipe, inventory: inventory, skills: skills) else { return false }
        if recipe.skillXP > 0, let requiredSkill = recipe.requiredSkill, let skill = skills[requiredSkill] {
            SkillProgressService.addXP(recipe.skillXP, to: skill)
        }
        lastGatherResult = nil
        save()
        return true
    }

    func canFight(_ enemy: EnemyDefinition) -> Bool {
        fightBlockReason(enemy) == nil
    }

    func fightBlockReason(_ enemy: EnemyDefinition) -> String? {
        if !combatService.canFight(enemy, combatLevel: combatLevel, isOnCooldown: isCombatOnCooldown) {
            if isCombatOnCooldown { return "Recovering from the last fight." }
            return "Requires Combat Level \(enemy.requiredCombatLevel)."
        }
        return nil
    }

    /// Resolves one fight with the existing combat math and applies rewards once.
    /// A second call during the cooldown returns nil so loot cannot be granted twice.
    func resolveFight(_ enemy: EnemyDefinition) -> CombatResult? {
        guard canFight(enemy) else { return nil }

        var generator = SystemRandomNumberGenerator()
        let result = combatService.resolveFight(
            enemy: enemy,
            playerAttackPower: playerAttackPower,
            playerHealth: currentHitPoints,
            playerDefense: playerCombatDefense,
            using: &generator
        )

        if result.victory {
            inventory.apply(drops: result.drops)
            for drop in result.drops {
                noteAcquired(drop.item)
            }
            recordGoldGain(goldAmount(in: result.drops))
            let combatSkills: [SkillKind] = [.combat, .attack, .strength, .defense]
            for kind in combatSkills {
                if let skill = skills[kind] {
                    SkillProgressService.addXP(result.xpGained, to: skill)
                }
            }
            playerCombat.currentHealth = result.remainingHealth
        } else {
            playerCombat.currentHealth = max(1, playerCombatHealth / 5)
        }
        playerCombat.combatCooldownEndTimestamp = Date.now.addingTimeInterval(CombatBalance.globalCooldownSeconds)
        startCooldownLoopIfNeeded()

        lastCombatResult = result
        save()
        return result
    }

    func beginLiveBattle(_ enemy: EnemyDefinition) -> Bool {
        guard canFight(enemy) else { return false }
        liveBattle = LiveBattle(
            enemy: enemy,
            enemyHP: enemy.health,
            playerHP: currentHitPoints,
            maxPlayerHP: playerCombatHealth,
            message: "Choose Attack or Magic.",
            magicXP: 0,
            usedMelee: false,
            rounds: 0,
            finished: false,
            victory: false,
            drops: [],
            lastEnemyDamage: 0,
            lastPlayerDamage: 0
        )
        return true
    }

    func liveMeleeStrike() {
        guard var battle = liveBattle, !battle.finished else { return }
        var damages: [Int] = []
        var hits = 0
        var generator = SystemRandomNumberGenerator()
        for index in 0..<meleeStrikesPerAttack {
            if battle.enemyHP <= 0 { break }
            let swing = CombatDamage.resolveMeleeSwing(
                maxHit: playerAttackPower,
                attackLevel: skillLevel(for: .attack),
                weaponAttack: weaponAttackBonus,
                enemyDefense: battle.enemy.defense,
                attackBoost: attackBoostAmount,
                using: &generator
            )
            guard swing.hit else {
                damages.append(0)
                continue
            }
            hits += 1
            let raw = swing.damage
            let swingDamage = index == 0 ? raw : (raw > 0 ? max(1, raw / 2) : 0)
            let dealt = min(swingDamage, battle.enemyHP)
            battle.enemyHP -= dealt
            damages.append(dealt)
        }
        battle.usedMelee = true
        battle.rounds += 1
        battle.lastEnemyDamage = damages.reduce(0, +)
        battle.lastPlayerDamage = 0
        if hits == 0 {
            battle.message = damages.count > 1 ? "You miss both swings." : "You miss."
        } else if damages.count > 1 {
            let listed = damages.map { String($0) }.joined(separator: " and ")
            battle.message = "You hit for \(listed)."
        } else {
            battle.message = "You hit for \(damages.first ?? 0)."
        }
        if battle.enemyHP <= 0 {
            finishLiveBattle(&battle, victory: true)
        } else {
            retaliate(&battle)
        }
        liveBattle = battle
        save()
    }

    func liveCast(_ spell: SpellDefinition) {
        guard var battle = liveBattle, !battle.finished, canCast(spell) else { return }
        for rune in runeBill(for: spell) {
            inventory.remove(rune.item, amount: rune.quantity)
        }
        let dealt = min(
            CombatDamage.damageAfterDefense(maxHit: magicStrikePower(for: spell), enemyDefense: battle.enemy.defense),
            battle.enemyHP
        )
        battle.enemyHP -= dealt
        battle.rounds += 1
        battle.lastEnemyDamage = dealt
        battle.lastPlayerDamage = 0
        if let skill = skills[.magic] {
            SkillProgressService.addXP(spell.magicXP, to: skill)
        }
        battle.magicXP += spell.magicXP
        battle.message = "\(spell.name) hits for \(dealt)."
        if battle.enemyHP <= 0 {
            finishLiveBattle(&battle, victory: true)
        } else {
            retaliate(&battle)
        }
        liveBattle = battle
        save()
    }

    private func retaliate(_ battle: inout LiveBattle) {
        var generator = SystemRandomNumberGenerator()
        let swing = CombatDamage.resolveCreatureSwing(
            creatureAttack: battle.enemy.attack,
            playerDefense: playerCombatDefense,
            using: &generator
        )
        let taken = min(swing.damage, battle.playerHP)
        battle.playerHP -= taken
        battle.lastPlayerDamage = taken
        if !swing.hit {
            battle.message += " \(battle.enemy.name) misses."
        } else if taken == 0 {
            battle.message += " \(battle.enemy.name) hits you for 0."
        } else {
            battle.message += " \(battle.enemy.name) hits you for \(taken)."
        }
        if battle.playerHP <= 0 {
            finishLiveBattle(&battle, victory: false)
        }
    }

    private func finishLiveBattle(_ battle: inout LiveBattle, victory: Bool) {
        battle.finished = true
        battle.victory = victory
        if victory {
            battle.playerHP = max(1, battle.playerHP)
            var generator = SystemRandomNumberGenerator()
            let drops = DropTableService.rollDrops(from: battle.enemy.dropTable, using: &generator)
            battle.drops = drops
            inventory.apply(drops: drops)
            for drop in drops {
                noteAcquired(drop.item)
            }
            recordGoldGain(goldAmount(in: drops))
            var rewarded: [SkillKind] = [.combat]
            if battle.usedMelee {
                rewarded.append(contentsOf: [.attack, .strength, .defense])
            }
            for kind in rewarded {
                if let skill = skills[kind] {
                    SkillProgressService.addXP(battle.enemy.combatXP, to: skill)
                }
            }
            playerCombat.currentHealth = battle.playerHP
        } else {
            playerCombat.currentHealth = max(1, playerCombatHealth / 5)
            battle.playerHP = 0
        }
        playerCombat.combatCooldownEndTimestamp = Date.now.addingTimeInterval(CombatBalance.globalCooldownSeconds)
        startCooldownLoopIfNeeded()
        lastCombatResult = CombatResult(
            enemy: battle.enemy,
            victory: victory,
            playerAttackPower: playerAttackPower,
            xpGained: victory ? battle.enemy.combatXP : 0,
            rounds: battle.rounds,
            remainingHealth: victory ? battle.playerHP : 0,
            drops: battle.drops,
            blows: []
        )
    }

    func equippedItem(in slot: EquipmentSlot) -> InventoryItemID? {
        playerCombat.equippedItem(in: slot)
    }

    func canEquip(_ item: InventoryItemID) -> Bool {
        item.equipmentSlot != nil && inventory.quantity(of: item) > 0 && !isEquipped(item)
    }

    func equipBlockReason(_ item: InventoryItemID) -> String? {
        guard let definition = EquipmentCatalog.definition(for: item),
              let skill = definition.bonuses.requiredSkill,
              let level = definition.bonuses.requiredLevel else { return nil }
        guard skillLevel(for: skill) < level else { return nil }
        return "You need \(skill.displayName) \(level) to equip this."
    }

    func canEquipWeapon(_ weapon: InventoryItemID) -> Bool {
        canEquip(weapon) && equipBlockReason(weapon) == nil
    }

    func equip(_ item: InventoryItemID) {
        guard let slot = item.equipmentSlot, canEquip(item) else { return }
        if let reason = equipBlockReason(item) {
            postNotice(reason)
            return
        }
        let previous = equippedItem(in: slot)
        guard inventory.remove(item, amount: 1) else { return }
        if let previous {
            inventory.add(previous, amount: 1)
        }
        playerCombat.setEquippedItem(item, in: slot)
        if SmithingCatalog.record(for: item)?.tier == .bronze {
            playerRecord.hasEquippedBronzeGear = true
        }
        save()
    }

    func equipWeapon(_ weapon: InventoryItemID) {
        equip(weapon)
    }

    func unequip(_ slot: EquipmentSlot) {
        guard let item = equippedItem(in: slot) else { return }
        inventory.add(item, amount: 1)
        playerCombat.setEquippedItem(nil, in: slot)
        save()
    }

    func isEquipped(_ item: InventoryItemID) -> Bool {
        guard let slot = item.equipmentSlot else { return false }
        return equippedItem(in: slot) == item
    }

    var workerStorageStacks: [(InventoryItemID, Int)] {
        workerPool.storedStacks
    }

    var workerStorageCount: Int {
        workerPool.storedItemCount
    }

    var workerStorageCapacity: Int {
        WorkerBalance.storageCapacity
    }

    var isWorkerStorageFull: Bool {
        workerStorageCount >= workerStorageCapacity
    }

    var showsWorkerStorage: Bool {
        workerPool.ownedCount > 0 || workerStorageCount > 0 || inventory.quantity(of: .autoGatherer) > 0
    }

    var workerStorageFraction: Double {
        guard workerStorageCapacity > 0 else { return 0 }
        return min(1, Double(workerStorageCount) / Double(workerStorageCapacity))
    }

    var nextWorkerTickLabel: String {
        if isWorkerStorageFull {
            return "Storage full"
        }
        guard let tick = nextWorkerTick() else {
            return "Assign a worker to start"
        }
        let seconds = max(0, Int(ceil(tick.remaining)))
        return "Next gather in \(seconds)s"
    }

    var nextWorkerTickFraction: Double {
        guard !isWorkerStorageFull else { return 1 }
        return nextWorkerTick()?.fraction ?? 0
    }

    func collectWorkerStorage() {
        let stacks = workerPool.storedStacks
        guard !stacks.isEmpty else { return }
        var gold = 0
        for (item, amount) in stacks {
            inventory.add(item, amount: amount)
            noteAcquired(item)
            if item == .gold {
                gold += amount
            }
        }
        workerPool.clearStorage()
        playerRecord.hasCollectedWorkerOutput = true
        recordGoldGain(gold)
        save()
    }

    private func nextWorkerTick() -> (remaining: TimeInterval, fraction: Double)? {
        var best: (remaining: TimeInterval, fraction: Double)?
        let interval = max(WorkerBalance.productionInterval, 0.001)
        for spot in ResourceSpotKind.allCases {
            guard workerPool.assignedCount(for: spot) > 0 else { continue }
            let elapsed = workerProgress[spot] ?? 0
            let remaining = max(0, interval - elapsed)
            let fraction = min(1, elapsed / interval)
            if best == nil || remaining < best!.remaining {
                best = (remaining, fraction)
            }
        }
        return best
    }

    func sellableStacks() -> [(InventoryItemID, Int)] {
        inventory.nonEmptyStacks().filter { item, _ in item.sellValue > 0 }
    }

    func canSell(_ item: InventoryItemID, quantity: Int) -> Bool {
        quantity > 0 && item.sellValue > 0 && inventory.quantity(of: item) >= quantity
    }

    func sell(_ item: InventoryItemID, quantity: Int) {
        guard canSell(item, quantity: quantity) else { return }
        guard inventory.remove(item, amount: quantity) else { return }
        let payout = item.sellValue * quantity
        inventory.add(.gold, amount: payout)
        playerRecord.hasSoldItem = true
        recordGoldGain(payout)
        save()
    }

    func sellAll(_ item: InventoryItemID) {
        sell(item, quantity: inventory.quantity(of: item))
    }

    var tutorialComplete: Bool {
        currentTask() == nil
    }

    func currentTask() -> GameTaskDefinition? {
        GameTaskCatalog.all.first { !playerRecord.completedTaskIDs.contains($0.id) }
    }

    func taskStepLabel(for task: GameTaskDefinition) -> String {
        let index = (GameTaskCatalog.all.firstIndex { $0.id == task.id } ?? 0) + 1
        return "\(index) of \(GameTaskCatalog.all.count)"
    }

    func taskProgress(_ task: GameTaskDefinition) -> (current: Int, goal: Int) {
        let goal = 1
        let current: Int
        switch task.kind {
        case .hireWorker:
            current = min(workerPool.ownedCount, goal)
        case .assignWorker:
            current = playerRecord.hasAssignedWorker ? goal : 0
        case .collectWorkerOutput:
            current = playerRecord.hasCollectedWorkerOutput ? goal : 0
        case .sellItem:
            current = playerRecord.hasSoldItem ? goal : 0
        case .buyItem:
            current = playerRecord.hasPurchasedNonWorkerItem ? goal : 0
        case .mineCopper:
            current = playerRecord.hasMinedCopper || inventory.quantity(of: .copperOre) > 0 ? goal : 0
        case .mineTin:
            current = playerRecord.hasMinedTin || inventory.quantity(of: .tinOre) > 0 ? goal : 0
        case .smeltBronze:
            current = playerRecord.hasSmeltedBronzeBar || inventory.quantity(of: .bronzeBar) > 0 ? goal : 0
        case .obtainHammer:
            current = playerRecord.hasObtainedHammer || inventory.quantity(of: .hammer) > 0 ? goal : 0
        case .visitAnvil:
            current = playerRecord.hasOpenedAnvil ? goal : 0
        case .smithBronze:
            current = playerRecord.hasSmithedBronzeItem ? goal : 0
        case .equipBronze:
            current = playerRecord.hasEquippedBronzeGear ? goal : 0
        }
        return (current, goal)
    }

    func isTaskReady(_ task: GameTaskDefinition) -> Bool {
        let progress = taskProgress(task)
        return progress.current >= progress.goal
    }

    func claim(_ task: GameTaskDefinition) {
        guard currentTask()?.id == task.id else { return }
        guard !playerRecord.completedTaskIDs.contains(task.id), isTaskReady(task) else { return }
        playerRecord.completedTaskIDs.insert(task.id)
        inventory.add(.gold, amount: task.goldReward)
        recordGoldGain(task.goldReward)
        save()
    }

    private func forgetRetiredTasks() {
        let known = Set(GameTaskCatalog.all.map(\.id))
        let kept = playerRecord.completedTaskIDs.intersection(known)
        if kept != playerRecord.completedTaskIDs {
            playerRecord.completedTaskIDs = kept
        }
    }

    func dismissGoldNotice() {
        goldNotice = nil
    }

    func dismissStatusNotice() {
        statusNotice = nil
    }

    func noteAcquired(_ item: InventoryItemID) {
        switch item {
        case .copperOre: playerRecord.hasMinedCopper = true
        case .tinOre: playerRecord.hasMinedTin = true
        case .hammer: playerRecord.hasObtainedHammer = true
        case .bronzeBar: playerRecord.hasSmeltedBronzeBar = true
        default: break
        }
    }

    /// Older saves kept the equipped copy in the bag. Move one copy into the slot.
    private func detachEquippedCopiesFromInventory() {
        var changed = false
        for slot in EquipmentSlot.allCases {
            guard let item = playerCombat.equippedItem(in: slot) else { continue }
            if inventory.quantity(of: item) > 0 {
                _ = inventory.remove(item, amount: 1)
                changed = true
            }
        }
        if changed {
            save()
        }
    }

    func postNotice(_ message: String) {
        statusNotice = message
        statusNoticeGeneration += 1
        let generation = statusNoticeGeneration
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            if statusNoticeGeneration == generation {
                statusNotice = nil
            }
        }
    }

    private func goldAmount(in drops: [InventoryItemDrop]) -> Int {
        drops.reduce(0) { total, drop in
            drop.item == .gold ? total + drop.amount : total
        }
    }

    private func recordGoldGain(_ amount: Int) {
        guard amount > 0 else { return }
        goldNotice = amount
        goldNoticeGeneration += 1
        let generation = goldNoticeGeneration
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            if goldNoticeGeneration == generation {
                goldNotice = nil
            }
        }
    }

    private func startWorkerLoop() {
        workerTask?.cancel()
        workerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.tickWorkers(delta: 1)
            }
        }
    }

    private func startCooldownLoopIfNeeded() {
        cooldownTask?.cancel()
        guard isCombatOnCooldown else { return }

        cooldownTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if !self.isCombatOnCooldown {
                    self.playerCombat.combatCooldownEndTimestamp = nil
                    self.save()
                    break
                }
                self.stateVersion += 1
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    /// Applies worker production as if `seconds` of game time passed.
    func advanceWorkers(by seconds: TimeInterval) {
        tickWorkers(delta: seconds)
    }

    private func tickWorkers(delta: TimeInterval) {
        var speedBoost: WorkerSpeedBoost?
        let workersAreAssigned = ResourceSpotKind.allCases.contains { workerPool.assignedCount(for: $0) > 0 }
        var remainingCapacity = max(0, WorkerBalance.storageCapacity - workerPool.storedItemCount)
        let results = workerProductionService.tick(
            delta: delta,
            plans: productionPlans(),
            progress: &workerProgress,
            yieldRemainders: &yieldRemainders,
            speedBoost: &speedBoost,
            remainingCapacity: &remainingCapacity
        )

        var needsSave = false
        if !results.isEmpty {
            var generator = SystemRandomNumberGenerator()
            for result in results {
                for drop in result.itemDrops where drop.amount > 0 {
                    workerPool.addStored(drop.item, amount: drop.amount)
                }
                if let skillKind = result.contributions.first?.resource.skill, let skill = skills[skillKind] {
                    SkillProgressService.addXP(result.xpGained, to: skill)
                }
                depositWorkerBonuses(for: result, using: &generator)
            }
            needsSave = true
        }

        if tickAutoGatherer(delta: delta) {
            needsSave = true
        }
        if expireBoosts() {
            needsSave = true
        }

        let plotsGrowing = FarmPlotCodec.decode(playerRecord.farmPlotsRaw).contains { $0.cropID != nil }
        if needsSave {
            save()
        } else if workersAreAssigned || plotsGrowing || inventory.quantity(of: .autoGatherer) > 0 {
            stateVersion += 1
        }
    }

    private func tickAutoGatherer(delta: TimeInterval) -> Bool {
        guard inventory.quantity(of: .autoGatherer) > 0 else { return false }
        playerRecord.autoGatherProgress += delta
        let resources = AutoGathererBalance.gatherResources
        guard !resources.isEmpty else { return false }
        var produced = false
        while playerRecord.autoGatherProgress >= AutoGathererBalance.interval {
            guard workerPool.storedItemCount < WorkerBalance.storageCapacity else { break }
            let index = playerRecord.autoGatherIndex % resources.count
            let resource = resources[index]
            workerPool.addStored(resource.primaryOutput, amount: resource.primaryAmount)
            if let skill = skills[resource.skill] {
                SkillProgressService.addXP(resource.xpReward, to: skill)
            }
            playerRecord.autoGatherIndex += 1
            playerRecord.autoGatherProgress -= AutoGathererBalance.interval
            produced = true
        }
        return produced
    }

    private func expireBoosts() -> Bool {
        var changed = false
        func clear(_ end: inout Date?) {
            guard let value = end, value <= Date() else { return }
            end = nil
            changed = true
        }
        clear(&playerRecord.attackBoostEnd)
        clear(&playerRecord.strengthBoostEnd)
        clear(&playerRecord.defenseBoostEnd)
        clear(&playerRecord.magicBoostEnd)
        clear(&playerRecord.gatherBoostEnd)
        return changed
    }

    private func depositWorkerBonuses(
        for result: WorkerProductionTickResult,
        using generator: inout some RandomNumberGenerator
    ) {
        for contribution in result.contributions {
            let rolls = result.cyclesCompleted * contribution.nodeCount
            guard rolls > 0 else { continue }
            for _ in 0..<rolls {
                guard workerPool.storedItemCount < WorkerBalance.storageCapacity else { return }
                for secondary in contribution.resource.secondaryDrops {
                    guard workerPool.storedItemCount < WorkerBalance.storageCapacity else { return }
                    guard Double.random(in: 0..<1, using: &generator) < secondary.chance else { continue }
                    let amount = min(secondary.amount, WorkerBalance.storageCapacity - workerPool.storedItemCount)
                    if amount > 0 {
                        workerPool.addStored(secondary.item, amount: amount)
                    }
                }
            }
        }
    }

    func gatheringNodes(for spot: ResourceSpotKind) -> [GatheringNode] {
        let count = max(0, workerPool.ownedCount)
        guard count > 0 else { return [] }
        let eligible = ResourceCatalog.resources(for: spot).filter { canGather($0) }
        let pool = eligible.isEmpty
            ? Array(ResourceCatalog.resources(for: spot).filter(\.isPlayable).prefix(1))
            : eligible
        guard !pool.isEmpty else { return [] }
        let assigned = workerPool.assignedCount(for: spot)
        let focused = focusedResource(for: spot)
        return (0..<count).map { index in
            GatheringNode(
                index: index,
                resource: focused ?? pool[index % pool.count],
                variant: index / pool.count,
                isOccupied: index < assigned
            )
        }
    }

    /// The ore, tree, or fish the player chose for this spot. Nil until they pick one.
    func focusedResource(for spot: ResourceSpotKind) -> ResourceDefinition? {
        let id: String?
        switch spot {
        case .miningSpot: id = workerPool.miningResourceID
        case .treePlot: id = workerPool.treeResourceID
        case .gardenSpot: id = workerPool.gardenResourceID
        case .fishingPond: id = workerPool.fishingResourceID
        case .runeMine: id = workerPool.runeMineResourceID
        }
        guard let id, let resource = ResourceCatalog.definition(id: id), canGather(resource) else { return nil }
        return resource
    }

    func maxSmeltCount(_ recipe: SmeltingRecipe) -> Int {
        guard skillLevel(for: .smithing) >= recipe.requiredSmithingLevel else { return 0 }
        return recipe.ingredients.reduce(Int.max) { count, ingredient in
            guard ingredient.quantity > 0 else { return 0 }
            return min(count, inventory.quantity(of: ingredient.item) / ingredient.quantity)
        }
    }

    func smelt(_ recipe: SmeltingRecipe, quantity: Int) {
        let qty = min(max(0, quantity), maxSmeltCount(recipe))
        guard qty > 0 else { return }
        for ingredient in recipe.ingredients {
            guard inventory.quantity(of: ingredient.item) >= ingredient.quantity * qty else { return }
        }
        for ingredient in recipe.ingredients {
            guard inventory.remove(ingredient.item, amount: ingredient.quantity * qty) else { return }
        }
        inventory.add(recipe.output, amount: recipe.outputQuantity * qty)
        if recipe.output == .bronzeBar {
            playerRecord.hasSmeltedBronzeBar = true
        }
        if let skill = skills[.smithing] {
            SkillProgressService.addXP(recipe.xpReward * qty, to: skill)
        }
        save()
    }

    func maxSmithCount(_ recipe: SmithingRecipe) -> Int {
        guard inventory.quantity(of: .hammer) > 0 else { return 0 }
        guard skillLevel(for: .smithing) >= recipe.requiredSmithingLevel else { return 0 }
        guard recipe.barsRequired > 0 else { return 0 }
        return inventory.quantity(of: recipe.bar) / recipe.barsRequired
    }

    @discardableResult
    func smith(_ recipe: SmithingRecipe, quantity: Int) -> String? {
        guard inventory.quantity(of: .hammer) > 0 else {
            let message = "You need a hammer to smith items."
            postNotice(message)
            return message
        }
        guard skillLevel(for: .smithing) >= recipe.requiredSmithingLevel else {
            let message = "Requires Smithing \(recipe.requiredSmithingLevel)."
            postNotice(message)
            return message
        }
        let qty = min(max(0, quantity), maxSmithCount(recipe))
        guard qty > 0 else { return nil }
        let bars = recipe.barsRequired * qty
        guard inventory.remove(recipe.bar, amount: bars) else { return nil }
        inventory.add(recipe.output, amount: qty)
        if recipe.tier == .bronze {
            playerRecord.hasSmithedBronzeItem = true
        }
        playerRecord.hasOpenedAnvil = true
        if let skill = skills[.smithing] {
            SkillProgressService.addXP(recipe.xpReward * qty, to: skill)
        }
        save()
        return nil
    }

    func markAnvilVisited() {
        guard !playerRecord.hasOpenedAnvil else { return }
        playerRecord.hasOpenedAnvil = true
        save()
    }

    /// Bonus from the single equipped tool for this skill. Copies in the bag do not stack.
    func workerYieldBonus(for skill: SkillKind) -> Double {
        let slot: EquipmentSlot
        switch skill {
        case .woodcutting: slot = .axe
        case .mining: slot = .pickaxe
        case .fishing: slot = .fishingRod
        default: return 0
        }
        guard let item = equippedItem(in: slot),
              let definition = EquipmentCatalog.definition(for: item),
              definition.slot == slot,
              definition.bonuses.workerSkill == skill else { return 0 }
        return max(0, definition.bonuses.workerYieldBonus)
    }

    func workerHeldTool(for skill: SkillKind) -> InventoryItemID {
        switch skill {
        case .mining:
            return equippedItem(in: .pickaxe) ?? .stonePickaxe
        case .woodcutting:
            return equippedItem(in: .axe) ?? .stoneAxe
        case .fishing:
            return equippedItem(in: .fishingRod) ?? .fishingRod
        default:
            return .stoneAxe
        }
    }

    private func productionPlans() -> [WorkerSpotPlan] {
        ResourceSpotKind.allCases.compactMap { spot in
            let nodes = gatheringNodes(for: spot).filter(\.isOccupied)
            guard !nodes.isEmpty else { return nil }
            return WorkerSpotPlan(
                spot: spot,
                interval: WorkerBalance.productionInterval,
                nodes: nodes.map { node in
                    WorkerNodePlan(
                        key: "\(spot.rawValue)#\(node.index)",
                        resource: node.resource,
                        yieldBonus: workerYieldBonus(for: node.resource.skill)
                    )
                }
            )
        }
    }

    private(set) var stateVersion: Int = 0

    func save() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("SwiftData save failed: \(error)")
        }
        stateVersion += 1
    }

    private static func loadOrCreateSkills(in context: ModelContext) -> [SkillKind: SkillProgress] {
        let existing = (try? context.fetch(FetchDescriptor<SkillProgress>())) ?? []
        var map = Dictionary(uniqueKeysWithValues: existing.map { ($0.skillKind, $0) })

        for kind in SkillKind.allCases where map[kind] == nil {
            let created = SkillProgress(skillKind: kind)
            context.insert(created)
            map[kind] = created
        }

        return map
    }

    private static func loadOrCreateWorkerPool(in context: ModelContext) -> WorkerPool {
        var descriptor = FetchDescriptor<WorkerPool>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = WorkerPool()
        context.insert(created)
        return created
    }

    private static func loadOrCreatePlayerRecord(in context: ModelContext) -> PlayerRecord {
        var descriptor = FetchDescriptor<PlayerRecord>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = PlayerRecord()
        context.insert(created)
        return created
    }

    private static func loadOrCreateCombatState(in context: ModelContext) -> PlayerCombatState {
        var descriptor = FetchDescriptor<PlayerCombatState>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = PlayerCombatState()
        context.insert(created)
        return created
    }
}
