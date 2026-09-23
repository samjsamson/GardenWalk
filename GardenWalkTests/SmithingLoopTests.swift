import SwiftData
import XCTest
@testable import GardenWalk

@MainActor
final class SmithingLoopTests: XCTestCase {
    private var container: ModelContainer?
    private var game: GameController?

    override func tearDown() {
        game?.stop()
        game = nil
        container = nil
        super.tearDown()
    }

    func testRecipesMatchTheMetalProgression() {
        let bronze = SmithingCatalog.smelting.first { $0.output == .bronzeBar }
        XCTAssertEqual(bronze?.ingredients.map(\.item), [.copperOre, .tinOre])
        XCTAssertEqual(bronze?.ingredients.map(\.quantity), [1, 1])
        XCTAssertEqual(bronze?.requiredSmithingLevel, 1)

        let steel = SmithingCatalog.smelting.first { $0.output == .steelBar }
        XCTAssertEqual(steel?.ingredients.map(\.item), [.ironOre, .coal])
        XCTAssertEqual(steel?.ingredients.map(\.quantity), [1, 2])

        let mithril = SmithingCatalog.smelting.first { $0.output == .mithrilBar }
        XCTAssertEqual(mithril?.ingredients.map(\.quantity), [1, 4])
        let adamant = SmithingCatalog.smelting.first { $0.output == .adamantBar }
        XCTAssertEqual(adamant?.ingredients.map(\.quantity), [1, 6])
        XCTAssertGreaterThan(adamant?.requiredSmithingLevel ?? 0, mithril?.requiredSmithingLevel ?? 0)

        func bars(_ item: InventoryItemID) -> Int {
            SmithingCatalog.smithing.first { $0.output == item }?.barsRequired ?? -1
        }
        XCTAssertEqual(bars(.bronzeHelmet), 2)
        XCTAssertEqual(bars(.bronzeShield), 2)
        XCTAssertEqual(bars(.bronzePlatelegs), 3)
        XCTAssertEqual(bars(.bronzePlatebody), 5)
        XCTAssertEqual(bars(.bronzeDagger), 1)
        XCTAssertEqual(bars(.bronzeSword), 2)
        XCTAssertEqual(SmithingCatalog.record(for: .adamantPlatebody)?.requiredLevel, 30)
        XCTAssertEqual(SmithingCatalog.record(for: .adamantPlatebody)?.requiredSkill, .defense)
        XCTAssertGreaterThan(
            SmithingCatalog.record(for: .adamantPlatebody)?.defenseBonus ?? 0,
            SmithingCatalog.record(for: .mithrilPlatebody)?.defenseBonus ?? 0
        )
    }

