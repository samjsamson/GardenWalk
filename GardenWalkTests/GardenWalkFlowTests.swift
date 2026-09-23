import SwiftData
import XCTest
@testable import GardenWalk

@MainActor
final class GardenWalkFlowTests: XCTestCase {
    private var container: ModelContainer?
    private var game: GameController?

    override func tearDown() {
        game?.stop()
        game = nil
        container = nil
        super.tearDown()
    }

    func testOnboardingClaimOrderAndRewards() throws {
        let game = try makeGame()
        XCTAssertEqual(game.currentTask()?.id, "hire-first-worker")
        XCTAssertEqual(game.inventory.quantity(of: .gold), 20)

        let gatherTask = GameTaskCatalog.all[2]
        let goldBeforeEarlyClaim = game.inventory.quantity(of: .gold)
        game.claim(gatherTask)
        XCTAssertEqual(game.inventory.quantity(of: .gold), goldBeforeEarlyClaim)
        XCTAssertFalse(game.playerRecord.completedTaskIDs.contains(gatherTask.id))

        XCTAssertTrue(game.purchaseSucceeds(StoreCatalog.worker))
        XCTAssertEqual(game.workerPool.ownedCount, 1)
        XCTAssertFalse(game.playerRecord.hasPurchasedNonWorkerItem)
        XCTAssertEqual(game.inventory.quantity(of: .gold), 10)
        claimCurrent(game, expectedReward: 8)
        XCTAssertEqual(game.inventory.quantity(of: .gold), 18)

        game.assignWorker(to: .miningSpot)
        XCTAssertEqual(game.assignedWorkers(for: .miningSpot), 1)
        game.assignWorker(to: .treePlot)
        XCTAssertEqual(game.assignedWorkers(for: .treePlot), 0, "A single worker cannot be assigned twice")
        claimCurrent(game, expectedReward: 10)
        XCTAssertEqual(game.inventory.quantity(of: .gold), 28)

        game.advanceWorkers(by: WorkerBalance.productionInterval)
        let storedCopper = storedQuantity(of: .copperOre, in: game)
        XCTAssertGreaterThanOrEqual(storedCopper, 1)
        let fishingXPBefore = game.skills[.fishing]?.totalXP ?? 0
        game.collectWorkerStorage()
        XCTAssertEqual(game.workerStorageCount, 0)
        XCTAssertEqual(game.inventory.quantity(of: .copperOre), storedCopper)
        XCTAssertEqual(game.skills[.fishing]?.totalXP, fishingXPBefore)
        claimCurrent(game, expectedReward: 12)

        let goldBeforeSell = game.inventory.quantity(of: .gold)
        game.sellAll(.copperOre)
        XCTAssertEqual(game.inventory.quantity(of: .copperOre), 0)
        XCTAssertEqual(
            game.inventory.quantity(of: .gold),
            goldBeforeSell + storedCopper * InventoryItemID.copperOre.sellValue
        )
        let goldAfterSell = game.inventory.quantity(of: .gold)
        game.sellAll(.copperOre)
        XCTAssertEqual(game.inventory.quantity(of: .gold), goldAfterSell)
        claimCurrent(game, expectedReward: 15)

        XCTAssertTrue(game.purchaseSucceeds(StoreCatalog.stoneAxe))
        XCTAssertEqual(game.inventory.quantity(of: .stoneAxe), 1)
        XCTAssertTrue(game.playerRecord.hasPurchasedNonWorkerItem)
        claimCurrent(game, expectedReward: 20)

        XCTAssertEqual(game.currentTask()?.id, "mine-copper")
        let goldWhenDone = game.inventory.quantity(of: .gold)
        game.claim(GameTaskCatalog.all[0])
        game.claim(GameTaskCatalog.all[4])
        XCTAssertEqual(game.inventory.quantity(of: .gold), goldWhenDone)
    }

