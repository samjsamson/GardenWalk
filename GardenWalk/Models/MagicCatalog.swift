import Foundation
import SwiftUI

enum CombatStyle: String, Hashable {
    case melee
    case magic
}

struct SpellDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let blurb: String
    let requiredMagicLevel: Int
    let baseDamage: Int
    /// Magic XP granted when the spell deals damage.
    let magicXP: Int
    let runes: [CraftingIngredient]

    var costLabel: String {
        runes.map { "\($0.quantity) \($0.item.displayName)" }.joined(separator: " + ")
    }
}

enum MagicCatalog {
    static let spells: [SpellDefinition] = [
        SpellDefinition(
            id: "air-strike",
            name: "Air Strike",
            blurb: "A light bolt of air.",
            requiredMagicLevel: 1,
            baseDamage: 2,
            magicXP: 10,
            runes: [
                CraftingIngredient(item: .airRune, quantity: 1),
                CraftingIngredient(item: .mindRune, quantity: 1)
            ]
        ),
        SpellDefinition(
            id: "water-strike",
            name: "Water Strike",
            blurb: "A heavier bolt of water.",
            requiredMagicLevel: 5,
            baseDamage: 4,
            magicXP: 18,
            runes: [
                CraftingIngredient(item: .waterRune, quantity: 1),
                CraftingIngredient(item: .airRune, quantity: 1),
                CraftingIngredient(item: .mindRune, quantity: 1)
            ]
        ),
        SpellDefinition(
            id: "earth-strike",
            name: "Earth Strike",
            blurb: "A blunt bolt of earth.",
            requiredMagicLevel: 9,
            baseDamage: 6,
            magicXP: 28,
            runes: [
                CraftingIngredient(item: .earthRune, quantity: 1),
                CraftingIngredient(item: .airRune, quantity: 1),
                CraftingIngredient(item: .mindRune, quantity: 1)
            ]
        ),
        SpellDefinition(
            id: "fire-strike",
            name: "Fire Strike",
            blurb: "A hot bolt of fire.",
            requiredMagicLevel: 13,
            baseDamage: 8,
            magicXP: 40,
            runes: [
                CraftingIngredient(item: .fireRune, quantity: 1),
                CraftingIngredient(item: .airRune, quantity: 1),
                CraftingIngredient(item: .mindRune, quantity: 1)
            ]
        )
    ]

    static func spell(id: String) -> SpellDefinition? {
        spells.first { $0.id == id }
    }

    static func displayName(for item: InventoryItemID) -> String? {
        switch item {
        case .airRune: "Air Rune"
        case .waterRune: "Water Rune"
        case .earthRune: "Earth Rune"
        case .fireRune: "Fire Rune"
        case .mindRune: "Mind Rune"
        case .airStaff: "Air Staff"
        case .apprenticeWand: "Apprentice Wand"
        case .oakStaff: "Oak Staff"
        case .wizardHat: "Wizard Hat"
        case .wizardRobe: "Wizard Robe"
        case .wizardSkirt: "Wizard Skirt"
        case .galeStaff: "Gale Staff"
        case .moonlitHat: "Moonlit Hat"
        case .duskRobe: "Dusk Robe"
        default: nil
        }
    }

