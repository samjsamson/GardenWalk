import Foundation

struct EnemyDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let health: Int
    let attack: Int
    let defense: Int
    let requiredCombatLevel: Int
    let combatXP: Int
    let isAvailable: Bool
    let guaranteedVictory: Bool
    let dropTable: [DropTableEntry]

    var difficultyLabel: String {
        "HP \(health) • ATK \(attack) • DEF \(defense)"
    }

    var notableDropsLabel: String {
        let names = Set(dropTable.map(\.item.displayName))
        return names.sorted().joined(separator: ", ")
    }
}

enum EnemyCatalog {
    static let rat = EnemyDefinition(
        id: "rat",
        name: "Rat",
        icon: "🐀",
        health: 5,
        attack: 1,
        defense: 0,
        requiredCombatLevel: 1,
        combatXP: 25,
        isAvailable: true,
        guaranteedVictory: true,
        dropTable: [
            DropTableEntry(item: .gold, chance: 1.0, minQuantity: 1, maxQuantity: 3),
            DropTableEntry(item: .wood, chance: 0.20, minQuantity: 1, maxQuantity: 2)
        ]
    )

    static let cow = EnemyDefinition(
        id: "cow",
        name: "Cow",
        icon: "🐄",
        health: 8,
        attack: 2,
        defense: 0,
        requiredCombatLevel: 3,
        combatXP: 40,
        isAvailable: true,
        guaranteedVictory: false,
        dropTable: [
            DropTableEntry(item: .gold, chance: 1.0, minQuantity: 2, maxQuantity: 4),
            DropTableEntry(item: .milk, chance: 1.0, minQuantity: 1, maxQuantity: 2),
            DropTableEntry(item: .cowMeat, chance: 0.85, minQuantity: 1, maxQuantity: 2),
            DropTableEntry(item: .leather, chance: 0.60, minQuantity: 1, maxQuantity: 1),
            DropTableEntry(item: .airRune, chance: 0.20, minQuantity: 1, maxQuantity: 1),
            DropTableEntry(item: .mindRune, chance: 0.12, minQuantity: 1, maxQuantity: 1)
        ]
    )

    static let skeleton = EnemyDefinition(
        id: "skeleton",
        name: "Skeleton",
        icon: "💀",
        health: 18,
        attack: 5,
        defense: 3,
        requiredCombatLevel: 10,
        combatXP: 120,
        isAvailable: true,
        guaranteedVictory: false,
        dropTable: [
            DropTableEntry(item: .gold, chance: 1.0, minQuantity: 3, maxQuantity: 6),
            DropTableEntry(item: .bones, chance: 1.0, minQuantity: 1, maxQuantity: 3),
            DropTableEntry(item: .mindRune, chance: 0.25, minQuantity: 1, maxQuantity: 1),
            DropTableEntry(item: .moonlitHat, chance: 0.04, minQuantity: 1, maxQuantity: 1)
        ]
    )

    static let pig = EnemyDefinition(
        id: "pig",
        name: "Pig",
        icon: "🐖",
        health: 15,
        attack: 4,
        defense: 1,
        requiredCombatLevel: 8,
        combatXP: 90,
        isAvailable: true,
        guaranteedVictory: false,
        dropTable: [
            DropTableEntry(item: .gold, chance: 1.0, minQuantity: 2, maxQuantity: 4),
            DropTableEntry(item: .porkMeat, chance: 1.0, minQuantity: 1, maxQuantity: 2)
        ]
    )

    static let goblin = EnemyDefinition(
        id: "goblin",
        name: "Goblin",
        icon: "👺",
        health: 22,
        attack: 6,
        defense: 4,
        requiredCombatLevel: 15,
        combatXP: 180,
        isAvailable: true,
        guaranteedVictory: false,
        dropTable: [
            DropTableEntry(item: .gold, chance: 1.0, minQuantity: 4, maxQuantity: 8),
            DropTableEntry(item: .wood, chance: 0.30, minQuantity: 1, maxQuantity: 3),
            DropTableEntry(item: .stone, chance: 0.35, minQuantity: 1, maxQuantity: 2),
            DropTableEntry(item: .copperOre, chance: 0.20, minQuantity: 1, maxQuantity: 1),
            DropTableEntry(item: .galeStaff, chance: 0.03, minQuantity: 1, maxQuantity: 1)
        ]
    )

    static let thief = EnemyDefinition(
        id: "thief",
        name: "Thief",
        icon: "🥷",
        health: 25,
        attack: 8,
        defense: 5,
        requiredCombatLevel: 20,
        combatXP: 250,
        isAvailable: true,
        guaranteedVictory: false,
        dropTable: [
            DropTableEntry(item: .gold, chance: 1.0, minQuantity: 8, maxQuantity: 16),
            DropTableEntry(item: .copperOre, chance: 0.35, minQuantity: 1, maxQuantity: 2),
            DropTableEntry(item: .steelDagger, chance: 0.02, minQuantity: 1, maxQuantity: 1),
            DropTableEntry(item: .duskRobe, chance: 0.02, minQuantity: 1, maxQuantity: 1)
        ]
    )

    static let all: [EnemyDefinition] = [
        rat, cow, pig, skeleton, goblin, thief
    ]

    static func enemy(id: String) -> EnemyDefinition? {
        all.first { $0.id == id }
    }
}

struct CombatBlow: Equatable, Identifiable {
    enum Target: Equatable {
        case player
        case enemy
    }

    let id: Int
    let target: Target
    let damage: Int
    let healthAfter: Int
}

struct CombatResult: Equatable {
    let enemy: EnemyDefinition
    let victory: Bool
    let playerAttackPower: Int
    let xpGained: Int
    let rounds: Int
    let remainingHealth: Int
    let drops: [InventoryItemDrop]
    let blows: [CombatBlow]

    var summaryLines: [String] {
        guard victory else {
            return ["Defeat!", "You were overpowered by a \(enemy.name)."]
        }
        var lines = [
            "Victory!",
            "You defeated a \(enemy.name).",
            "+\(xpGained) Combat XP"
        ]
        if drops.isEmpty {
            lines.append("No drops this time.")
        } else {
            lines.append(contentsOf: drops.map { "+\($0.amount) \($0.item.displayName)" })
        }
        return lines
    }
}