    func testSellAllPaysOnceAndEquippingRemovesTheBagCopy() throws {
        let game = try makeGame()
        XCTAssertTrue(game.purchaseSucceeds(StoreCatalog.stoneAxe))
        let goldBefore = game.inventory.quantity(of: .gold)
        let owned = game.inventory.quantity(of: .stoneAxe)
        game.sellAll(.stoneAxe)

        XCTAssertEqual(game.inventory.quantity(of: .stoneAxe), 0)
        XCTAssertNil(game.equippedItem(in: .axe))
        XCTAssertEqual(game.inventory.quantity(of: .gold), goldBefore + owned * InventoryItemID.stoneAxe.sellValue)

        game.inventory.add(.stoneAxe, amount: 1)
        game.equip(.stoneAxe)
        XCTAssertEqual(game.inventory.quantity(of: .stoneAxe), 0)
        XCTAssertEqual(game.equippedItem(in: .axe), .stoneAxe)
        let goldWhileEquipped = game.inventory.quantity(of: .gold)
        game.sellAll(.stoneAxe)
        XCTAssertEqual(game.inventory.quantity(of: .gold), goldWhileEquipped)
        XCTAssertEqual(game.equippedItem(in: .axe), .stoneAxe)

        game.unequip(.axe)
        XCTAssertEqual(game.inventory.quantity(of: .stoneAxe), 1)
        XCTAssertNil(game.equippedItem(in: .axe))
    }

    func testIronPickaxeRaisesMiningOutputButNotXP() throws {
        let game = try makeGame()
        game.inventory.add(.gold, amount: 200)
        XCTAssertTrue(game.purchaseSucceeds(StoreCatalog.worker))
        XCTAssertTrue(game.purchaseSucceeds(StoreCatalog.ironPickaxe))
        game.equip(.ironPickaxe)
        XCTAssertEqual(game.workerYieldBonus(for: .mining), 0.20)
        XCTAssertEqual(InventoryItemID.ironPickaxe.effect, "Mining Bonus +20%")
        game.assignWorker(to: .miningSpot)

        game.advanceWorkers(by: WorkerBalance.productionInterval * 5)

        XCTAssertEqual(storedQuantity(of: .copperOre, in: game), 6)
        XCTAssertEqual(game.skills[.mining]?.totalXP, ResourceCatalog.copper.workerXP * 5)
    }

    func testFishingProducesShrimpAndXP() throws {
        let game = try makeGame()
        XCTAssertTrue(game.purchaseSucceeds(StoreCatalog.worker))
        game.assignWorker(to: .fishingPond)
        XCTAssertEqual(game.gatheringNodes(for: .fishingPond).count, 1)
        XCTAssertEqual(game.gatheringNodes(for: .fishingPond).first?.resource.id, "shrimp")

        let xpBefore = game.skills[.fishing]?.totalXP ?? 0
        game.advanceWorkers(by: WorkerBalance.productionInterval)

        XCTAssertEqual(storedQuantity(of: .shrimp, in: game), 1)
        XCTAssertEqual(game.skills[.fishing]?.totalXP, xpBefore + ResourceCatalog.shrimp.workerXP)
        game.collectWorkerStorage()
        XCTAssertEqual(game.inventory.quantity(of: .shrimp), 1)
    }

    func testWorkersAllocateIndependentlyPerResource() throws {
        let game = try makeGame()
        game.workerPool.ownedCount = 10
        game.skills[.mining]?.totalXP = SkillProgressService.totalXP(forLevel: 40)

        game.assignWorker(to: ResourceCatalog.copper)
        game.assignWorker(to: ResourceCatalog.copper)
        game.assignWorker(to: ResourceCatalog.copper)
        game.assignWorker(to: ResourceCatalog.tin)
        game.assignWorker(to: ResourceCatalog.tin)
        game.assignWorker(to: ResourceCatalog.tree)
        game.assignWorker(to: ResourceCatalog.tree)
        game.assignWorker(to: ResourceCatalog.tree)
        game.assignWorker(to: ResourceCatalog.tree)

        XCTAssertEqual(game.assignedWorkers(for: ResourceCatalog.copper), 3)
        XCTAssertEqual(game.assignedWorkers(for: ResourceCatalog.tin), 2)
        XCTAssertEqual(game.assignedWorkers(for: ResourceCatalog.tree), 4)
        XCTAssertEqual(game.unassignedWorkerCount, 1)
        XCTAssertEqual(game.assignedWorkers(for: .miningSpot), 5)
        XCTAssertEqual(game.gatheringNodes(for: .miningSpot).count, 5)
        XCTAssertTrue(game.gatheringNodes(for: .miningSpot).allSatisfy(\.isOccupied))
        XCTAssertTrue(game.canAssignWorker(to: ResourceCatalog.copper))

        game.assignWorker(to: ResourceCatalog.copper)
        XCTAssertEqual(game.assignedWorkers(for: ResourceCatalog.copper), 4)
        XCTAssertEqual(game.unassignedWorkerCount, 0)
        XCTAssertFalse(game.canAssignWorker(to: ResourceCatalog.tin))
    }

