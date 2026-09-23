import SwiftUI

enum ItemCategory: String {
    case currency
    case ore
    case material
    case food
    case tool
    case weapon
    case container
    case consumable
    case npc
    case node
    case upgrade
}

enum ItemGlyph {
    case symbol
    case goldCoins
    case worker
    case axe
    case dagger(primitive: Bool)
    case ingot
    case apple
    case ore(bright: Bool)
    case sapling
    case pickaxe
    case ration
    case torch
    case crate
    case backpack
    case helmet
    case pants
    case bootPair
    case quiver
    case copperRock
    case woodLogs
    case seed
    case cropSeed(SeedPicture)
    case scimitar
    case roughStone
    case fishingRod
    case platebody
    case shield
    case sword
    case hammer
    case hide
}

enum SeedPicture {
    case turnip
    case carrot
    case cabbage
    case pumpkin
    case herb
    case glowcap
}

enum ItemVisual: Hashable {
    case item(InventoryItemID)
    case worker
    case backpack
}

struct ItemArt {
    let displayName: String
    let category: ItemCategory
    /// Asset catalog image name. Nil until a sprite is added.
    let assetName: String?
    /// SF Symbol used when `glyph` is `.symbol` and no asset exists.
    let fallbackSymbol: String
    let tint: Color
    let secondaryTint: Color
    let glyph: ItemGlyph
}

enum ItemPalette {
    static let goldLight = Color(red: 1.0, green: 0.90, blue: 0.40)
    static let gold = Color(red: 0.95, green: 0.74, blue: 0.14)
    static let goldDeep = Color(red: 0.62, green: 0.40, blue: 0.05)

    static let woodLight = Color(red: 0.78, green: 0.56, blue: 0.32)
    static let wood = Color(red: 0.49, green: 0.32, blue: 0.16)

    static let stoneLight = Color(red: 0.82, green: 0.83, blue: 0.84)
    static let stone = Color(red: 0.58, green: 0.60, blue: 0.62)
    static let stoneDark = Color(red: 0.34, green: 0.36, blue: 0.38)

    static let copperLight = Color(red: 0.97, green: 0.64, blue: 0.36)
    static let copper = Color(red: 0.80, green: 0.42, blue: 0.20)
    static let copperDeep = Color(red: 0.50, green: 0.24, blue: 0.12)

    static let bronzeLight = Color(red: 0.92, green: 0.72, blue: 0.36)
    static let bronze = Color(red: 0.72, green: 0.48, blue: 0.18)
    static let bronzeDeep = Color(red: 0.46, green: 0.28, blue: 0.08)

    static let steelLight = Color(red: 0.94, green: 0.95, blue: 0.97)
    static let steel = Color(red: 0.70, green: 0.75, blue: 0.80)
    static let steelDeep = Color(red: 0.38, green: 0.43, blue: 0.48)

    static let skin = Color(red: 0.93, green: 0.76, blue: 0.58)
    static let ironLight = Color(red: 0.62, green: 0.64, blue: 0.66)
    static let iron = Color(red: 0.34, green: 0.36, blue: 0.38)
    static let ironDeep = Color(red: 0.16, green: 0.17, blue: 0.19)

    static let silverLight = Color(red: 0.98, green: 0.99, blue: 1.0)
    static let silver = Color(red: 0.84, green: 0.87, blue: 0.91)
    static let silverDeep = Color(red: 0.58, green: 0.62, blue: 0.68)

    static let tin = Color(red: 0.72, green: 0.76, blue: 0.78)
    static let apple = Color(red: 0.80, green: 0.18, blue: 0.16)
    static let appleLeaf = Color(red: 0.30, green: 0.58, blue: 0.28)
}

