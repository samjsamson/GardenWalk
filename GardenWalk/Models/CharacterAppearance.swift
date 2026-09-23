import SwiftUI

enum CharacterSkinTone: String, CaseIterable, Identifiable {
    case porcelain, sand, warm, bronze, brown, deep
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .porcelain: Color(red: 0.98, green: 0.83, blue: 0.73)
        case .sand: Color(red: 0.89, green: 0.70, blue: 0.52)
        case .warm: Color(red: 0.77, green: 0.53, blue: 0.36)
        case .bronze: Color(red: 0.65, green: 0.40, blue: 0.25)
        case .brown: Color(red: 0.46, green: 0.28, blue: 0.19)
        case .deep: Color(red: 0.29, green: 0.17, blue: 0.13)
        }
    }
}

enum CharacterClothingTone: String, CaseIterable, Identifiable {
    case forest, ocean, plum, rust, gold, midnight
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .forest: GardenPalette.moss
        case .ocean: Color(red: 0.18, green: 0.43, blue: 0.61)
        case .plum: Color(red: 0.48, green: 0.29, blue: 0.55)
        case .rust: Color(red: 0.66, green: 0.29, blue: 0.22)
        case .gold: Color(red: 0.74, green: 0.55, blue: 0.19)
        case .midnight: Color(red: 0.22, green: 0.25, blue: 0.34)
        }
    }
}
