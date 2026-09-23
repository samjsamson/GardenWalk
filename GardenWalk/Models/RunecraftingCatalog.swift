import Foundation
import SwiftUI

struct AltarDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let rune: InventoryItemID
    let runecraftingLevel: Int
    /// Runes produced for each Rune Essence spent.
    let runesPerEssence: Int
    let xp: Int

}

enum RunecraftingCatalog {
    /// Without a Rune Pouch, one essence is shaped at a time.
    static let plainBatch = 1
    /// A Rune Pouch lets one altar visit shape several essence at once.
    static let pouchBatch = 5
    static let pouchLevel = 20

    static let altars: [AltarDefinition] = [
        AltarDefinition(id: "air-altar", name: "Air Altar", rune: .airRune, runecraftingLevel: 1, runesPerEssence: 1, xp: 5),
        AltarDefinition(id: "mind-altar", name: "Mind Altar", rune: .mindRune, runecraftingLevel: 3, runesPerEssence: 1, xp: 8),
        AltarDefinition(id: "water-altar", name: "Water Altar", rune: .waterRune, runecraftingLevel: 5, runesPerEssence: 1, xp: 12),
        AltarDefinition(id: "earth-altar", name: "Earth Altar", rune: .earthRune, runecraftingLevel: 10, runesPerEssence: 2, xp: 18),
        AltarDefinition(id: "fire-altar", name: "Fire Altar", rune: .fireRune, runecraftingLevel: 15, runesPerEssence: 2, xp: 25)
    ]

    static func displayName(for item: InventoryItemID) -> String? {
        switch item {
        case .runeEssence: "Rune Essence"
        case .runePouch: "Rune Pouch"
        default: nil
        }
    }

    static func details(for item: InventoryItemID) -> ItemDetails? {
        switch item {
        case .runeEssence:
            return ItemDetails(
                summary: "Unshaped stone used for runecrafting.",
                effect: "Mined at Mining level 5. Grants Mining XP. Craft it at an altar on the Forge tab to make runes and earn Runecrafting XP.",
                sellValue: 3
            )
        case .runePouch:
            return ItemDetails(
                summary: "A stitched pouch for essence.",
                effect: "Requires Runecrafting \(pouchLevel). While you own one, each altar visit can craft up to \(pouchBatch) Rune Essence instead of \(plainBatch).",
                sellValue: 40
            )
        default:
            return nil
        }
    }

    static func art(for item: InventoryItemID) -> ItemArt? {
        switch item {
        case .runeEssence:
            return ItemArtCatalog.symbol(item, category: .ore, symbol: "diamond.fill", tint: Color(red: 0.72, green: 0.78, blue: 0.88), secondary: ItemPalette.stoneDark)
        case .runePouch:
            return ItemArtCatalog.symbol(item, category: .container, symbol: "bag.fill", tint: Color(red: 0.45, green: 0.32, blue: 0.62), secondary: ItemPalette.gold)
        default:
            return nil
        }
    }

    static let pouchRecipe = CraftingRecipeDefinition(
        id: "rune-pouch",
        output: .runePouch,
        outputQuantity: 1,
        ingredients: [
            CraftingIngredient(item: .leather, quantity: 2),
            CraftingIngredient(item: .runeEssence, quantity: 10)
        ],
        category: .magic,
        requiredSkill: .runecrafting,
        requiredSkillLevel: pouchLevel,
        skillXP: 50
    )
}
