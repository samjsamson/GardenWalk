import SwiftUI

struct GoldBalanceLabel: View {
    let amount: Int
    var iconSize: CGFloat = 18

    var body: some View {
        HStack(spacing: 4) {
            ItemIconView(item: .gold, size: iconSize)
            Text(amount.formatted())
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(ItemPalette.goldDeep)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(amount) Gold")
    }
}

/// Compact gold count and health for the top-right of each screen.
struct StatusHUD: View {
    @Environment(GameController.self) private var game
    var compact = true

    private var health: Int { game.currentHitPoints }
    private var maxHealth: Int { max(1, game.playerCombatHealth) }
    private var fraction: Double { min(1, max(0, Double(health) / Double(maxHealth))) }

    var body: some View {
        let _ = game.stateVersion
        HStack(spacing: compact ? 8 : 10) {
            healthChip
            GoldBalanceLabel(amount: game.inventory.quantity(of: .gold), iconSize: compact ? 14 : 16)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.white.opacity(0.92), in: Capsule())
        .overlay {
            Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health \(health) of \(maxHealth), \(game.inventory.quantity(of: .gold)) Gold")
    }

    private var healthChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(red: 0.72, green: 0.18, blue: 0.20))
            VStack(alignment: .leading, spacing: 2) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.10))
                        Capsule()
                            .fill(fraction > 0.35 ? GardenPalette.leaf : Color(red: 0.78, green: 0.22, blue: 0.18))
                            .frame(width: max(2, geo.size.width * fraction))
                    }
                }
                .frame(width: 36, height: 5)
                Text("\(health)/\(maxHealth)")
                    .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(GardenPalette.ink)
            }
        }
    }
}

struct StatusHUDToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StatusHUD()
            }
        }
    }
}

extension View {
    /// Adds the shared gold + health chip to the navigation bar.
    func statusHUD() -> some View {
        modifier(StatusHUDToolbarModifier())
    }
}

struct GoldGainBanner: View {
    let amount: Int

    var body: some View {
        Text("+\(amount) Gold")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(ItemPalette.goldDeep)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.white, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
            .accessibilityLabel("Gained \(amount) gold")
    }
}
