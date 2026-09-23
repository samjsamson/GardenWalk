import SwiftUI

struct AppTabView: View {
    @Environment(GameController.self) private var game
    @Environment(AuthController.self) private var auth

    var body: some View {
        let _ = game.stateVersion
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            NavigationStack {
                CombatView()
            }
            .tabItem {
                Label("Combat", systemImage: "shield.lefthalf.filled")
            }

            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "bag.fill")
                }

            ResourcesView()
                .tabItem {
                    Label("Resources", systemImage: "leaf.fill")
                }

            ForgeHubView()
                .tabItem {
                    Label("Forge", systemImage: "flame.fill")
                }

            ProfileView()
                .tabItem {
                    Label("User", systemImage: "person.crop.circle")
                }
        }
        .tint(GardenPalette.moss)
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                if let amount = game.goldNotice {
                    GoldGainBanner(amount: amount)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if let message = game.statusNotice {
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GardenPalette.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white, in: Capsule())
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 8)
        }
        .animation(.easeInOut(duration: 0.2), value: game.goldNotice)
        .animation(.easeInOut(duration: 0.2), value: game.statusNotice)
    }
}
