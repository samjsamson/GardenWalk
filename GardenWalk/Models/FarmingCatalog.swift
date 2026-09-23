import Foundation
import SwiftUI

struct FarmPlot: Equatable {
    var cropID: String?
    var plantedAt: Date?
}

enum FarmPlotCodec {
    static let count = 4
    static let unlockLevels = [1, 3, 7, 12]

    static func decode(_ raw: String?) -> [FarmPlot] {
        var plots = Array(repeating: FarmPlot(), count: count)
        let parts = (raw ?? "").split(separator: ";", omittingEmptySubsequences: false).map(String.init)
        for (index, part) in parts.enumerated() where index < count && !part.isEmpty {
            let bits = part.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            guard bits.count == 2, !bits[0].isEmpty, let time = TimeInterval(bits[1]) else { continue }
            plots[index] = FarmPlot(cropID: bits[0], plantedAt: Date(timeIntervalSince1970: time))
        }
        return plots
    }

    static func encode(_ plots: [FarmPlot]) -> String {
        plots.map { plot in
            guard let id = plot.cropID, let date = plot.plantedAt else { return "" }
            return "\(id)@\(date.timeIntervalSince1970)"
        }.joined(separator: ";")
    }
}

struct CropDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let seed: InventoryItemID
    let harvest: InventoryItemID
    let harvestQuantity: Int
    let farmingLevel: Int
    let growth: TimeInterval
    let xp: Int
    let seedPrice: Int
    let summary: String
}

struct PotionDefinition: Equatable {
    let item: InventoryItemID
    let name: String
    let summary: String
    let effect: String
    let duration: TimeInterval?
    let heal: Int?
    let sellValue: Int
}

enum AutoGathererBalance {
    static let requiredTotalLevel = 50
    static let price = 2500
    static let sellValue = 250
    /// One basic resource per minute, slower than a single worker's 30 second cycle.
    static let interval: TimeInterval = 60
    /// Same catalog entries as manual gathering so XP cannot drift apart.
    static var gatherResources: [ResourceDefinition] {
        [ResourceCatalog.copper, ResourceCatalog.tree, ResourceCatalog.shrimp]
    }
}

enum FarmingCatalog {
    static let potionDuration: TimeInterval = 3 * 60
    static let attackBonus = 3
    static let strengthBonus = 3
    static let defenseBonus = 3
    static let magicBonus = 4

    static let crops: [CropDefinition] = [
        CropDefinition(id: "turnip", name: "Turnip", seed: .turnipSeed, harvest: .turnip, harvestQuantity: 3, farmingLevel: 1, growth: 40, xp: 12, seedPrice: 3, summary: "A quick root crop and a simple meal."),
        CropDefinition(id: "carrot", name: "Carrot", seed: .carrotSeed, harvest: .carrot, harvestQuantity: 2, farmingLevel: 10, growth: 75, xp: 22, seedPrice: 10, summary: "A sweeter crop that heals more than turnips."),
        CropDefinition(id: "bitterleaf", name: "Bitterleaf", seed: .bitterleafSeed, harvest: .bitterleaf, harvestQuantity: 3, farmingLevel: 15, growth: 90, xp: 28, seedPrice: 16, summary: "A sharp herb used in tonics and robes."),
        CropDefinition(id: "cabbage", name: "Cabbage", seed: .cabbageSeed, harvest: .cabbage, harvestQuantity: 2, farmingLevel: 20, growth: 120, xp: 36, seedPrice: 24, summary: "A filling crop for stronger meals and draughts."),
        CropDefinition(id: "glowcap", name: "Glowcap", seed: .glowcapSeed, harvest: .glowcap, harvestQuantity: 2, farmingLevel: 30, growth: 150, xp: 48, seedPrice: 40, summary: "A pale mushroom used in stronger potions."),
        CropDefinition(id: "pumpkin", name: "Pumpkin", seed: .pumpkinSeed, harvest: .pumpkin, harvestQuantity: 1, farmingLevel: 35, growth: 180, xp: 55, seedPrice: 50, summary: "A slow crop with the strongest farm-grown meal. Sometimes yields a sunseed.")
    ]

