import Foundation

enum StoreCategory: String, CaseIterable, Identifiable {
    case tools
    case machines
    case seeds

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tools: "Tools"
        case .machines: "Machines"
        case .seeds: "Seeds"
        }
    }
}

enum StoreProduct: Equatable {
    case worker
    case inventoryItem(InventoryItemID)
    case backpackUpgrade
}

struct StoreListing: Identifiable, Equatable {
    let id: String
    let name: String
    let product: StoreProduct
    let goldCost: Int
    let quantity: Int
    let category: StoreCategory
    let requiredSkill: SkillKind?
    let requiredSkillLevel: Int?
    let prerequisiteID: String?
    var requiredTotalLevel: Int? = nil

    func price(backpackTier: Int) -> Int {
        guard product == .backpackUpgrade else { return goldCost }
        return goldCost * (backpackTier + 1)
    }

    var summary: String {
        switch product {
        case .worker:
            "A helper you assign to a resource spot."
        case .backpackUpgrade:
            "A larger pack for carrying more."
        case .inventoryItem(let item):
            item.summary
        }
    }

    var effect: String {
        switch product {
        case .worker:
            "Assigned workers add resources to Worker Storage over time. Collect that storage to move everything into your inventory. Total level sets how many you can own."
        case .backpackUpgrade:
            "Each purchase increases saved inventory capacity by \(PlayerProgression.backpackCapacityPerTier)."
        case .inventoryItem(let item):
            item.effect
        }
    }
}

enum StoreCatalog {
    static let worker = StoreListing(
        id: "worker",
        name: "Worker",
        product: .worker,
        goldCost: 10,
        quantity: 1,
        category: .machines,
        requiredSkill: nil,
        requiredSkillLevel: nil,
        prerequisiteID: nil
    )

    static let fishingRod = toolListing("fishing-rod", .fishingRod, price: 12)
    static let hammer = toolListing("hammer", .hammer, price: 6)
    static let leatherBoots = toolListing("leather-boots", .leatherBoots, price: 8)
    static let leather = toolListing("leather", .leather, price: 4)

    static let stonePickaxe = toolListing("stone-pickaxe", .stonePickaxe, price: 8)
    static let copperPickaxe = toolListing("copper-pickaxe", .copperPickaxe, price: 30)
    static let bronzePickaxe = toolListing("bronze-pickaxe", .bronzePickaxe, price: 60)
    static let ironPickaxe = toolListing("iron-pickaxe", .ironPickaxe, price: 120)
    static let steelPickaxe = toolListing("steel-pickaxe", .steelPickaxe, price: 220)

    static let stoneAxe = toolListing("stone-axe", .stoneAxe, price: 8)
    static let copperAxe = toolListing("copper-axe", .copperAxe, price: 30)
    static let bronzeAxe = toolListing("bronze-axe", .bronzeAxe, price: 60)
    static let ironAxe = toolListing("iron-axe", .ironAxe, price: 120)
    static let steelAxe = toolListing("steel-axe", .steelAxe, price: 220)

    static let torch = StoreListing(
        id: "torch",
        name: "Torch",
        product: .inventoryItem(.torch),
        goldCost: 15,
        quantity: 1,
        category: .tools,
        requiredSkill: nil,
        requiredSkillLevel: nil,
        prerequisiteID: nil
    )

    static let autoGatherer = StoreListing(
        id: "auto-gatherer",
        name: "Auto-Gatherer",
        product: .inventoryItem(.autoGatherer),
        goldCost: AutoGathererBalance.price,
        quantity: 1,
        category: .machines,
        requiredSkill: nil,
        requiredSkillLevel: nil,
        prerequisiteID: nil,
        requiredTotalLevel: AutoGathererBalance.requiredTotalLevel
    )

    static let backpackUpgrade = StoreListing(
        id: "backpack-upgrade",
        name: "Backpack Upgrade",
        product: .backpackUpgrade,
        goldCost: 25,
        quantity: 1,
        category: .machines,
        requiredSkill: nil,
        requiredSkillLevel: nil,
        prerequisiteID: nil
    )

    static let all: [StoreListing] = [
        worker,
        fishingRod,
        hammer,
        leatherBoots,
        leather,
        stonePickaxe, copperPickaxe, bronzePickaxe, ironPickaxe, steelPickaxe,
        stoneAxe, copperAxe, bronzeAxe, ironAxe, steelAxe,
        torch,
        autoGatherer,
        backpackUpgrade
    ] + FarmingCatalog.crops.map { crop in
        StoreListing(
            id: "\(crop.id)-seed",
            name: "\(crop.name) Seed",
            product: .inventoryItem(crop.seed),
            goldCost: crop.seedPrice,
            quantity: 1,
            category: .seeds,
            requiredSkill: .farming,
            requiredSkillLevel: crop.farmingLevel,
            prerequisiteID: nil
        )
    }

    private static func toolListing(_ id: String, _ item: InventoryItemID, price: Int) -> StoreListing {
        StoreListing(
            id: id,
            name: item.displayName,
            product: .inventoryItem(item),
            goldCost: price,
            quantity: 1,
            category: .tools,
            requiredSkill: nil,
            requiredSkillLevel: nil,
            prerequisiteID: nil
        )
    }

    static func listing(id: String) -> StoreListing? {
        all.first { $0.id == id }
    }
}

enum PendingReward: Equatable {}

struct GatheringResult: Equatable {
    let resource: ResourceDefinition
    let xpGained: Int
    let itemDrops: [InventoryItemDrop]
}

