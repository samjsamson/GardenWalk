import Foundation

enum EquipmentSlot: String, CaseIterable, Identifiable {
    case helmet
    case chest
    case legs
    case boots
    case weapon
    case shield
    case arrows
    case axe
    case pickaxe
    case fishingRod

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .helmet: "Helmet"
        case .chest: "Chest"
        case .legs: "Legs"
        case .boots: "Boots"
        case .weapon: "Weapon"
        case .shield: "Shield"
        case .arrows: "Ammo"
        case .axe: "Axe"
        case .pickaxe: "Pickaxe"
        case .fishingRod: "Rod"
        }
    }

    /// Empty-slot marker. Equipped items use `ItemIconView` instead.
    var emptySymbolName: String {
        switch self {
        case .helmet: "circle.fill"
        case .chest: "tshirt.fill"
        case .legs: "figure.stand"
        case .boots: "shoeprints.fill"
        case .weapon: "line.diagonal"
        case .shield: "shield.fill"
        case .arrows: "arrow.up.right"
        case .axe: "arrow.up.left"
        case .pickaxe: "hammer.fill"
        case .fishingRod: "line.diagonal"
        }
    }

    static let paperDollLeading: [EquipmentSlot] = [.helmet, .chest, .legs, .boots]
    static let paperDollTrailing: [EquipmentSlot] = [.weapon, .shield, .arrows]
    static let toolSlots: [EquipmentSlot] = [.axe, .pickaxe, .fishingRod]
}

struct EquipmentBonuses: Equatable {
    var attack: Int = 0
    var defense: Int = 0
    var ranged: Int = 0
    var armor: Int = 0
    var strength: Int = 0
    var magic: Int = 0
    /// While this item is equipped, spells do not consume this rune.
    var suppliedRune: InventoryItemID? = nil
    var requiredLevel: Int?
    var requiredSkill: SkillKind?
    var durability: Int?
    var setID: String?
    /// Extra worker resource output for `workerSkill`. `0.15` is +15%. Does not affect XP.
    var workerYieldBonus: Double = 0
    var workerSkill: SkillKind?
    /// OSRS attack interval in ticks. Lower is faster. Dagger and scimitar are 4. Sword is 5.
    var attackSpeed: Int? = nil
    var weaponKind: String? = nil
}

struct EquippableItemDefinition: Equatable {
    let item: InventoryItemID
    let slot: EquipmentSlot
    var bonuses: EquipmentBonuses = EquipmentBonuses()
}

enum EquipmentCatalog {
    static let all: [EquippableItemDefinition] = [
        EquippableItemDefinition(item: .stoneDagger, slot: .weapon, bonuses: EquipmentBonuses(attack: 3, attackSpeed: 4, weaponKind: "Dagger")),
        EquippableItemDefinition(item: .copperDagger, slot: .weapon, bonuses: EquipmentBonuses(attack: 5, attackSpeed: 4, weaponKind: "Dagger")),
        tool(.stoneAxe, slot: .axe, skill: .woodcutting, bonus: 0.05),
        tool(.copperAxe, slot: .axe, skill: .woodcutting, bonus: 0.10),
        tool(.bronzeAxe, slot: .axe, skill: .woodcutting, bonus: 0.15),
        tool(.ironAxe, slot: .axe, skill: .woodcutting, bonus: 0.20),
        tool(.steelAxe, slot: .axe, skill: .woodcutting, bonus: 0.25),
        tool(.stonePickaxe, slot: .pickaxe, skill: .mining, bonus: 0.05),
        tool(.copperPickaxe, slot: .pickaxe, skill: .mining, bonus: 0.10),
        tool(.bronzePickaxe, slot: .pickaxe, skill: .mining, bonus: 0.15),
        tool(.ironPickaxe, slot: .pickaxe, skill: .mining, bonus: 0.20),
        tool(.steelPickaxe, slot: .pickaxe, skill: .mining, bonus: 0.25),
        EquippableItemDefinition(item: .fishingRod, slot: .fishingRod)
    ] + SmithingCatalog.equipmentDefinitions() + MagicCatalog.equipmentDefinitions()

    private static func tool(
        _ item: InventoryItemID,
        slot: EquipmentSlot,
        skill: SkillKind,
        bonus: Double
    ) -> EquippableItemDefinition {
        EquippableItemDefinition(
            item: item,
            slot: slot,
            bonuses: EquipmentBonuses(workerYieldBonus: bonus, workerSkill: skill)
        )
    }

    static func definition(for item: InventoryItemID) -> EquippableItemDefinition? {
        all.first { $0.item == item }
    }

    static func slot(for item: InventoryItemID) -> EquipmentSlot? {
        definition(for: item)?.slot
    }

    static func attackPower(for item: InventoryItemID?) -> Int {
        guard let item, let definition = definition(for: item), definition.slot == .weapon else { return 1 }
        return max(1, definition.bonuses.attack)
    }

    static func combatStatsText(for item: InventoryItemID) -> String? {
        guard let bonuses = definition(for: item)?.bonuses else { return nil }
        var parts: [String] = []
        if bonuses.attack > 0 { parts.append("Attack Bonus \(bonuses.attack)") }
        if bonuses.strength > 0 { parts.append("Strength Bonus \(bonuses.strength)") }
        if bonuses.defense > 0 { parts.append("Defense Bonus \(bonuses.defense)") }
        if bonuses.magic > 0 { parts.append("Magic Bonus \(bonuses.magic)") }
        if let speed = bonuses.attackSpeed {
            parts.append("Attack Speed \(CombatDamage.attackIntervalLabel(ticks: speed))")
        }
        if let yield = workerYieldDescription(for: item) { parts.append(yield) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    static func requirementText(for item: InventoryItemID) -> String? {
        guard let bonuses = definition(for: item)?.bonuses,
              let skill = bonuses.requiredSkill,
              let level = bonuses.requiredLevel else { return nil }
        return "Requires \(skill.displayName) \(level)"
    }

    /// Bonus line for the equipped tool only. Bonuses do not stack across copies.
    static func workerYieldDescription(for item: InventoryItemID) -> String? {
        guard let definition = definition(for: item),
              let skill = definition.bonuses.workerSkill,
              definition.bonuses.workerYieldBonus > 0 else { return nil }
        let percent = Int((definition.bonuses.workerYieldBonus * 100).rounded())
        return "\(skill.displayName) Bonus +\(percent)%"
    }
}
