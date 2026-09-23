import Foundation

struct ResourceSecondaryDrop: Equatable {
    let item: InventoryItemID
    let amount: Int
    let chance: Double
}

struct ResourceDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let spot: ResourceSpotKind
    let skill: SkillKind
    let requiredLevel: Int
    let isPlayable: Bool
    let xpReward: Int
    let primaryOutput: InventoryItemID
    let primaryAmount: Int
    let secondaryDrops: [ResourceSecondaryDrop]
    let workerOutput: InventoryItemID
    let workerOutputAmount: Int
    let workerInterval: TimeInterval
    let workerXP: Int
}

struct GatheringNode: Identifiable, Equatable {
    let index: Int
    let resource: ResourceDefinition
    let variant: Int
    let isOccupied: Bool

    var id: String { "\(resource.spot.rawValue)-\(index)" }
}

enum ResourceCatalog {
    static let copper = ore("copper", "Copper Ore", level: 1, xp: 17, output: .copperOre, sellDrops: [
        ResourceSecondaryDrop(item: .stone, amount: 1, chance: 0.40)
    ])
    static let tin = ore("tin", "Tin Ore", level: 5, xp: 25, output: .tinOre)
    static let iron = ore("iron", "Iron Ore", level: 10, xp: 35, output: .ironOre, sellDrops: [
        ResourceSecondaryDrop(item: .gold, amount: 1, chance: 0.03)
    ])
    static let coal = ore("coal", "Coal", level: 15, xp: 40, output: .coal, workerXP: 6)
    static let silver = ore("silver", "Silver Ore", level: 20, xp: 45, output: .silverOre, workerXP: 6, sellDrops: [
        ResourceSecondaryDrop(item: .gold, amount: 2, chance: 0.05)
    ])
    static let goldOre = ore("gold-ore", "Gold Ore", level: 40, xp: 65, output: .goldOre, workerXP: 8, sellDrops: [
        ResourceSecondaryDrop(item: .gold, amount: 3, chance: 0.08)
    ])
    static let mithril = ore("mithril", "Mithril Ore", level: 30, xp: 55, output: .mithrilOre, workerXP: 8)
    static let adamant = ore("adamant", "Adamant Ore", level: 50, xp: 80, output: .adamantOre, workerXP: 10)

    static let tree = wood("tree", "Tree", level: 1, xp: 28)
    static let oak = wood("oak", "Oak", level: 15, xp: 45)
    static let willow = wood("willow", "Willow", level: 30, xp: 65)
    static let maple = wood("maple", "Maple", level: 40, xp: 90, workerXP: 10)

    static let runeEssence = ResourceDefinition(
        id: "rune-essence",
        name: "Rune Essence",
        spot: .runeMine,
        skill: .mining,
        requiredLevel: 10,
        isPlayable: true,
        xpReward: 30,
        primaryOutput: .runeEssence,
        primaryAmount: 1,
        secondaryDrops: [],
        workerOutput: .runeEssence,
        workerOutputAmount: 1,
        workerInterval: WorkerBalance.productionInterval,
        workerXP: 6
    )

    static let shrimp = fish("shrimp", "Shrimp", level: 1, xp: 15, output: .shrimp, workerXP: 4)
    static let sardine = fish("sardine", "Sardine", level: 5, xp: 22, output: .sardine)
    static let trout = fish("trout", "Trout", level: 10, xp: 32, output: .trout, workerXP: 6)
    static let salmon = fish("salmon", "Salmon", level: 20, xp: 45, output: .salmon, workerXP: 7)
    static let lobster = fish("lobster", "Lobster", level: 30, xp: 55, output: .lobster, workerXP: 8)
    static let swordfish = fish("swordfish", "Swordfish", level: 40, xp: 70, output: .swordfish, workerXP: 9)

    static let all: [ResourceDefinition] = [
        copper, tin, iron, coal, silver, goldOre, mithril, adamant,
        tree, oak, willow, maple,
        shrimp, sardine, trout, salmon, lobster, swordfish,
        runeEssence
    ]

    static func definition(id: String) -> ResourceDefinition? {
        all.first { $0.id == id }
    }

    static func resources(for spot: ResourceSpotKind) -> [ResourceDefinition] {
        all.filter { $0.spot == spot }
    }

    static func activeResource(for spot: ResourceSpotKind) -> ResourceDefinition? {
        resources(for: spot).first { $0.isPlayable }
    }

    private static func ore(
        _ id: String,
        _ name: String,
        level: Int,
        xp: Int,
        output: InventoryItemID,
        workerXP: Int = 5,
        sellDrops: [ResourceSecondaryDrop] = []
    ) -> ResourceDefinition {
        make(id, name, spot: .miningSpot, skill: .mining, level: level, xp: xp, output: output, drops: sellDrops, workerXP: workerXP)
    }

    private static func wood(
        _ id: String,
        _ name: String,
        level: Int,
        xp: Int,
        workerXP: Int = 5
    ) -> ResourceDefinition {
        make(id, name, spot: .treePlot, skill: .woodcutting, level: level, xp: xp, output: .wood, drops: [], workerXP: workerXP)
    }

    private static func fish(
        _ id: String,
        _ name: String,
        level: Int,
        xp: Int,
        output: InventoryItemID,
        workerXP: Int = 5
    ) -> ResourceDefinition {
        make(id, name, spot: .fishingPond, skill: .fishing, level: level, xp: xp, output: output, drops: [], workerXP: workerXP)
    }

    private static func make(
        _ id: String,
        _ name: String,
        spot: ResourceSpotKind,
        skill: SkillKind,
        level: Int,
        xp: Int,
        output: InventoryItemID,
        drops: [ResourceSecondaryDrop],
        workerXP: Int
    ) -> ResourceDefinition {
        ResourceDefinition(
            id: id,
            name: name,
            spot: spot,
            skill: skill,
            requiredLevel: level,
            isPlayable: true,
            xpReward: xp,
            primaryOutput: output,
            primaryAmount: 1,
            secondaryDrops: drops,
            workerOutput: output,
            workerOutputAmount: 1,
            workerInterval: WorkerBalance.productionInterval,
            workerXP: workerXP
        )
    }
}
