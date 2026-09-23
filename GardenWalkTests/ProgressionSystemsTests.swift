import SwiftData
import XCTest
@testable import GardenWalk

@MainActor
final class ProgressionSystemsTests: XCTestCase {
    private var container: ModelContainer?
    private var game: GameController?

    override func tearDown() {
        game?.stop()
        game = nil
        container = nil
        super.tearDown()
    }

    func testTotalLevelSumsEverySkill() throws {
        let game = try makeGame()
        XCTAssertEqual(game.totalLevel, SkillKind.allCases.count)
        XCTAssertEqual(SkillKind.allCases.count, 11)
        game.skills[.magic]?.totalXP = SkillProgressService.totalXP(forLevel: 4)
        XCTAssertEqual(game.totalLevel, 14)
    }

    func testCowIsAnEarlyEnemyAndTreeBranchIsGone() {
        XCTAssertEqual(EnemyCatalog.cow.requiredCombatLevel, 3)
        XCTAssertLessThan(EnemyCatalog.cow.health, 15)
        XCTAssertFalse(InventoryItemID.allCases.map(\.rawValue).contains("treeBranch"))
        XCTAssertNil(CraftingCatalog.all.first { $0.ingredients.contains { $0.item.rawValue == "treeBranch" } })
        XCTAssertEqual(ResourceSpotKind.gardenSpot.title, "Farming")
        XCTAssertFalse(ResourceSpotKind.allCases.map(\.title).contains { $0.contains("Area") })
    }

    func testFarmingHarvestsFoodThatHeals() throws {
        let game = try makeGame()
        let turnip = try XCTUnwrap(FarmingCatalog.crop(id: "turnip"))
        game.inventory.add(turnip.seed, amount: 1)
        game.plant(turnip, in: 0)
        XCTAssertEqual(game.inventory.quantity(of: turnip.seed), 0)
        XCTAssertFalse(game.isReadyToHarvest(0))
        game.advanceFarmPlots(by: turnip.growth)
        XCTAssertTrue(game.isReadyToHarvest(0))
        game.harvestPlot(0)
        XCTAssertEqual(game.inventory.quantity(of: .turnip), turnip.harvestQuantity)
        XCTAssertEqual(game.skills[.farming]?.totalXP, turnip.xp)

        game.playerCombat.currentHealth = 5
        let before = game.currentHitPoints
        game.use(.turnip)
        XCTAssertEqual(game.currentHitPoints, before + (FarmingCatalog.healAmount(for: .turnip) ?? 0))
        XCTAssertEqual(game.inventory.quantity(of: .turnip), turnip.harvestQuantity - 1)
    }

    func testMagicSpellSpendsRunesAndGrantsMagicXP() throws {
        let game = try makeGame()
        let spell = try XCTUnwrap(MagicCatalog.spell(id: "air-strike"))
        let casts = 3
        for rune in spell.runes {
            game.inventory.add(rune.item, amount: rune.quantity * casts)
        }
        XCTAssertTrue(game.beginLiveBattle(EnemyCatalog.rat))
        for _ in 0..<casts {
            game.liveCast(spell)
        }
        let battle = try XCTUnwrap(game.liveBattle)
        XCTAssertTrue(battle.victory)
        for rune in spell.runes {
            XCTAssertEqual(game.inventory.quantity(of: rune.item), 0)
        }
        XCTAssertEqual(game.skills[.magic]?.totalXP, spell.magicXP * casts)
        XCTAssertEqual(game.skills[.attack]?.totalXP, 0)
        XCTAssertEqual(game.skills[.combat]?.totalXP, EnemyCatalog.rat.combatXP)
        XCTAssertFalse(game.canCast(spell))
    }