    static let potions: [PotionDefinition] = [
        PotionDefinition(item: .heartyTonic, name: "Hearty Tonic", summary: "A thick vegetable tonic.", effect: "Drink to restore 18 HP.", duration: nil, heal: 18, sellValue: 8),
        PotionDefinition(item: .keenOil, name: "Keen Oil", summary: "A sharp herbal oil.", effect: "Drink for +\(attackBonus) Attack for \(Int(potionDuration / 60)) minutes.", duration: potionDuration, heal: nil, sellValue: 12),
        PotionDefinition(item: .oakDraught, name: "Oak Draught", summary: "A heavy cabbage draught.", effect: "Drink for +\(strengthBonus) Strength for \(Int(potionDuration / 60)) minutes.", duration: potionDuration, heal: nil, sellValue: 16),
        PotionDefinition(item: .barkTincture, name: "Bark Tincture", summary: "A bitter defensive tincture.", effect: "Drink for +\(defenseBonus) Defense for \(Int(potionDuration / 60)) minutes.", duration: potionDuration, heal: nil, sellValue: 16),
        PotionDefinition(item: .sparkPhilter, name: "Spark Philter", summary: "A glowing mushroom philter.", effect: "Drink for +\(magicBonus) Magic for \(Int(potionDuration / 60)) minutes.", duration: potionDuration, heal: nil, sellValue: 20),
        PotionDefinition(item: .gatherersBrew, name: "Gatherer's Brew", summary: "A bright field brew.", effect: "Drink so each manual gather grants one extra main resource for \(Int(potionDuration / 60)) minutes.", duration: potionDuration, heal: nil, sellValue: 18)
    ]

    static func crop(id: String) -> CropDefinition? {
        crops.first { $0.id == id }
    }

    static func crop(seed: InventoryItemID) -> CropDefinition? {
        crops.first { $0.seed == seed }
    }

    static func potion(for item: InventoryItemID) -> PotionDefinition? {
        potions.first { $0.item == item }
    }

    static func healAmount(for item: InventoryItemID) -> Int? {
        if let potion = potion(for: item) { return potion.heal }
        return switch item {
        case .apple: 3
        case .shrimp: 2
        case .sardine: 4
        case .trout: 6
        case .salmon: 8
        case .lobster: 10
        case .swordfish: 14
        case .milk: 2
        case .cowMeat: 6
        case .ratMeat: 3
        case .porkMeat: 5
        case .turnip: 4
        case .carrot: 8
        case .cabbage: 14
        case .pumpkin: 22
        default: nil
        }
    }

    static func displayName(for item: InventoryItemID) -> String? {
        if item == .sunseed { return "Sunseed" }
        if item == .autoGatherer { return "Auto-Gatherer" }
        if let crop = crops.first(where: { $0.seed == item }) { return "\(crop.name) Seed" }
        if let crop = crops.first(where: { $0.harvest == item }) { return crop.name }
        return potion(for: item)?.name
    }

    static func details(for item: InventoryItemID) -> ItemDetails? {
        if item == .autoGatherer {
            return ItemDetails(
                summary: "A clockwork collector for basic resources.",
                effect: "Requires Total Level \(AutoGathererBalance.requiredTotalLevel). While you own one, it places 1 copper ore, wood, or shrimp into Worker Storage every \(Int(AutoGathererBalance.interval)) seconds and grants the same Mining, Woodcutting, or Fishing XP as gathering that resource by hand. Extra copies do not speed it up. Selling it stops the machine.",
                sellValue: AutoGathererBalance.sellValue
            )
        }
        if item == .sunseed {
            return ItemDetails(summary: "A rare seed that ripens inside pumpkins.", effect: "Sell it at the General Store. It is not planted.", sellValue: 20)
        }
        if let crop = crops.first(where: { $0.seed == item }) {
            let seconds = Int(crop.growth)
            return ItemDetails(
                summary: "Plant this in Farming.",
                effect: "Requires Farming \(crop.farmingLevel). Grows in \(seconds) seconds, then harvest \(crop.harvestQuantity) \(crop.harvest.displayName) and \(crop.xp) Farming XP.",
                sellValue: max(1, crop.seedPrice / 3)
            )
        }
        if let crop = crops.first(where: { $0.harvest == item }) {
            if let heal = healAmount(for: item) {
                return ItemDetails(summary: crop.summary, effect: "Eat to restore \(heal) HP.", sellValue: max(2, crop.seedPrice / 2))
            }
            return ItemDetails(summary: crop.summary, effect: "A potion ingredient. It is not eaten.", sellValue: max(2, crop.seedPrice / 2))
        }
        if let potion = potion(for: item) {
            return ItemDetails(summary: potion.summary, effect: potion.effect, sellValue: potion.sellValue)
        }
        return nil
    }