    func testMiningSmeltingSmithingAndEquipLoop() throws {
        let game = try makeGame()
        game.skills[.mining]?.totalXP = SkillProgressService.totalXP(forLevel: 50)
        XCTAssertTrue(game.gatheringNodes(for: .miningSpot).isEmpty)

        game.workerPool.ownedCount = 1
        let highLevelOres = Set(ResourceCatalog.resources(for: .miningSpot).filter { game.canGather($0) }.map(\.id))
        XCTAssertTrue(highLevelOres.contains("mithril"))
        XCTAssertTrue(highLevelOres.contains("adamant"))

        game.selectWorkerResource(ResourceCatalog.mithril)
        game.assignWorker(to: .miningSpot)
        game.advanceWorkers(by: WorkerBalance.productionInterval)
        XCTAssertEqual(stored(.mithrilOre, game), 1)
        game.collectWorkerStorage()
        XCTAssertEqual(game.inventory.quantity(of: .mithrilOre), 1)

        game.inventory.add(.copperOre, amount: 3)
        game.inventory.add(.tinOre, amount: 2)
        let bronze = try XCTUnwrap(SmithingCatalog.smelting.first { $0.output == .bronzeBar })
        XCTAssertEqual(game.maxSmeltCount(bronze), 2)
        game.smelt(bronze, quantity: 99)
        XCTAssertEqual(game.inventory.quantity(of: .copperOre), 1)
        XCTAssertEqual(game.inventory.quantity(of: .tinOre), 0)
        XCTAssertEqual(game.inventory.quantity(of: .bronzeBar), 2)
        XCTAssertEqual(game.skills[.smithing]?.totalXP, bronze.xpReward * 2)
        XCTAssertTrue(game.playerRecord.hasSmeltedBronzeBar)

        let helmet = try XCTUnwrap(SmithingCatalog.smithing.first { $0.output == .bronzeHelmet })
        let xpBeforeSmith = game.skills[.smithing]?.totalXP ?? 0
        XCTAssertNil(game.smith(helmet, quantity: 1))
        XCTAssertEqual(game.inventory.quantity(of: .bronzeBar), 0)
        XCTAssertEqual(game.inventory.quantity(of: .bronzeHelmet), 1)
        XCTAssertEqual(game.skills[.smithing]?.totalXP, xpBeforeSmith + helmet.xpReward)
        XCTAssertTrue(game.playerRecord.hasSmithedBronzeItem)

        XCTAssertEqual(game.equipBlockReason(.bronzeHelmet), nil)
        game.equip(.bronzeHelmet)
        XCTAssertEqual(game.inventory.quantity(of: .bronzeHelmet), 0)
        XCTAssertEqual(game.equippedItem(in: .helmet), .bronzeHelmet)
        XCTAssertEqual(game.playerCombatDefense, SmithingCatalog.record(for: .bronzeHelmet)?.defenseBonus)
        XCTAssertTrue(game.playerRecord.hasEquippedBronzeGear)

        game.unequip(.helmet)
        XCTAssertEqual(game.inventory.quantity(of: .bronzeHelmet), 1)
        XCTAssertNil(game.equippedItem(in: .helmet))

        game.inventory.add(.bronzeDagger, amount: 1)
        game.equip(.bronzeDagger)
        game.equip(.bronzeHelmet)
        XCTAssertEqual(game.equippedItem(in: .weapon), .bronzeDagger)
        XCTAssertEqual(game.equippedItem(in: .helmet), .bronzeHelmet)
        XCTAssertEqual(game.inventory.quantity(of: .bronzeDagger), 0)

        game.inventory.add(.ironDagger, amount: 1)
        game.equip(.ironDagger)
        XCTAssertEqual(game.equippedItem(in: .weapon), .ironDagger)
        XCTAssertEqual(game.inventory.quantity(of: .bronzeDagger), 1)
        XCTAssertEqual(game.inventory.quantity(of: .ironDagger), 0)

        let goldBefore = game.inventory.quantity(of: .gold)
        game.sellAll(.bronzeDagger)
        game.sell(.mithrilOre, quantity: 1)
        game.sell(.bronzeBar, quantity: 5)
        XCTAssertEqual(game.inventory.quantity(of: .bronzeDagger), 0)
        XCTAssertEqual(game.inventory.quantity(of: .mithrilOre), 0)
        XCTAssertEqual(
            game.inventory.quantity(of: .gold),
            goldBefore + InventoryItemID.bronzeDagger.sellValue + InventoryItemID.mithrilOre.sellValue
        )
        XCTAssertGreaterThanOrEqual(game.inventory.quantity(of: .gold), 0)
        XCTAssertEqual(game.equippedItem(in: .weapon), .ironDagger)

        let savedXP = game.skills[.smithing]?.totalXP
        let reloaded = GameController(modelContext: try XCTUnwrap(container).mainContext)
        XCTAssertEqual(reloaded.skills[.smithing]?.totalXP, savedXP)
        XCTAssertEqual(reloaded.equippedItem(in: .weapon), .ironDagger)
        XCTAssertEqual(reloaded.inventory.quantity(of: .ironDagger), 0)
        XCTAssertEqual(reloaded.equippedItem(in: .helmet), .bronzeHelmet)
        XCTAssertEqual(reloaded.inventory.quantity(of: .bronzeHelmet), 0)
        reloaded.stop()
    }

    func testDefenseRequirementBlocksEquipWithoutDeletingTheItem() throws {
        let game = try makeGame()
        game.inventory.add(.mithrilHelmet, amount: 1)
        let reason = game.equipBlockReason(.mithrilHelmet)
        XCTAssertEqual(reason, "You need Defense 20 to equip this.")
        game.equip(.mithrilHelmet)
        XCTAssertEqual(game.inventory.quantity(of: .mithrilHelmet), 1)
        XCTAssertNil(game.equippedItem(in: .helmet))
        XCTAssertEqual(game.statusNotice, reason)

        game.skills[.defense]?.totalXP = SkillProgressService.totalXP(forLevel: 20)
        XCTAssertNil(game.equipBlockReason(.mithrilHelmet))
        game.equip(.mithrilHelmet)
        XCTAssertEqual(game.inventory.quantity(of: .mithrilHelmet), 0)
        XCTAssertEqual(game.equippedItem(in: .helmet), .mithrilHelmet)
    }

    func testOlderSaveKeepsEquippedGearWithoutCrashingOrDuplicating() throws {
        let schema = Schema([
            SkillProgress.self,
            InventoryEntry.self,
            WorkerPool.self,
            PlayerCombatState.self,
            PlayerRecord.self
        ])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        context.insert(PlayerRecord())
        context.insert(PlayerCombatState(equippedWeaponRaw: InventoryItemID.stoneDagger.rawValue))
        let dagger = InventoryEntry(itemID: .stoneDagger, quantity: 1)
        context.insert(dagger)

        let game = GameController(modelContext: context)
        self.container = container
        self.game = game

        XCTAssertEqual(game.equippedItem(in: .weapon), .stoneDagger)
        XCTAssertEqual(game.inventory.quantity(of: .stoneDagger), 0)
        XCTAssertFalse(game.playerRecord.hasEquippedBronzeGear)
        XCTAssertEqual(game.inventory.quantity(of: .mithrilOre), 0)
    }

    private func stored(_ item: InventoryItemID, _ game: GameController) -> Int {
        game.workerStorageStacks.first { $0.0 == item }?.1 ?? 0
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
