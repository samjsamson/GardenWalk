import SwiftData
import SwiftUI

@main
struct GardenWalkApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: [
                SkillProgress.self, InventoryEntry.self, WorkerPool.self,
                PlayerCombatState.self, PlayerRecord.self, LocalAccount.self
            ])
    }
}

private struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var game: GameController?
    @State private var auth: AuthController?
    @State private var characterContainer: ModelContainer?
    @State private var activeAccount: LocalAccount?
    @State private var openingError: String?

    var body: some View {
        Group {
            if let auth {
                if let game, auth.isSignedIn {
                    AppTabView()
                        .environment(game)
                        .environment(auth)
                        .onChange(of: game.stateVersion) { _, _ in savePreview() }
                } else {
                    AuthGateView(onEnter: enterGarden)
                        .environment(auth)
                }
            } else {
                ZStack {
                    GardenPalette.cream.ignoresSafeArea()
                    ProgressView("Preparing your little escape…")
                }
            }
        }
        .task {
            guard auth == nil else { return }
            let session = AuthController(store: LocalAccountStore(modelContext: modelContext))
            session.restoreSession()
            auth = session
            // Always show the welcome screen, even with a remembered login.
            if let legacyAccount = session.accounts.first(where: { session.usesLegacyGarden($0) }),
               legacyAccount.previewCombatLevel == nil {
                let previewGame = GameController(modelContext: modelContext)
                CharacterSaveStore.updatePreview(for: legacyAccount, game: previewGame, context: modelContext)
            }
        }
        .onChange(of: auth?.currentUsername) { _, name in
            if name == nil { leaveGarden() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { savePreview() }
        }
        .preferredColorScheme(.light)
        .background { WelcomeMusicHost() }
        .alert("We couldn’t open your garden", isPresented: Binding(
            get: { openingError != nil }, set: { if !$0 { openingError = nil } }
        )) {
            Button("OK") { openingError = nil }
        } message: {
            Text(openingError ?? "Please try again.")
        }
    }

    private func enterGarden() {
        guard let auth, let account = auth.currentAccount else { return }
        do {
            let container = try CharacterSaveStore.container(for: account, auth: auth, legacy: modelContext.container)
            let controller = GameController(modelContext: container.mainContext)
            characterContainer = container
            activeAccount = account
            game = controller
            controller.bootstrap()
            savePreview()
        } catch {
            openingError = "Your save has been kept safe. Please close and reopen the app, then try again."
        }
    }

    private func savePreview() {
        guard let game, let activeAccount else { return }
        CharacterSaveStore.updatePreview(for: activeAccount, game: game, context: modelContext)
    }

    private func leaveGarden() {
        savePreview()
        game?.stop()
        game = nil
        activeAccount = nil
        characterContainer = nil
    }
}
