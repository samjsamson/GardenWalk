import Foundation

enum GameTaskKind: Equatable {
    case hireWorker
    case assignWorker
    case collectWorkerOutput
    case sellItem
    case buyItem
    case mineCopper
    case mineTin
    case smeltBronze
    case visitAnvil
    case smithBronze
    case equipBronze
}

struct GameTaskDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let requirement: String
    let kind: GameTaskKind
    let goldReward: Int
}

enum GameTaskCatalog {
    static let all: [GameTaskDefinition] = [
        GameTaskDefinition(
            id: "hire-first-worker",
            title: "Hire Your First Worker",
            requirement: "Buy 1 worker from the General Store.",
            kind: .hireWorker,
            goldReward: 8
        ),
        GameTaskDefinition(
            id: "assign-worker",
            title: "Assign a Worker",
            requirement: "Assign that worker to any resource-gathering area.",
            kind: .assignWorker,
            goldReward: 10
        ),
        GameTaskDefinition(
            id: "gather-resources",
            title: "Gather Resources",
            requirement: "Collect resources produced by a worker.",
            kind: .collectWorkerOutput,
            goldReward: 12
        ),
        GameTaskDefinition(
            id: "sell-item",
            title: "Sell an Item",
            requirement: "Sell any resource or item to the General Store.",
            kind: .sellItem,
            goldReward: 15
        ),
        GameTaskDefinition(
            id: "buy-item",
            title: "Buy an Item",
            requirement: "Purchase any item that isn't a worker from the General Store.",
            kind: .buyItem,
            goldReward: 20
        ),
        GameTaskDefinition(
            id: "mine-copper",
            title: "Mine Copper Ore",
            requirement: "Collect copper ore from Mining.",
            kind: .mineCopper,
            goldReward: 12
        ),
        GameTaskDefinition(
            id: "mine-tin",
            title: "Mine Tin Ore",
            requirement: "Reach Mining level 5, choose Tin in Mining, then collect tin ore.",
            kind: .mineTin,
            goldReward: 14
        ),
        GameTaskDefinition(
            id: "smelt-bronze",
            title: "Smelt a Bronze Bar",
            requirement: "Use the furnace in the Forge. 1 copper ore and 1 tin ore make 1 bronze bar.",
            kind: .smeltBronze,
            goldReward: 16
        ),
        GameTaskDefinition(
            id: "visit-anvil",
            title: "Visit the Anvil",
            requirement: "Open the Forge tab and select the Anvil.",
            kind: .visitAnvil,
            goldReward: 8
        ),
        GameTaskDefinition(
            id: "smith-bronze",
            title: "Smith a Bronze Item",
            requirement: "At the anvil, smith any bronze weapon or armor.",
            kind: .smithBronze,
            goldReward: 20
        ),
        GameTaskDefinition(
            id: "equip-bronze",
            title: "Equip Your Bronze Gear",
            requirement: "Equip the bronze item you smithed.",
            kind: .equipBronze,
            goldReward: 18
        )
    ]
}