    func testAirStaffWaivesOnlyAirRunes() throws {
        let game = try makeGame()
        game.skills[.magic]?.totalXP = SkillProgressService.totalXP(forLevel: 8)
        game.inventory.add(.airStaff, amount: 1)
        game.equip(.airStaff)
        let spell = try XCTUnwrap(MagicCatalog.spell(id: "air-strike"))
        XCTAssertFalse(game.canCast(spell))
        game.inventory.add(.mindRune, amount: 1)
        XCTAssertTrue(game.canCast(spell))
        XCTAssertTrue(game.beginLiveBattle(EnemyCatalog.rat))
        game.liveCast(spell)
        XCTAssertEqual(game.inventory.quantity(of: .mindRune), 0)
        XCTAssertEqual(game.inventory.quantity(of: .airRune), 0)
        XCTAssertEqual(game.skills[.magic]?.totalXP, SkillProgressService.totalXP(forLevel: 8) + spell.magicXP)
    }

    func testAltarsSpendEssenceAndGrantRunecraftingXP() throws {
        let game = try makeGame()
        let air = try XCTUnwrap(RunecraftingCatalog.altars.first { $0.rune == .airRune })
        game.inventory.add(.runeEssence, amount: 3)
        game.craftAtAltar(air)
        XCTAssertEqual(game.inventory.quantity(of: .runeEssence), 2)
        XCTAssertEqual(game.inventory.quantity(of: .airRune), 1)
        XCTAssertEqual(game.skills[.runecrafting]?.totalXP, air.xp)

        game.inventory.add(.runePouch, amount: 1)
        game.craftAtAltar(air)
        XCTAssertEqual(game.inventory.quantity(of: .runeEssence), 0)
        XCTAssertEqual(game.inventory.quantity(of: .airRune), 1 + air.runesPerEssence * 2)
        XCTAssertEqual(game.skills[.runecrafting]?.totalXP, air.xp * 3)
    }

    func testRuneMineAndRetiredSupplies() {
        let essence = ResourceCatalog.all.first { $0.primaryOutput == .runeEssence }
        XCTAssertEqual(essence?.requiredLevel, 10)
        XCTAssertEqual(essence?.skill, .mining)
        XCTAssertEqual(essence?.spot, .runeMine)
        XCTAssertTrue(InventoryItemID.allCases.contains(.runeEssence))
        XCTAssertNil(InventoryItemID(rawValue: "lootBag"))
        XCTAssertNil(InventoryItemID(rawValue: "mysteryCrate"))
        XCTAssertNil(InventoryItemID(rawValue: "workerRations"))
        XCTAssertEqual(ResourceCatalog.oak.requiredLevel, 15)
        XCTAssertEqual(ResourceCatalog.willow.requiredLevel, 30)
        XCTAssertEqual(ResourceCatalog.maple.requiredLevel, 40)
        XCTAssertEqual(FarmPlotCodec.unlockLevels, [1, 3, 7, 12])
        XCTAssertEqual(WorkerBalance.expandedUnlockTotalLevel, 15)
    }

    func testEarlyMeleeDamageStaysLow() throws {
        let game = try makeGame()
        game.skills[.attack]?.totalXP = SkillProgressService.totalXP(forLevel: 14)
        game.skills[.strength]?.totalXP = SkillProgressService.totalXP(forLevel: 14)
        game.inventory.add(.bronzeSword, amount: 1)
        game.equip(.bronzeSword)
        XCTAssertLessThanOrEqual(game.playerAttackPower, 6)
        let vsCow = CombatDamage.damageAfterDefense(maxHit: game.playerAttackPower, enemyDefense: EnemyCatalog.cow.defense)
        XCTAssertGreaterThanOrEqual(vsCow, 1)
        XCTAssertLessThanOrEqual(vsCow, 6)
    }