    static func details(for item: InventoryItemID) -> ItemDetails? {
        switch item {
        case .airRune:
            return mote("A pale rune of moving air.", "Made at the Air Altar. Used in every basic strike spell.")
        case .waterRune:
            return mote("A blue rune of flowing water.", "Made at the Water Altar. Used for Water Strike.")
        case .earthRune:
            return mote("A brown rune of packed earth.", "Made at the Earth Altar. Used for Earth Strike.")
        case .fireRune:
            return mote("An orange rune of heat.", "Made at the Fire Altar. Used for Fire Strike.")
        case .mindRune:
            return mote("A quiet rune that shapes a spell.", "Made at the Mind Altar. Every basic strike spell uses one.")
        case .airStaff:
            return gear("A staff that keeps a thread of air ready.", "Crafted. Equip in the Weapon slot. While worn, Air Strike and the other strikes do not spend Air Runes. Mind and elemental runes are still required.", sell: 24)
        case .apprenticeWand:
            return gear("A short wand for first spells.", "Crafted. Equip in the Weapon slot. Its Magic bonus adds to spell damage.", sell: 8)
        case .oakStaff:
            return gear("A longer staff with a copper collar.", "Crafted. Equip in the Weapon slot. Stronger Magic bonus than the apprentice wand.", sell: 18)
        case .wizardHat:
            return gear("A soft hat stitched from leather.", "Crafted. Equip in the Helmet slot. Adds a little Magic and Defense.", sell: 6)
        case .wizardRobe:
            return gear("A robe lined with bitterleaf.", "Crafted. Equip in the Chest slot. Adds Magic and a little Defense.", sell: 16)
        case .wizardSkirt:
            return gear("A split skirt that matches the robe.", "Crafted. Equip in the Legs slot. Adds Magic and a little Defense.", sell: 12)
        case .galeStaff:
            return gear("A staff that hums in a breeze.", "Dropped by goblins. Cannot be crafted. Equip in the Weapon slot for a high Magic bonus.", sell: 80)
        case .moonlitHat:
            return gear("A pale hat found on skeletons.", "Dropped by skeletons. Cannot be crafted. Equip in the Helmet slot.", sell: 40)
        case .duskRobe:
            return gear("A dark robe taken from a thief.", "Dropped by thieves. Cannot be crafted. Equip in the Chest slot.", sell: 90)
        default:
            return nil
        }
    }

    static func art(for item: InventoryItemID) -> ItemArt? {
        switch item {
        case .airRune:
            return ItemArtCatalog.symbol(item, category: .material, symbol: "wind", tint: Color(red: 0.75, green: 0.88, blue: 0.95), secondary: ItemPalette.steel)
        case .waterRune:
            return ItemArtCatalog.symbol(item, category: .material, symbol: "drop.fill", tint: Color(red: 0.35, green: 0.58, blue: 0.86), secondary: ItemPalette.steel)
        case .earthRune:
            return ItemArtCatalog.symbol(item, category: .material, symbol: "hexagon.fill", tint: ItemPalette.stone, secondary: GardenPalette.moss)
        case .fireRune:
            return ItemArtCatalog.symbol(item, category: .material, symbol: "flame.fill", tint: Color(red: 0.90, green: 0.38, blue: 0.16), secondary: ItemPalette.goldDeep)
        case .mindRune:
            return ItemArtCatalog.symbol(item, category: .material, symbol: "brain.head.profile", tint: Color(red: 0.62, green: 0.55, blue: 0.85), secondary: ItemPalette.steelDeep)
        case .airStaff, .apprenticeWand, .oakStaff, .galeStaff:
            return ItemArtCatalog.symbol(item, category: .weapon, symbol: "wand.and.rays", tint: staffTint(item), secondary: ItemPalette.wood)
        case .wizardHat, .moonlitHat:
            return ItemArtCatalog.symbol(item, category: .tool, symbol: "crown.fill", tint: hatTint(item), secondary: ItemPalette.gold)
        case .wizardRobe, .wizardSkirt, .duskRobe:
            return ItemArtCatalog.symbol(item, category: .tool, symbol: "tshirt.fill", tint: robeTint(item), secondary: ItemPalette.steel)
        default:
            return nil
        }
    }

    static func equipmentDefinitions() -> [EquippableItemDefinition] {
        [
            magicWeapon(.apprenticeWand, magic: 2, level: 1, supplies: nil),
            magicWeapon(.airStaff, magic: 3, level: 8, supplies: .airRune),
            magicWeapon(.oakStaff, magic: 4, level: 5, supplies: nil),
            magicWeapon(.galeStaff, magic: 7, level: 20, supplies: nil),
            magicArmor(.wizardHat, slot: .helmet, magic: 1, defense: 1, level: 1),
            magicArmor(.moonlitHat, slot: .helmet, magic: 3, defense: 4, level: 15),
            magicArmor(.wizardRobe, slot: .chest, magic: 2, defense: 2, level: 10),
            magicArmor(.duskRobe, slot: .chest, magic: 5, defense: 5, level: 25),
            magicArmor(.wizardSkirt, slot: .legs, magic: 1, defense: 2, level: 10)
        ]
    }

