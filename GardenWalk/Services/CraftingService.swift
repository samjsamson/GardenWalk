import Foundation

@MainActor
struct CraftingService {
    func canCraft(
        _ recipe: CraftingRecipeDefinition,
        inventory: InventoryService,
        skills: [SkillKind: SkillProgress]
    ) -> Bool {
        for ingredient in recipe.ingredients {
            guard inventory.quantity(of: ingredient.item) >= ingredient.quantity else {
                return false
            }
        }

        if let requiredSkill = recipe.requiredSkill,
           let requiredLevel = recipe.requiredSkillLevel {
            let totalXP = skills[requiredSkill]?.totalXP ?? 0
            guard SkillProgressService.level(forTotalXP: totalXP) >= requiredLevel else {
                return false
            }
        }

        return true
    }

    @discardableResult
    func craft(
        _ recipe: CraftingRecipeDefinition,
        inventory: InventoryService,
        skills: [SkillKind: SkillProgress]
    ) -> Bool {
        guard canCraft(recipe, inventory: inventory, skills: skills) else { return false }

        for ingredient in recipe.ingredients {
            guard inventory.remove(ingredient.item, amount: ingredient.quantity) else {
                return false
            }
        }

        inventory.add(recipe.output, amount: recipe.outputQuantity)
        return true
    }
}
