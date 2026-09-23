import Foundation

enum InventoryItemID: String, CaseIterable, Codable, Identifiable {
    case gold
    case copperOre
    case tinOre
    case ironOre
    case coal
    case silverOre
    case goldOre
    case wood
    case apple
    case stone
    case shrimp
    case sardine
    case trout
    case salmon
    case lobster
    case swordfish
    case stoneAxe
    case copperAxe
    case bronzeAxe
    case ironAxe
    case steelAxe
    case stonePickaxe
    case copperPickaxe
    case bronzePickaxe
    case ironPickaxe
    case steelPickaxe
    case fishingRod
    case torch
    case stoneDagger
    case copperDagger
    case bronzeBar
    case bronzeDagger
    case milk
    case cowMeat
    case bones
    case porkMeat
    case steelDagger
    case mithrilOre
    case adamantOre
    case ironBar
    case steelBar
    case mithrilBar
    case adamantBar
    case hammer
    case leather
    case leatherBoots
    case hardLeatherBoots
    case studdedBoots
    case mithrilBoots
    case adamantBoots
    case bronzeHelmet
    case bronzePlatebody
    case bronzePlatelegs
    case bronzeShield
    case ironHelmet
    case ironPlatebody
    case ironPlatelegs
    case ironShield
    case steelHelmet
    case steelPlatebody
    case steelPlatelegs
    case steelShield
    case mithrilHelmet
    case mithrilPlatebody
    case mithrilPlatelegs
    case mithrilShield
    case adamantHelmet
    case adamantPlatebody
    case adamantPlatelegs
    case adamantShield
    case ironDagger
    case mithrilDagger
    case adamantDagger
    case bronzeSword
    case ironSword
    case steelSword
    case mithrilSword
    case adamantSword
    case bronzeScimitar
    case ironScimitar
    case steelScimitar
    case mithrilScimitar
    case adamantScimitar
    case turnipSeed
    case carrotSeed
    case cabbageSeed
    case pumpkinSeed
    case bitterleafSeed
    case glowcapSeed
    case turnip
    case carrot
    case cabbage
    case pumpkin
    case bitterleaf
    case glowcap
    case sunseed
    case heartyTonic
    case keenOil
    case oakDraught
    case barkTincture
    case sparkPhilter
    case gatherersBrew
    case runeEssence
    case airRune
    case waterRune
    case earthRune
    case fireRune
    case mindRune
    case runePouch
    case airStaff
    case apprenticeWand
    case oakStaff
    case wizardHat
    case wizardRobe
    case wizardSkirt
    case galeStaff
    case moonlitHat
    case duskRobe
    case autoGatherer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gold: "Gold"
        case .copperOre: "Copper Ore"
        case .tinOre: "Tin Ore"
        case .ironOre: "Iron Ore"
        case .coal: "Coal"
        case .silverOre: "Silver Ore"
        case .goldOre: "Gold Ore"
        case .wood: "Wood"
        case .apple: "Apple"
        case .stone: "Stone"
        case .shrimp: "Shrimp"
        case .sardine: "Sardine"
        case .trout: "Trout"
        case .salmon: "Salmon"
        case .lobster: "Lobster"
        case .swordfish: "Swordfish"
        case .stoneAxe: "Stone Axe"
        case .copperAxe: "Copper Axe"
        case .bronzeAxe: "Bronze Axe"
        case .ironAxe: "Iron Axe"
        case .steelAxe: "Steel Axe"
        case .stonePickaxe: "Stone Pickaxe"
        case .copperPickaxe: "Copper Pickaxe"
        case .bronzePickaxe: "Bronze Pickaxe"
        case .ironPickaxe: "Iron Pickaxe"
        case .steelPickaxe: "Steel Pickaxe"
        case .fishingRod: "Fishing Rod"
        case .torch: "Torch"
        case .stoneDagger: "Stone Dagger"
        case .copperDagger: "Copper Dagger"
        case .bronzeBar: "Bronze Bar"
        case .bronzeDagger: "Bronze Dagger"
        case .milk: "Milk"
        case .cowMeat: "Cow Meat"
        case .bones: "Bones"
        case .porkMeat: "Pork Meat"
        default:
            FarmingCatalog.displayName(for: self)
                ?? RunecraftingCatalog.displayName(for: self)
                ?? MagicCatalog.displayName(for: self)
                ?? SmithingCatalog.displayName(for: self)
                ?? rawValue
        }
    }

    var isWeapon: Bool {
        equipmentSlot == .weapon
    }

    var equipmentSlot: EquipmentSlot? {
        EquipmentCatalog.slot(for: self)
    }

    /// Items shown in the inventory grid, in display order.
    static var inventoryDisplayOrder: [InventoryItemID] {
        allCases
    }
}

struct InventoryItemDrop: Identifiable, Equatable {
    let item: InventoryItemID
    let amount: Int

    var id: String { item.rawValue }

    var label: String {
        "\(amount) \(item.displayName)"
    }
}
