import Foundation

enum CraftingCategory: String, CaseIterable, Identifiable {
    case tools
    case smithing
    case weapons
    case provisions
    case magic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tools: "Tools"
        case .smithing: "Smithing"
        case .weapons: "Weapons"
        case .provisions: "Potions"
        case .magic: "Magic"
        }
    }
}

struct CraftingIngredient: Equatable {
    let item: InventoryItemID
    let quantity: Int
}

struct CraftingRecipeDefinition: Identifiable, Equatable {
    let id: String
    let output: InventoryItemID
    let outputQuantity: Int
    let ingredients: [CraftingIngredient]
    let category: CraftingCategory
    let requiredSkill: SkillKind?
    let requiredSkillLevel: Int?
    /// XP granted to `requiredSkill` when the recipe is crafted.
    let skillXP: Int

    var materialsDescription: String {
        ingredients
            .map { "\($0.quantity) \($0.item.displayName)" }
            .joined(separator: " + ")
    }

    var detailDescription: String {
        var parts = [materialsDescription]
        if let requiredSkill, let requiredSkillLevel {
            parts.append("\(requiredSkill.displayName) \(requiredSkillLevel)+")
        }
        if skillXP > 0, let requiredSkill {
            parts.append("+\(skillXP) \(requiredSkill.displayName) XP")
        }
        return parts.joined(separator: " • ")
    }
}

enum CraftingCatalog {
    static let stonePickaxe = toolRecipe("stone-pickaxe", .stonePickaxe, [
        CraftingIngredient(item: .stone, quantity: 5),
        CraftingIngredient(item: .wood, quantity: 5)
    ])

    static let copperAxe = toolRecipe("copper-axe", .copperAxe, [
        CraftingIngredient(item: .copperOre, quantity: 5),
        CraftingIngredient(item: .wood, quantity: 3)
    ], skill: .smithing, level: 1, xp: 50)

    static let copperPickaxe = toolRecipe("copper-pickaxe", .copperPickaxe, [
        CraftingIngredient(item: .copperOre, quantity: 5),
        CraftingIngredient(item: .wood, quantity: 3)
    ], skill: .smithing, level: 1, xp: 50)

    static let copperFishingRod = toolRecipe("copper-fishing-rod", .copperFishingRod, [
        CraftingIngredient(item: .copperOre, quantity: 3),
        CraftingIngredient(item: .wood, quantity: 3)
    ], skill: .smithing, level: 1, xp: 40)

    static let fishingRod = toolRecipe("fishing-rod", .fishingRod, [
        CraftingIngredient(item: .wood, quantity: 5)
    ])

    static let stoneAxe = CraftingRecipeDefinition(
        id: "stone-axe",
        output: .stoneAxe,
        outputQuantity: 1,
        ingredients: [
            CraftingIngredient(item: .stone, quantity: 5),
            CraftingIngredient(item: .wood, quantity: 5)
        ],
        category: .tools,
        requiredSkill: nil,
        requiredSkillLevel: nil,
        skillXP: 0
    )

    static let stoneDagger = CraftingRecipeDefinition(
        id: "stone-dagger",
        output: .stoneDagger,
        outputQuantity: 1,
        ingredients: [
            CraftingIngredient(item: .wood, quantity: 5),
            CraftingIngredient(item: .stone, quantity: 5)
        ],
        category: .weapons,
        requiredSkill: nil,
        requiredSkillLevel: nil,
        skillXP: 0
    )

    static let copperDagger = CraftingRecipeDefinition(
        id: "copper-dagger",
        output: .copperDagger,
        outputQuantity: 1,
        ingredients: [
            CraftingIngredient(item: .copperOre, quantity: 5),
            CraftingIngredient(item: .wood, quantity: 5)
        ],
        category: .weapons,
        requiredSkill: .smithing,
        requiredSkillLevel: 1,
        skillXP: 50
    )

    static let studdedBoots = CraftingRecipeDefinition(
        id: "studded-boots",
        output: .studdedBoots,
        outputQuantity: 1,
        ingredients: [
            CraftingIngredient(item: .leather, quantity: 2),
            CraftingIngredient(item: .bronzeBar, quantity: 1)
        ],
        category: .smithing,
        requiredSkill: .smithing,
        requiredSkillLevel: 5,
        skillXP: 50
    )

    static let hardLeatherBoots = CraftingRecipeDefinition(
        id: "hard-leather-boots",
        output: .hardLeatherBoots,
        outputQuantity: 1,
        ingredients: [
            CraftingIngredient(item: .leather, quantity: 2)
        ],
        category: .smithing,
        requiredSkill: .smithing,
        requiredSkillLevel: 1,
        skillXP: 20
    )

    static let all: [CraftingRecipeDefinition] = [
        stoneAxe,
        stonePickaxe,
        fishingRod,
        hardLeatherBoots,
        studdedBoots,
        stoneDagger,
        copperDagger
    ] + FarmingCatalog.recipes + MagicCatalog.recipes + [RunecraftingCatalog.pouchRecipe]

    /// Copper tools shown on the Forge anvil before bronze.
    static var copperForgeTools: [CraftingRecipeDefinition] {
        [copperAxe, copperPickaxe, copperFishingRod]
    }

    private static func toolRecipe(
        _ id: String,
        _ output: InventoryItemID,
        _ ingredients: [CraftingIngredient],
        skill: SkillKind? = nil,
        level: Int? = nil,
        xp: Int = 0
    ) -> CraftingRecipeDefinition {
        CraftingRecipeDefinition(
            id: id,
            output: output,
            outputQuantity: 1,
            ingredients: ingredients,
            category: .tools,
            requiredSkill: skill,
            requiredSkillLevel: level,
            skillXP: xp
        )
    }

    static func recipes(in category: CraftingCategory) -> [CraftingRecipeDefinition] {
        all.filter { $0.category == category }
    }

    static func recipe(id: String) -> CraftingRecipeDefinition? {
        all.first { $0.id == id }
    }
}
