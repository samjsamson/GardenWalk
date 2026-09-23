import SwiftUI

enum GardenPalette {
    static let moss = Color(red: 0.18, green: 0.45, blue: 0.28)
    static let leaf = Color(red: 0.32, green: 0.62, blue: 0.35)
    static let soil = Color(red: 0.42, green: 0.28, blue: 0.16)
    static let skyTop = Color(red: 0.62, green: 0.84, blue: 0.95)
    static let skyBottom = Color(red: 0.85, green: 0.93, blue: 0.78)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let bark = Color(red: 0.23, green: 0.18, blue: 0.14)
    /// Main text. Dark gray so it stays readable on the cream and white surfaces.
    static let ink = Color(red: 0.22, green: 0.20, blue: 0.18)
    /// Supporting text. Still dark enough to read on cream and white.
    static let inkMuted = Color(red: 0.34, green: 0.31, blue: 0.27)
}