enum ItemArtCatalog {
    static func art(for item: InventoryItemID) -> ItemArt {
        switch item {
        case .gold:
            return painted(item, category: .currency, glyph: .goldCoins, tint: ItemPalette.goldLight, secondary: ItemPalette.goldDeep)
        case .stoneAxe, .copperAxe, .bronzeAxe, .ironAxe, .steelAxe:
            return painted(item, category: .tool, glyph: .axe, tint: metalLight(for: item), secondary: metalDark(for: item))
        case .stonePickaxe, .copperPickaxe, .bronzePickaxe, .ironPickaxe, .steelPickaxe:
            return painted(item, category: .tool, glyph: .pickaxe, tint: metalLight(for: item), secondary: metalDark(for: item))
        case .fishingRod:
            return painted(item, category: .tool, glyph: .fishingRod, tint: ItemPalette.woodLight, secondary: ItemPalette.wood)
        case .stoneDagger:
            return painted(item, category: .weapon, glyph: .dagger(primitive: true), tint: ItemPalette.stoneLight, secondary: ItemPalette.stoneDark)
        case .copperDagger:
            return painted(item, category: .weapon, glyph: .dagger(primitive: false), tint: ItemPalette.copperLight, secondary: ItemPalette.copperDeep)
        case .apple:
            return painted(item, category: .food, glyph: .apple, tint: ItemPalette.apple, secondary: ItemPalette.appleLeaf)
        case .torch:
            return painted(item, category: .consumable, glyph: .torch, tint: ItemPalette.gold, secondary: ItemPalette.wood)
        case .copperOre:
            return painted(item, category: .ore, glyph: .copperRock, tint: ItemPalette.stone, secondary: ItemPalette.copper)
        case .tinOre:
            return symbol(item, category: .ore, symbol: "hexagon.fill", tint: ItemPalette.tin, secondary: ItemPalette.stone)
        case .ironOre:
            return painted(item, category: .ore, glyph: .ore(bright: false), tint: ItemPalette.iron, secondary: ItemPalette.ironDeep)
        case .coal:
            return painted(item, category: .ore, glyph: .ore(bright: false), tint: Color(red: 0.16, green: 0.16, blue: 0.17), secondary: Color(red: 0.05, green: 0.05, blue: 0.06))
        case .silverOre:
            return painted(item, category: .ore, glyph: .ore(bright: true), tint: ItemPalette.silverLight, secondary: ItemPalette.silverDeep)
        case .goldOre:
            return painted(item, category: .ore, glyph: .ore(bright: true), tint: ItemPalette.goldLight, secondary: ItemPalette.goldDeep)
        case .shrimp:
            return symbol(item, category: .food, symbol: "fish.fill", tint: Color(red: 0.95, green: 0.55, blue: 0.55), secondary: ItemPalette.copper)
        case .sardine:
            return symbol(item, category: .food, symbol: "fish.fill", tint: ItemPalette.silver, secondary: Color(red: 0.35, green: 0.55, blue: 0.72))
        case .trout:
            return symbol(item, category: .food, symbol: "fish.fill", tint: Color(red: 0.45, green: 0.58, blue: 0.32), secondary: ItemPalette.wood)
        case .salmon:
            return symbol(item, category: .food, symbol: "fish.fill", tint: Color(red: 0.92, green: 0.45, blue: 0.28), secondary: ItemPalette.copperDeep)
        case .lobster:
            return symbol(item, category: .food, symbol: "fish.fill", tint: Color(red: 0.72, green: 0.16, blue: 0.14), secondary: ItemPalette.bronzeDeep)
        case .swordfish:
            return symbol(item, category: .food, symbol: "fish.fill", tint: Color(red: 0.35, green: 0.48, blue: 0.72), secondary: ItemPalette.steelDeep)
        case .stone:
            return painted(item, category: .ore, glyph: .roughStone, tint: ItemPalette.stone, secondary: ItemPalette.stoneDark)
        case .wood:
            return painted(item, category: .material, glyph: .woodLogs, tint: ItemPalette.wood, secondary: ItemPalette.woodLight)
        case .milk:
            return symbol(item, category: .food, symbol: "drop.fill", tint: Color(red: 0.85, green: 0.92, blue: 0.98), secondary: ItemPalette.steel)
        case .cowMeat, .porkMeat, .ratMeat:
            return symbol(item, category: .food, symbol: "fork.knife", tint: Color(red: 0.62, green: 0.24, blue: 0.20), secondary: ItemPalette.wood)
        case .bones:
            return symbol(item, category: .material, symbol: "capsule.fill", tint: Color(red: 0.93, green: 0.90, blue: 0.82), secondary: ItemPalette.stone)
        default:
            if let art = FarmingCatalog.art(for: item) { return art }
            if let art = RunecraftingCatalog.art(for: item) { return art }
            if let art = MagicCatalog.art(for: item) { return art }
            return smithingArt(for: item)
        }
    }

