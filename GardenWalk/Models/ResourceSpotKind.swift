import Foundation

enum ResourceSpotKind: String, CaseIterable, Codable, Identifiable {
    case miningSpot
    case treePlot
    case fishingPond
    case gardenSpot
    case runeMine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .miningSpot: "Mining"
        case .treePlot: "Woodcutting"
        case .fishingPond: "Fishing"
        case .gardenSpot: "Farming"
        case .runeMine: "Rune Mine"
        }
    }

    var symbolName: String {
        switch self {
        case .miningSpot: "hammer.fill"
        case .treePlot: "tree.fill"
        case .fishingPond: "fish.fill"
        case .gardenSpot: "leaf.fill"
        case .runeMine: "diamond.fill"
        }
    }
}