    func testRatFightPaysOnceAndStopsAtZeroHP() throws {
        let game = try makeGame()
        let goldBefore = game.inventory.quantity(of: .gold)
        let meatBefore = game.inventory.quantity(of: .ratMeat)
        let xpBefore = game.skills[.combat]?.totalXP ?? 0

        let first = game.resolveFight(EnemyCatalog.rat)
        XCTAssertNotNil(first)
        XCTAssertEqual(first?.victory, true)
        XCTAssertEqual(first?.blows.last?.healthAfter, 0)
        XCTAssertFalse(first?.blows.dropLast().contains { $0.target == .enemy && $0.healthAfter == 0 } ?? true)
        XCTAssertEqual(game.skills[.combat]?.totalXP, xpBefore + EnemyCatalog.rat.combatXP)

        let goldAfterWin = game.inventory.quantity(of: .gold)
        let goldGained = goldAfterWin - goldBefore
        XCTAssertGreaterThanOrEqual(goldGained, 0)
        XCTAssertLessThanOrEqual(goldGained, 5)
        let meatGained = game.inventory.quantity(of: .ratMeat) - meatBefore
        XCTAssertGreaterThanOrEqual(meatGained, 0)
        XCTAssertLessThanOrEqual(meatGained, 2)

        let second = game.resolveFight(EnemyCatalog.rat)
        XCTAssertNil(second)
        XCTAssertEqual(game.inventory.quantity(of: .gold), goldAfterWin)
        XCTAssertEqual(game.skills[.combat]?.totalXP, xpBefore + EnemyCatalog.rat.combatXP)
    }

    func testRetiredTasksAndSeedItemsAreRemoved() throws {
        let schema = gameSchema
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        let context = container.mainContext

        let record = PlayerRecord(completedTaskIDsRaw: "stock-wood,hire-first-worker,mining-practice")
        context.insert(record)

        let seed = InventoryEntry(itemID: .wood, quantity: 4)
        seed.itemID = "appleSeed"
        context.insert(seed)

        let legacyPickaxe = InventoryEntry(itemID: .wood, quantity: 2)
        legacyPickaxe.itemID = "pickaxe"
        context.insert(legacyPickaxe)

        let game = GameController(modelContext: context)
        self.container = container
        self.game = game

        XCTAssertEqual(game.playerRecord.completedTaskIDs, Set(["hire-first-worker"]))
        XCTAssertEqual(game.currentTask()?.id, "assign-worker")
        XCTAssertEqual(game.inventory.quantity(of: .stonePickaxe), 2)
        XCTAssertEqual(
            (try context.fetch(FetchDescriptor<InventoryEntry>())).filter { $0.itemID == "appleSeed" }.count,
            0
        )
        XCTAssertFalse(InventoryItemID.allCases.map(\.rawValue).contains("appleSeed"))
        XCTAssertFalse(InventoryItemID.allCases.map(\.rawValue).contains("seedPack"))
    }

    private func claimCurrent(_ game: GameController, expectedReward: Int) {
        guard let task = game.currentTask() else {
            XCTFail("Expected a current task")
            return
        }
        let before = game.inventory.quantity(of: .gold)
        game.claim(task)
        XCTAssertEqual(game.inventory.quantity(of: .gold), before + expectedReward)
        XCTAssertTrue(game.playerRecord.completedTaskIDs.contains(task.id))
        let after = game.inventory.quantity(of: .gold)
        game.claim(task)
        XCTAssertEqual(game.inventory.quantity(of: .gold), after)
    }

    private func storedQuantity(of item: InventoryItemID, in game: GameController) -> Int {
        game.workerStorageStacks.first { $0.0 == item }?.1 ?? 0
    }

    private var gameSchema: Schema {
        Schema([
            SkillProgress.self,
            InventoryEntry.self,
            WorkerPool.self,
            PlayerCombatState.self,
            PlayerRecord.self
        ])
    }

    private func makeGame() throws -> GameController {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: gameSchema, configurations: configuration)
        let game = GameController(modelContext: container.mainContext)
        self.container = container
        self.game = game
        return game
    }
}

private extension GameController {
    func purchaseSucceeds(_ listing: StoreListing) -> Bool {
        let beforeGold = inventory.quantity(of: .gold)
        purchase(listing, quantity: 1)
        return inventory.quantity(of: .gold) < beforeGold
    }
}