    static func art(for item: InventoryItemID) -> ItemArt? {
        switch item {
        case .turnipSeed:
            return ItemArtCatalog.cropSeed(item, picture: .turnip, tint: Color(red: 0.93, green: 0.86, blue: 0.62), secondary: GardenPalette.leaf)
        case .carrotSeed:
            return ItemArtCatalog.cropSeed(item, picture: .carrot, tint: Color(red: 0.93, green: 0.52, blue: 0.18), secondary: GardenPalette.leaf)
        case .cabbageSeed:
            return ItemArtCatalog.cropSeed(item, picture: .cabbage, tint: Color(red: 0.48, green: 0.72, blue: 0.34), secondary: GardenPalette.moss)
        case .pumpkinSeed:
            return ItemArtCatalog.cropSeed(item, picture: .pumpkin, tint: Color(red: 0.90, green: 0.46, blue: 0.12), secondary: ItemPalette.goldDeep)
        case .bitterleafSeed:
            return ItemArtCatalog.cropSeed(item, picture: .herb, tint: Color(red: 0.28, green: 0.48, blue: 0.22), secondary: ItemPalette.wood)
        case .glowcapSeed:
            return ItemArtCatalog.cropSeed(item, picture: .glowcap, tint: Color(red: 0.72, green: 0.70, blue: 0.95), secondary: Color(red: 0.45, green: 0.38, blue: 0.72))
        case .turnip:
            return ItemArtCatalog.symbol(item, category: .food, symbol: "circle.fill", tint: Color(red: 0.86, green: 0.78, blue: 0.62), secondary: GardenPalette.leaf)
        case .carrot:
            return ItemArtCatalog.symbol(item, category: .food, symbol: "triangle.fill", tint: Color(red: 0.92, green: 0.48, blue: 0.16), secondary: GardenPalette.leaf)
        case .cabbage:
            return ItemArtCatalog.symbol(item, category: .food, symbol: "circle.fill", tint: Color(red: 0.55, green: 0.72, blue: 0.38), secondary: GardenPalette.moss)
        case .pumpkin:
            return ItemArtCatalog.symbol(item, category: .food, symbol: "circle.fill", tint: Color(red: 0.90, green: 0.48, blue: 0.12), secondary: GardenPalette.moss)
        case .bitterleaf:
            return ItemArtCatalog.symbol(item, category: .material, symbol: "leaf.fill", tint: Color(red: 0.35, green: 0.55, blue: 0.28), secondary: ItemPalette.wood)
        case .glowcap:
            return ItemArtCatalog.symbol(item, category: .material, symbol: "moon.fill", tint: Color(red: 0.72, green: 0.78, blue: 0.95), secondary: GardenPalette.moss)
        case .sunseed:
            return ItemArtCatalog.symbol(item, category: .material, symbol: "sun.max.fill", tint: ItemPalette.gold, secondary: ItemPalette.goldDeep)
        case .heartyTonic, .keenOil, .oakDraught, .barkTincture, .sparkPhilter, .gatherersBrew:
            return ItemArtCatalog.symbol(item, category: .consumable, symbol: "flask.fill", tint: potionTint(item), secondary: ItemPalette.steel)
        case .autoGatherer:
            return ItemArtCatalog.symbol(item, category: .upgrade, symbol: "gearshape.2.fill", tint: ItemPalette.steel, secondary: ItemPalette.copper)
        default:
            return nil
        }
    }

    static let recipes: [CraftingRecipeDefinition] = [
        potionRecipe("hearty-tonic", .heartyTonic, [
            CraftingIngredient(item: .turnip, quantity: 1),
            CraftingIngredient(item: .bitterleaf, quantity: 1)
        ], level: 8, xp: 18),
        potionRecipe("keen-oil", .keenOil, [
            CraftingIngredient(item: .carrot, quantity: 1),
            CraftingIngredient(item: .bitterleaf, quantity: 1)
        ], level: 12, xp: 24),
        potionRecipe("oak-draught", .oakDraught, [
            CraftingIngredient(item: .cabbage, quantity: 1),
            CraftingIngredient(item: .bitterleaf, quantity: 1)
        ], level: 20, xp: 32),
        potionRecipe("bark-tincture", .barkTincture, [
            CraftingIngredient(item: .cabbage, quantity: 1),
            CraftingIngredient(item: .glowcap, quantity: 1)
        ], level: 24, xp: 36),
        potionRecipe("spark-philter", .sparkPhilter, [
            CraftingIngredient(item: .glowcap, quantity: 2)
        ], level: 30, xp: 42),
        potionRecipe("gatherers-brew", .gatherersBrew, [
            CraftingIngredient(item: .carrot, quantity: 2),
            CraftingIngredient(item: .glowcap, quantity: 1)
        ], level: 28, xp: 40)
    ]

    private static func potionRecipe(
        _ id: String,
        _ output: InventoryItemID,
        _ ingredients: [CraftingIngredient],
        level: Int,
        xp: Int
    ) -> CraftingRecipeDefinition {
        CraftingRecipeDefinition(
            id: id,
            output: output,
            outputQuantity: 1,
            ingredients: ingredients,
            category: .provisions,
            requiredSkill: .farming,
            requiredSkillLevel: level,
            skillXP: xp
        )
    }

    private static func potionTint(_ item: InventoryItemID) -> Color {
        switch item {
        case .heartyTonic: Color(red: 0.72, green: 0.45, blue: 0.22)
        case .keenOil: Color(red: 0.85, green: 0.28, blue: 0.22)
        case .oakDraught: Color(red: 0.45, green: 0.32, blue: 0.18)
        case .barkTincture: Color(red: 0.42, green: 0.48, blue: 0.32)
        case .sparkPhilter: Color(red: 0.55, green: 0.45, blue: 0.85)
        default: Color(red: 0.35, green: 0.62, blue: 0.38)
        }
    }
}
