import SwiftUI

struct ProfileView: View {
    @Environment(GameController.self) private var game
    @Environment(AuthController.self) private var auth

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        let _ = game.stateVersion
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    EquipmentBoard()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skills")
                            .font(.headline)
                        Text("Total Level \(game.totalLevel)")
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(GardenPalette.moss)
                        Text("The sum of every skill level.")
                            .font(.caption2)
                            .foregroundStyle(GardenPalette.inkMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(SkillKind.allCases) { skill in
                            SkillStatTile(skill: skill, progress: game.progress(for: skill))
                        }
                    }
                }
                .padding()
            }
            .background(GardenPalette.cream.ignoresSafeArea())
            .navigationTitle(auth.currentUsername ?? "Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        StatusHUD()
                        Button("Sign Out") {
                            auth.signOut()
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
            }
        }
    }
}

struct SkillStatTile: View {
    let skill: SkillKind
    let progress: SkillLevelProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(skill.emoji)
                .font(.body)
            Text(skill.displayName)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Lv \(progress.level)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(GardenPalette.moss)
            if progress.isMaxLevel {
                Text("Max")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GardenPalette.leaf)
            } else {
                SkillXPBar(fraction: progress.progressFraction)
                Text("\(progress.xpIntoLevel.formatted()) / \(progress.xpForNextLevel.formatted())")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(GardenPalette.inkMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct SkillXPBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.15))
                Capsule()
                    .fill(GardenPalette.moss)
                    .frame(width: max(4, geometry.size.width * fraction))
            }
        }
        .frame(height: 4)
    }
}
