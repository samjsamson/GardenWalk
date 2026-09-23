import Foundation

struct ItemDetails: Equatable {
    let summary: String
    let effect: String
    let sellValue: Int
}

enum ItemCatalog {
    private static func requiredLevel(for item: InventoryItemID) -> Int {
        ResourceCatalog.all.first { $0.primaryOutput == item }?.requiredLevel ?? 1
    }

    static func details(for item: InventoryItemID) -> ItemDetails {
        switch item {
        case .gold:
            return ItemDetails(summary: "Currency used at the General Store.", effect: "Spent to buy store goods. Earned from selling, combat, tasks, and rare finds.", sellValue: 0)
        case .copperOre:
            return ItemDetails(summary: "Used to create copper equipment and other items.", effect: "Smithing material. Combined with tin to make a bronze bar.", sellValue: 2)
        case .tinOre:
            return ItemDetails(summary: "Smelted with copper ore to make bronze.", effect: "Smithing material. One tin ore and one copper ore make a bronze bar.", sellValue: 4)
        case .ironOre:
            return ItemDetails(summary: "A heavier ore used for stronger metalwork.", effect: "Gathered from Mining at Mining level \(requiredLevel(for: .ironOre)).", sellValue: 8)
        case .coal:
            return ItemDetails(summary: "Dark fuel used when smithing steel tools.", effect: "Gathered from Mining at Mining level \(requiredLevel(for: .coal)).", sellValue: 12)
        case .silverOre:
            return ItemDetails(summary: "A bright precious ore worth more than iron.", effect: "Gathered from Mining at Mining level \(requiredLevel(for: .silverOre)).", sellValue: 16)
        case .goldOre:
            return ItemDetails(summary: "A rich ore that sells for a high price.", effect: "Gathered from Mining at Mining level \(requiredLevel(for: .goldOre)).", sellValue: 28)
        case .wood:
            return ItemDetails(summary: "Basic material used for crafting.", effect: "Crafting material from trees.", sellValue: 1)
        case .apple:
            return foodDetails(item, summary: "A sweet fruit.", sellValue: 2)
        case .stone:
            return ItemDetails(summary: "Rough rock used for stone tools and weapons.", effect: "Crafting material. Also a bonus drop while mining copper.", sellValue: 1)
        case .shrimp, .sardine, .trout, .salmon, .lobster, .swordfish:
            return foodDetails(
                item,
                summary: "A catch from Fishing.",
                sellValue: fishSellValue(item),
                extra: "Caught at Fishing level \(requiredLevel(for: item))."
            )
        case .stoneAxe, .copperAxe, .bronzeAxe, .ironAxe, .steelAxe:
            return toolDetails(item, summary: "An axe that improves worker woodcutting.")
        case .stonePickaxe, .copperPickaxe, .bronzePickaxe, .ironPickaxe, .steelPickaxe:
            return toolDetails(item, summary: "A pickaxe that improves worker mining.")
        case .fishingRod:
            return ItemDetails(
                summary: "A rod used for fishing.",
                effect: "Equip in the Rod slot. Workers at the Fishing Pond hold a rod and catch fish. Better fish unlock as your Fishing level rises.",
                sellValue: 5
            )
        case .torch:
            return ItemDetails(summary: "A light source kept for future caves and dungeons.", effect: "Held in inventory. No effect yet.", sellValue: 6)
        case .stoneDagger:
            return ItemDetails(summary: "A primitive melee weapon used in combat.", effect: "Equip in the Weapon slot. Attack \(EquipmentCatalog.attackPower(for: .stoneDagger)).", sellValue: 4)
        case .copperDagger:
            return ItemDetails(summary: "A basic melee weapon used in combat.", effect: "Equip in the Weapon slot. Attack \(EquipmentCatalog.attackPower(for: .copperDagger)).", sellValue: 8)
        case .milk:
            return foodDetails(item, summary: "A drink dropped by cows.", sellValue: 3, extra: "A combat drop.")
        case .cowMeat:
            return foodDetails(item, summary: "Hearty meat from a cow.", sellValue: 4, extra: "A combat drop.")
        case .ratMeat:
            return foodDetails(item, summary: "Scrawny meat from a rat.", sellValue: 2, extra: "A common combat drop.")
        case .bones:
            return ItemDetails(summary: "Remains dropped by skeletons.", effect: "A combat drop.", sellValue: 2)
        case .porkMeat:
            return foodDetails(item, summary: "Meat dropped by pigs.", sellValue: 4, extra: "A combat drop.")
        default:
            if let details = FarmingCatalog.details(for: item) { return details }
            if let details = RunecraftingCatalog.details(for: item) { return details }
            if let details = MagicCatalog.details(for: item) { return details }
            if let record = SmithingCatalog.record(for: item) {
                return ItemDetails(summary: record.summary, effect: record.effect, sellValue: record.sellValue)
            }
            return ItemDetails(summary: item.displayName, effect: "", sellValue: 1)
        }
    }

    private static func foodDetails(
        _ item: InventoryItemID,
        summary: String,
        sellValue: Int,
        extra: String? = nil
    ) -> ItemDetails {
        let heal = FarmingCatalog.healAmount(for: item) ?? 0
        var effect = "Eat to restore \(heal) HP."
        if let extra, !extra.isEmpty {
            effect += " \(extra)"
        }
        return ItemDetails(summary: summary, effect: effect, sellValue: sellValue)
    }

    private static func toolDetails(_ item: InventoryItemID, summary: String) -> ItemDetails {
        let effect = EquipmentCatalog.workerYieldDescription(for: item) ?? "Equip this tool. The equipped tool sets the gathering bonus."
        return ItemDetails(summary: summary, effect: effect, sellValue: toolSellValue(item))
    }

    private static func toolSellValue(_ item: InventoryItemID) -> Int {
        switch item {
        case .stoneAxe, .stonePickaxe: 3
        case .copperAxe, .copperPickaxe: 8
        case .bronzeAxe, .bronzePickaxe: 14
        case .ironAxe, .ironPickaxe: 22
        case .steelAxe, .steelPickaxe: 36
        default: 3
        }
    }

    private static func fishSellValue(_ item: InventoryItemID) -> Int {
        switch item {
        case .shrimp: 2
        case .sardine: 4
        case .trout: 8
        case .salmon: 14
        case .lobster: 22
        case .swordfish: 34
        default: 2
        }
    }
}

extension InventoryItemID {
    var summary: String {
        ItemCatalog.details(for: self).summary
    }

    var effect: String {
        ItemCatalog.details(for: self).effect
    }

    var sellValue: Int {
        ItemCatalog.details(for: self).sellValue
    }
}