    static let recipes: [CraftingRecipeDefinition] = [
        gearRecipe("apprentice-wand", .apprenticeWand, [
            CraftingIngredient(item: .wood, quantity: 3),
            CraftingIngredient(item: .stone, quantity: 1)
        ], level: 1, xp: 15),
        gearRecipe("air-staff", .airStaff, [
            CraftingIngredient(item: .wood, quantity: 6),
            CraftingIngredient(item: .airRune, quantity: 2)
        ], level: 8, xp: 35),
        gearRecipe("oak-staff", .oakStaff, [
            CraftingIngredient(item: .wood, quantity: 6),
            CraftingIngredient(item: .copperOre, quantity: 2)
        ], level: 5, xp: 30),
        gearRecipe("wizard-hat", .wizardHat, [
            CraftingIngredient(item: .leather, quantity: 2)
        ], level: 1, xp: 12),
        gearRecipe("wizard-robe", .wizardRobe, [
            CraftingIngredient(item: .leather, quantity: 4),
            CraftingIngredient(item: .bitterleaf, quantity: 1)
        ], level: 10, xp: 40),
        gearRecipe("wizard-skirt", .wizardSkirt, [
            CraftingIngredient(item: .leather, quantity: 3),
            CraftingIngredient(item: .bitterleaf, quantity: 1)
        ], level: 10, xp: 30)
    ]

    private static func mote(_ summary: String, _ effect: String) -> ItemDetails {
        ItemDetails(summary: summary, effect: effect, sellValue: 3)
    }

    private static func gear(_ summary: String, _ effect: String, sell: Int) -> ItemDetails {
        ItemDetails(summary: summary, effect: effect, sellValue: sell)
    }

    private static func magicWeapon(
        _ item: InventoryItemID,
        magic: Int,
        level: Int,
        supplies: InventoryItemID?
    ) -> EquippableItemDefinition {
        EquippableItemDefinition(
            item: item,
            slot: .weapon,
            bonuses: EquipmentBonuses(
                attack: 1,
                magic: magic,
                suppliedRune: supplies,
                requiredLevel: level,
                requiredSkill: .magic,
                attackSpeed: 5,
                weaponKind: "Staff"
            )
        )
    }

    private static func magicArmor(
        _ item: InventoryItemID,
        slot: EquipmentSlot,
        magic: Int,
        defense: Int,
        level: Int
    ) -> EquippableItemDefinition {
        EquippableItemDefinition(
            item: item,
            slot: slot,
            bonuses: EquipmentBonuses(defense: defense, magic: magic, requiredLevel: level, requiredSkill: .magic)
        )
    }

    private static func gearRecipe(
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
            category: .magic,
            requiredSkill: .magic,
            requiredSkillLevel: level,
            skillXP: xp
        )
    }

    private static func staffTint(_ item: InventoryItemID) -> Color {
        switch item {
        case .galeStaff, .airStaff: Color(red: 0.55, green: 0.75, blue: 0.90)
        case .oakStaff: ItemPalette.woodLight
        default: ItemPalette.wood
        }
    }

    private static func hatTint(_ item: InventoryItemID) -> Color {
        item == .moonlitHat ? Color(red: 0.82, green: 0.86, blue: 0.95) : Color(red: 0.28, green: 0.24, blue: 0.48)
    }

    private static func robeTint(_ item: InventoryItemID) -> Color {
        switch item {
        case .duskRobe: Color(red: 0.22, green: 0.16, blue: 0.32)
        case .wizardSkirt: Color(red: 0.32, green: 0.28, blue: 0.55)
        default: Color(red: 0.25, green: 0.22, blue: 0.48)
        }
    }
}
