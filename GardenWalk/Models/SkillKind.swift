import Foundation

enum SkillKind: String, CaseIterable, Codable, Identifiable {
    case mining
    case woodcutting
    case fishing
    case farming
    case smithing
    case combat
    case attack
    case strength
    case defense
    case magic
    case runecrafting

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mining: "Mining"
        case .woodcutting: "Woodcutting"
        case .fishing: "Fishing"
        case .farming: "Farming"
        case .smithing: "Smithing"
        case .combat: "Combat"
        case .attack: "Attack"
        case .strength: "Strength"
        case .defense: "Defense"
        case .magic: "Magic"
        case .runecrafting: "Runecrafting"
        }
    }

    var emoji: String {
        switch self {
        case .mining: "⛏️"
        case .woodcutting: "🪓"
        case .fishing: "🎣"
        case .farming: "🌱"
        case .smithing: "⚒️"
        case .combat: "⚔️"
        case .attack: "🗡️"
        case .strength: "💪"
        case .defense: "🛡️"
        case .magic: "✨"
        case .runecrafting: "💠"
        }
    }
}