    func testCowAccuracyIsReliableForEarlyGear() throws {
        let game = try makeGame()
        game.skills[.attack]?.totalXP = SkillProgressService.totalXP(forLevel: 5)
        game.skills[.strength]?.totalXP = SkillProgressService.totalXP(forLevel: 5)
        game.inventory.add(.bronzeSword, amount: 1)
        game.equip(.bronzeSword)
        XCTAssertEqual(EnemyCatalog.cow.defense, 0)
        let chance = game.meleeHitChance(against: EnemyCatalog.cow)
        XCTAssertGreaterThanOrEqual(chance, 0.85)
        XCTAssertLessThanOrEqual(chance, CombatDamage.maxHitChance)

        var generator = SystemRandomNumberGenerator()
        var hits = 0
        var damageHits = 0
        let trials = 200
        for _ in 0..<trials {
            let swing = CombatDamage.resolveMeleeSwing(
                maxHit: game.playerAttackPower,
                attackLevel: game.skillLevel(for: .attack),
                weaponAttack: game.weaponAttackBonus,
                enemyDefense: EnemyCatalog.cow.defense,
                using: &generator
            )
            if swing.hit {
                hits += 1
                if swing.damage > 0 { damageHits += 1 }
            }
        }
        let rate = Double(hits) / Double(trials)
        XCTAssertGreaterThan(rate, 0.80, "Expected mostly hits against a cow, got \(rate)")
        XCTAssertEqual(hits, damageHits, "Landed hits against a cow should deal damage")
        XCTAssertEqual(game.attackSpeedSummary, "3s")
    }

    func testAutoGathererNeedsTotalLevelAndCollectsSlowly() throws {
        let game = try makeGame()
        let listing = try XCTUnwrap(StoreCatalog.listing(id: "auto-gatherer"))
        XCTAssertEqual(listing.requiredTotalLevel, 50)
        XCTAssertFalse(game.canPurchase(listing, quantity: 1))
        game.advanceWorkers(by: AutoGathererBalance.interval)
        XCTAssertEqual(game.workerStorageCount, 0)

        game.inventory.add(.autoGatherer, amount: 1)
        game.advanceWorkers(by: AutoGathererBalance.interval)
        XCTAssertEqual(game.workerStorageCount, 1)
        XCTAssertEqual(game.workerStorageStacks.first?.0, AutoGathererBalance.gatherResources[0].primaryOutput)
        XCTAssertEqual(game.skills[.mining]?.totalXP, ResourceCatalog.copper.xpReward)
    }

    func testEquipmentPickerListsOnlyThatSlot() throws {
        let game = try makeGame()
        game.inventory.add(.bronzeHelmet, amount: 1)
        game.inventory.add(.apprenticeWand, amount: 1)
        XCTAssertEqual(game.bagItems(for: .helmet).map(\.0), [.bronzeHelmet])
        XCTAssertEqual(game.bagItems(for: .weapon).map(\.0), [.apprenticeWand])
        XCTAssertTrue(game.bagItems(for: .shield).isEmpty)
        game.equip(.apprenticeWand)
        XCTAssertEqual(game.equippedItem(in: .weapon), .apprenticeWand)
        XCTAssertTrue(game.bagItems(for: .weapon).isEmpty)
    }

    func testRetiredTreeBranchIsDeleted() throws {
        let schema = Schema([
            SkillProgress.self,
            InventoryEntry.self,
            WorkerPool.self,
            PlayerCombatState.self,
            PlayerRecord.self
        ])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let branch = InventoryEntry(itemID: .wood, quantity: 1)
        branch.itemID = "treeBranch"
        container.mainContext.insert(branch)
        let game = GameController(modelContext: container.mainContext)
        self.container = container
        self.game = game
        let leftover = try container.mainContext.fetch(FetchDescriptor<InventoryEntry>()).filter { $0.itemID == "treeBranch" }
        XCTAssertTrue(leftover.isEmpty)
    }

    private func makeGame() throws -> GameController {
        let schema = Schema([
            SkillProgress.self,
            InventoryEntry.self,
            WorkerPool.self,
            PlayerCombatState.self,
            PlayerRecord.self
        ])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let game = GameController(modelContext: container.mainContext)
        self.container = container
        self.game = game
        return game
    }
}