    private static func smithingArt(for item: InventoryItemID) -> ItemArt {
        guard let record = SmithingCatalog.record(for: item) else {
            return symbol(item, category: .material, symbol: "square.fill", tint: ItemPalette.stone, secondary: ItemPalette.stoneDark)
        }
        let colors = tierColors(record.tier)
        let glyph: ItemGlyph
        let category: ItemCategory
        switch record.visual {
        case .ore:
            glyph = .ore(bright: record.tier == .adamant || record.tier == .mithril)
            category = .ore
        case .bar:
            glyph = .ingot
            category = .material
        case .hammer:
            glyph = .hammer
            category = .tool
        case .leather:
            glyph = .hide
            category = .material
        case .helmet:
            glyph = .helmet
            category = .tool
        case .platebody:
            glyph = .platebody
            category = .tool
        case .platelegs:
            glyph = .pants
            category = .tool
        case .shield:
            glyph = .shield
            category = .tool
        case .boots:
            glyph = .bootPair
            category = .tool
        case .dagger:
            glyph = .dagger(primitive: false)
            category = .weapon
        case .sword:
            glyph = .sword
            category = .weapon
        case .scimitar:
            glyph = .scimitar
            category = .weapon
        }
        let tint = record.item == .leatherBoots || record.item == .hardLeatherBoots
            ? ItemPalette.woodLight
            : (record.item == .studdedBoots ? ItemPalette.bronzeLight : colors.light)
        let secondary = record.item == .leather || record.item == .leatherBoots
            ? ItemPalette.wood
            : (record.item == .hardLeatherBoots ? ItemPalette.wood : colors.deep)
        return painted(item, category: category, glyph: glyph, tint: tint, secondary: secondary)
    }

    private static func tierColors(_ tier: MetalTier?) -> (light: Color, deep: Color) {
        switch tier {
        case .bronze:
            (ItemPalette.bronzeLight, ItemPalette.bronzeDeep)
        case .iron:
            (ItemPalette.ironLight, ItemPalette.ironDeep)
        case .steel:
            (ItemPalette.steelLight, ItemPalette.steelDeep)
        case .mithril:
            (Color(red: 0.62, green: 0.78, blue: 0.92), Color(red: 0.16, green: 0.32, blue: 0.58))
        case .adamant:
            (Color(red: 0.55, green: 0.84, blue: 0.46), Color(red: 0.12, green: 0.40, blue: 0.22))
        case nil:
            (ItemPalette.woodLight, ItemPalette.wood)
        }
    }

    static func art(for visual: ItemVisual) -> ItemArt {
        switch visual {
        case .item(let item):
            art(for: item)
        case .worker:
            worker
        case .backpack:
            backpack
        }
    }

    static func art(for listing: StoreListing) -> ItemArt {
        art(for: visual(for: listing))
    }

    static func visual(for listing: StoreListing) -> ItemVisual {
        switch listing.product {
        case .worker:
            .worker
        case .inventoryItem(let item):
            .item(item)
        case .backpackUpgrade:
            .backpack
        }
    }

    static func art(for resource: ResourceDefinition) -> ItemArt {
        switch resource.id {
        case "copper":
            art(for: .copperOre)
        case "tin":
            art(for: .tinOre)
        case "iron":
            art(for: .ironOre)
        case "silver":
            art(for: .silverOre)
        case "tree":
            node(resource, symbol: "tree.fill", tint: GardenPalette.leaf, secondary: GardenPalette.moss)
        case "oak":
            node(resource, symbol: "tree.fill", tint: Color(red: 0.22, green: 0.48, blue: 0.24), secondary: ItemPalette.wood)
        case "willow":
            node(resource, symbol: "tree.fill", tint: Color(red: 0.45, green: 0.62, blue: 0.38), secondary: GardenPalette.bark)
        case "maple":
            node(resource, symbol: "leaf.fill", tint: Color(red: 0.85, green: 0.42, blue: 0.18), secondary: ItemPalette.bronzeDeep)
        case "shrimp", "sardine", "trout", "salmon", "lobster", "swordfish":
            art(for: resource.primaryOutput)
        case "coal":
            art(for: .coal)
        case "gold-ore":
            art(for: .goldOre)
        case "apple-tree":
            art(for: .apple)
        case "rose-bush":
            node(resource, symbol: "leaf.fill", tint: Color(red: 0.78, green: 0.28, blue: 0.38), secondary: GardenPalette.leaf)
        case "raspberries":
            node(resource, symbol: "circle.fill", tint: Color(red: 0.45, green: 0.22, blue: 0.55), secondary: ItemPalette.apple)
        default:
            art(for: resource.primaryOutput)
        }
    }

