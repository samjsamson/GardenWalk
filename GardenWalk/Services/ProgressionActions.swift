import Foundation

extension GameController {
    func isBoostActive(_ end: Date?) -> Bool {
        guard let end else { return false }
        return end > Date()
    }

    func boostRemainingLabel(_ end: Date?) -> String? {
        guard isBoostActive(end), let end else { return nil }
        let remaining = Int(ceil(end.timeIntervalSinceNow))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var playerMagicPower: Int {
        let known = MagicCatalog.spells.filter { skillLevel(for: .magic) >= $0.requiredMagicLevel }
        if let best = known.map({ magicStrikePower(for: $0) }).max() {
            return best
        }
        return max(1, magicGearBonus() + skillLevel(for: .magic) / 5)
    }

    var equippedAttackSpeed: Int {
        equippedWeapon.flatMap { EquipmentCatalog.definition(for: $0)?.bonuses.attackSpeed } ?? 4
    }

    var equippedWeaponKind: String {
        equippedWeapon.flatMap { EquipmentCatalog.definition(for: $0)?.bonuses.weaponKind } ?? "Unarmed"
    }

    /// Speed 4 weapons (dagger, scimitar, unarmed) land two hits. Speed 5 weapons land one.
    var meleeStrikesPerAttack: Int {
        equippedAttackSpeed <= 4 ? 2 : 1
    }

    var attackSpeedSummary: String {
        CombatDamage.attackIntervalLabel(ticks: equippedAttackSpeed)
    }

    var weaponAttackBonus: Int {
        equippedWeapon.flatMap { EquipmentCatalog.definition(for: $0)?.bonuses.attack } ?? 0
    }

    var attackBoostAmount: Int {
        isBoostActive(playerRecord.attackBoostEnd) ? FarmingCatalog.attackBonus : 0
    }

    func meleeHitChance(against enemy: EnemyDefinition) -> Double {
        CombatDamage.meleeHitChance(
            attackLevel: skillLevel(for: .attack),
            weaponAttack: weaponAttackBonus,
            enemyDefense: enemy.defense,
            attackBoost: attackBoostAmount
        )
    }

    func magicGearBonus() -> Int {
        let slots: [EquipmentSlot] = [.weapon, .helmet, .chest, .legs, .boots, .shield]
        return slots.reduce(0) { total, slot in
            total + (equippedItem(in: slot).flatMap { EquipmentCatalog.definition(for: $0) }?.bonuses.magic ?? 0)
        }
    }

    func magicStrikePower(for spell: SpellDefinition? = nil) -> Int {
        guard let spell = spell ?? selectedSpell else { return 1 }
        var power = spell.baseDamage + magicGearBonus() + skillLevel(for: .magic) / 5
        if isBoostActive(playerRecord.magicBoostEnd) {
            power += FarmingCatalog.magicBonus
        }
        return max(1, power)
    }

    func suppliedRunes() -> Set<InventoryItemID> {
        var runes: Set<InventoryItemID> = []
        for slot in EquipmentSlot.allCases {
            if let item = equippedItem(in: slot),
               let rune = EquipmentCatalog.definition(for: item)?.bonuses.suppliedRune {
                runes.insert(rune)
            }
        }
        return runes
    }

    func runeBill(for spell: SpellDefinition) -> [CraftingIngredient] {
        let free = suppliedRunes()
        return spell.runes.filter { !free.contains($0.item) }
    }

    func missingRunes(for spell: SpellDefinition) -> [CraftingIngredient] {
        runeBill(for: spell).compactMap { ingredient in
            let short = ingredient.quantity - inventory.quantity(of: ingredient.item)
            guard short > 0 else { return nil }
            return CraftingIngredient(item: ingredient.item, quantity: short)
        }
    }

    func canCast(_ spell: SpellDefinition) -> Bool {
        skillLevel(for: .magic) >= spell.requiredMagicLevel && missingRunes(for: spell).isEmpty
    }

    func runeCostLine(for spell: SpellDefinition) -> String {
        let free = suppliedRunes()
        return spell.runes.map { ingredient in
            let name = ingredient.item.displayName.replacingOccurrences(of: " Rune", with: "")
            if free.contains(ingredient.item) {
                return "\(name) free"
            }
            return "\(name) \(inventory.quantity(of: ingredient.item))/\(ingredient.quantity)"
        }.joined(separator: " · ")
    }

    func altarBatchLimit() -> Int {
        inventory.quantity(of: .runePouch) > 0 ? RunecraftingCatalog.pouchBatch : RunecraftingCatalog.plainBatch
    }

    func maxAltarCraft(_ altar: AltarDefinition) -> Int {
        guard skillLevel(for: .runecrafting) >= altar.runecraftingLevel else { return 0 }
        return min(inventory.quantity(of: .runeEssence), altarBatchLimit())
    }

    /// Absolute maximum essence that can be shaped at this altar (ignores pouch visit batch).
    func maxAltarCraftAbsolute(_ altar: AltarDefinition) -> Int {
        guard skillLevel(for: .runecrafting) >= altar.runecraftingLevel else { return 0 }
        return inventory.quantity(of: .runeEssence)
    }

    func craftAtAltar(_ altar: AltarDefinition) {
        craftAtAltar(altar, quantity: maxAltarCraft(altar))
    }

    func craftAtAltar(_ altar: AltarDefinition, quantity: Int) {
        let count = min(max(0, quantity), maxAltarCraftAbsolute(altar))
        guard count > 0, inventory.remove(.runeEssence, amount: count) else { return }
        let made = altar.runesPerEssence * count
        inventory.add(altar.rune, amount: made)
        if let skill = skills[.runecrafting] {
            SkillProgressService.addXP(altar.xp * count, to: skill)
        }
        postNotice("Crafted \(made) \(altar.rune.displayName).")
        save()
    }

    func setCombatStyle(_ style: CombatStyle) {
        playerCombat.combatStyleRaw = style.rawValue
        if style == .magic, playerCombat.selectedSpellRaw == nil {
            playerCombat.selectedSpellRaw = MagicCatalog.spells.first?.id
        }
        save()
    }

    func selectSpell(_ spell: SpellDefinition) {
        playerCombat.combatStyleRaw = CombatStyle.magic.rawValue
        playerCombat.selectedSpellRaw = spell.id
        save()
    }

    func bagItems(for slot: EquipmentSlot) -> [(InventoryItemID, Int)] {
        inventory.nonEmptyStacks().filter { $0.0.equipmentSlot == slot }
    }

    var farmPlots: [FarmPlot] {
        FarmPlotCodec.decode(playerRecord.farmPlotsRaw)
    }

    func plotUnlockLevel(_ index: Int) -> Int {
        guard FarmPlotCodec.unlockLevels.indices.contains(index) else { return 99 }
        return FarmPlotCodec.unlockLevels[index]
    }

    func canPlant(_ crop: CropDefinition, in index: Int) -> Bool {
        guard farmPlots.indices.contains(index) else { return false }
        guard skillLevel(for: .farming) >= plotUnlockLevel(index) else { return false }
        guard skillLevel(for: .farming) >= crop.farmingLevel else { return false }
        guard farmPlots[index].cropID == nil else { return false }
        return inventory.quantity(of: crop.seed) > 0
    }

    func plant(_ crop: CropDefinition, in index: Int) {
        guard canPlant(crop, in: index) else { return }
        guard inventory.remove(crop.seed, amount: 1) else { return }
        var plots = farmPlots
        plots[index] = FarmPlot(cropID: crop.id, plantedAt: Date())
        playerRecord.farmPlotsRaw = FarmPlotCodec.encode(plots)
        save()
    }

    func growthRemaining(for plot: FarmPlot, now: Date = Date()) -> TimeInterval {
        guard let cropID = plot.cropID,
              let crop = FarmingCatalog.crop(id: cropID),
              let planted = plot.plantedAt else { return 0 }
        return max(0, crop.growth - now.timeIntervalSince(planted))
    }

    func isReadyToHarvest(_ index: Int) -> Bool {
        guard farmPlots.indices.contains(index) else { return false }
        let plot = farmPlots[index]
        guard plot.cropID != nil else { return false }
        return growthRemaining(for: plot) <= 0
    }

    func harvestPlot(_ index: Int) {
        guard isReadyToHarvest(index) else { return }
        let plot = farmPlots[index]
        guard let cropID = plot.cropID, let crop = FarmingCatalog.crop(id: cropID) else { return }
        inventory.add(crop.harvest, amount: crop.harvestQuantity)
        noteAcquired(crop.harvest)
        if crop.id == "pumpkin", Int.random(in: 1...100) <= 20 {
            inventory.add(.sunseed, amount: 1)
            noteAcquired(.sunseed)
            postNotice("The pumpkin held a sunseed.")
        }
        if let skill = skills[.farming] {
            SkillProgressService.addXP(crop.xp, to: skill)
        }
        var plots = farmPlots
        plots[index] = FarmPlot()
        playerRecord.farmPlotsRaw = FarmPlotCodec.encode(plots)
        save()
    }

    /// Moves planted crops forward so tests and the harvest button can finish a grow cycle.
    func advanceFarmPlots(by seconds: TimeInterval) {
        var plots = farmPlots
        for index in plots.indices {
            if let planted = plots[index].plantedAt {
                plots[index].plantedAt = planted.addingTimeInterval(-seconds)
            }
        }
        playerRecord.farmPlotsRaw = FarmPlotCodec.encode(plots)
        save()
    }

    func canUse(_ item: InventoryItemID) -> Bool {
        guard inventory.quantity(of: item) > 0 else { return false }
        if FarmingCatalog.potion(for: item) != nil { return true }
        if FarmingCatalog.healAmount(for: item) != nil {
            return currentHitPoints < playerCombatHealth
        }
        return false
    }

    func use(_ item: InventoryItemID) {
        guard canUse(item), inventory.remove(item, amount: 1) else { return }
        if let potion = FarmingCatalog.potion(for: item) {
            apply(potion)
            return
        }
        guard let heal = FarmingCatalog.healAmount(for: item) else { return }
        let before = currentHitPoints
        let after = min(playerCombatHealth, before + heal)
        playerCombat.currentHealth = after
        postNotice("Restored \(after - before) HP.")
        save()
    }

    private func apply(_ potion: PotionDefinition) {
        if let heal = potion.heal {
            let before = currentHitPoints
            let after = min(playerCombatHealth, before + heal)
            playerCombat.currentHealth = after
            postNotice("Restored \(after - before) HP.")
            save()
            return
        }
        let end = Date().addingTimeInterval(potion.duration ?? FarmingCatalog.potionDuration)
        switch potion.item {
        case .keenOil: playerRecord.attackBoostEnd = end
        case .oakDraught: playerRecord.strengthBoostEnd = end
        case .barkTincture: playerRecord.defenseBoostEnd = end
        case .sparkPhilter: playerRecord.magicBoostEnd = end
        case .gatherersBrew: playerRecord.gatherBoostEnd = end
        default: break
        }
        postNotice(potion.effect)
        save()
    }
}