    static func placeholder(for slot: EquipmentSlot) -> ItemArt {
        switch slot {
        case .helmet:
            return gearArt(slot, glyph: .helmet, tint: ItemPalette.steelLight, secondary: ItemPalette.steelDeep)
        case .legs:
            return gearArt(slot, glyph: .pants, tint: ItemPalette.iron, secondary: ItemPalette.ironDeep)
        case .boots:
            return gearArt(slot, glyph: .bootPair, tint: ItemPalette.wood, secondary: ItemPalette.woodLight)
        case .arrows:
            return gearArt(slot, glyph: .quiver, tint: ItemPalette.wood, secondary: ItemPalette.steel)
        case .axe:
            return gearArt(slot, glyph: .axe, tint: ItemPalette.stoneLight, secondary: ItemPalette.stoneDark)
        case .pickaxe:
            return gearArt(slot, glyph: .pickaxe, tint: ItemPalette.ironLight, secondary: ItemPalette.ironDeep)
        case .fishingRod:
            return gearArt(slot, glyph: .fishingRod, tint: ItemPalette.woodLight, secondary: ItemPalette.wood)
        case .chest:
            return gearArt(slot, glyph: .platebody, tint: ItemPalette.steelLight, secondary: ItemPalette.steelDeep)
        case .weapon:
            return gearArt(slot, glyph: .sword, tint: ItemPalette.stoneLight, secondary: ItemPalette.stoneDark)
        case .shield:
            return gearArt(slot, glyph: .shield, tint: ItemPalette.steelLight, secondary: ItemPalette.steelDeep)
        }
    }

    private static func gearArt(
        _ slot: EquipmentSlot,
        glyph: ItemGlyph,
        symbol: String = "circle.fill",
        tint: Color,
        secondary: Color
    ) -> ItemArt {
        ItemArt(
            displayName: slot.displayName,
            category: .tool,
            assetName: nil,
            fallbackSymbol: symbol,
            tint: tint,
            secondaryTint: secondary,
            glyph: glyph
        )
    }

    static let backpack = ItemArt(
        displayName: "Backpack Upgrade",
        category: .upgrade,
        assetName: nil,
        fallbackSymbol: "bag.fill",
        tint: ItemPalette.wood,
        secondaryTint: ItemPalette.woodLight,
        glyph: .backpack
    )

    static let worker = ItemArt(
        displayName: "Worker",
        category: .npc,
        assetName: nil,
        fallbackSymbol: "person.fill",
        tint: GardenPalette.moss,
        secondaryTint: ItemPalette.skin,
        glyph: .worker
    )

    private static func metalLight(for item: InventoryItemID) -> Color {
        switch item {
        case .copperAxe, .copperPickaxe: ItemPalette.copperLight
        case .bronzeAxe, .bronzePickaxe: ItemPalette.bronzeLight
        case .ironAxe, .ironPickaxe: ItemPalette.ironLight
        case .steelAxe, .steelPickaxe: ItemPalette.steelLight
        default: ItemPalette.stoneLight
        }
    }

    private static func metalDark(for item: InventoryItemID) -> Color {
        switch item {
        case .copperAxe, .copperPickaxe: ItemPalette.copperDeep
        case .bronzeAxe, .bronzePickaxe: ItemPalette.bronzeDeep
        case .ironAxe, .ironPickaxe: ItemPalette.ironDeep
        case .steelAxe, .steelPickaxe: ItemPalette.steelDeep
        default: ItemPalette.stoneDark
        }
    }

    private static func painted(
        _ item: InventoryItemID,
        category: ItemCategory,
        glyph: ItemGlyph,
        tint: Color,
        secondary: Color
    ) -> ItemArt {
        ItemArt(
            displayName: item.displayName,
            category: category,
            assetName: nil,
            fallbackSymbol: "circle.fill",
            tint: tint,
            secondaryTint: secondary,
            glyph: glyph
        )
    }

    static func cropSeed(
        _ item: InventoryItemID,
        picture: SeedPicture,
        tint: Color,
        secondary: Color
    ) -> ItemArt {
        ItemArt(
            displayName: item.displayName,
            category: .material,
            assetName: nil,
            fallbackSymbol: "leaf.fill",
            tint: tint,
            secondaryTint: secondary,
            glyph: .cropSeed(picture)
        )
    }

    static func symbol(
        _ item: InventoryItemID,
        category: ItemCategory,
        symbol: String,
        tint: Color,
        secondary: Color
    ) -> ItemArt {
        ItemArt(
            displayName: item.displayName,
            category: category,
            assetName: nil,
            fallbackSymbol: symbol,
            tint: tint,
            secondaryTint: secondary,
            glyph: .symbol
        )
    }

    private static func node(
        _ resource: ResourceDefinition,
        symbol: String,
        tint: Color,
        secondary: Color
    ) -> ItemArt {
        ItemArt(
            displayName: resource.name,
            category: .node,
            assetName: nil,
            fallbackSymbol: symbol,
            tint: tint,
            secondaryTint: secondary,
            glyph: .symbol
        )
    }
}
