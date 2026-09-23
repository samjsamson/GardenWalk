import SwiftUI

private enum AuthMode: String, Identifiable {
    case login, create
    var id: String { rawValue }
    var title: String { self == .login ? "Welcome back" : "A new beginning" }
    var actionTitle: String { self == .login ? "Login" : "Create Account" }
}

struct AuthGateView: View {
    @Environment(AuthController.self) private var auth
    @AppStorage("gardenwalk.welcome.music") private var musicEnabled = true
    @State private var mode: AuthMode?
    @State private var selectedUsername = ""
    let onEnter: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [GardenPalette.skyTop.opacity(0.5), GardenPalette.cream, GardenPalette.skyBottom],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Label("A little adventure, at your pace", systemImage: "leaf")
                            .font(.caption)
                            .foregroundStyle(GardenPalette.moss)
                        Spacer()
                        Button {
                            musicEnabled.toggle()
                        } label: {
                            Image(systemName: musicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.7), in: Circle())
                        }
                        .tint(GardenPalette.moss)
                        .accessibilityLabel(musicEnabled ? "Mute music" : "Play music")
                    }

                    WelcomeGardenScene(account: auth.currentAccount)
                        .frame(height: 210)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("GardenWalk")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(GardenPalette.moss)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        Text("Settle in. Your little world is waiting.")
                            .font(.subheadline)
                            .foregroundStyle(GardenPalette.bark.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        if let username = auth.currentUsername {
                            Button(action: onEnter) {
                                Label("Continue as \(username)", systemImage: "arrow.right")
                                    .frame(maxWidth: .infinity, minHeight: 32)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(GardenPalette.moss)
                        }
                        HStack(spacing: 12) {
                            Button { selectedUsername = ""; mode = .login } label: {
                                Text("Login").frame(maxWidth: .infinity, minHeight: 32)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(GardenPalette.moss)
                            Button { selectedUsername = ""; mode = .create } label: {
                                Text("Create Account").frame(maxWidth: .infinity, minHeight: 32)
                            }
                            .buttonStyle(.bordered)
                            .tint(GardenPalette.moss)
                        }
                    }
                    .font(.subheadline.weight(.semibold))

                    Text("Grow a garden. Meet a friend. Find your next adventure.")
                        .font(.caption)
                        .foregroundStyle(GardenPalette.inkMuted)
                        .multilineTextAlignment(.center)
                    Text("Your account and progress are saved on this device.")
                        .font(.caption2)
                        .foregroundStyle(GardenPalette.inkMuted)
                }
                .frame(maxWidth: 520)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(item: $mode) { mode in
            AuthenticationForm(mode: mode, initialUsername: selectedUsername, onSuccess: {
                self.mode = nil
                onEnter()
            })
            .environment(auth)
        }
    }
}

private struct CharacterPortrait: View {
    let account: LocalAccount?
    var body: some View {
        PlayerSilhouette(
            helmet: account?.previewItem(in: .helmet), chest: account?.previewItem(in: .chest),
            legs: account?.previewItem(in: .legs), boots: account?.previewItem(in: .boots),
            weapon: account?.previewItem(in: .weapon), shield: account?.previewItem(in: .shield),
            skinTone: CharacterSkinTone(rawValue: account?.previewSkinToneRaw ?? "") ?? .warm,
            clothingTone: CharacterClothingTone(rawValue: account?.previewClothingToneRaw ?? "") ?? .forest
        )
    }
}

private struct WelcomeGardenScene: View {
    let account: LocalAccount?
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color(red: 1, green: 0.88, blue: 0.57).opacity(0.8))
                    .frame(width: 66, height: 66)
                    .offset(x: geometry.size.width * 0.27, y: -60)
                Ellipse()
                    .fill(GardenPalette.leaf.opacity(0.2))
                    .frame(width: geometry.size.width * 1.1, height: 100)
                    .offset(x: -30, y: 75)
                Ellipse()
                    .fill(GardenPalette.moss.opacity(0.12))
                    .frame(width: geometry.size.width, height: 90)
                    .offset(x: 70, y: 95)
                Image(systemName: "tree.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(GardenPalette.moss.opacity(0.75))
                    .offset(x: -geometry.size.width * 0.3, y: 22)
                Image(systemName: "tree.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(GardenPalette.leaf)
                    .offset(x: geometry.size.width * 0.3, y: 50)
                CharacterPortrait(account: account)
                    .offset(y: 25)
                HStack(spacing: 42) {
                    ForEach(0..<4) { _ in
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(GardenPalette.leaf)
                            .rotationEffect(.degrees(-25))
                    }
                }
                .offset(y: 93)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

private struct AuthenticationForm: View {
    @Environment(AuthController.self) private var auth
    @Environment(\.dismiss) private var dismiss
    let mode: AuthMode
    let onSuccess: () -> Void
    @State private var username: String
    @State private var password = ""
    @State private var message: String?
    @FocusState private var focusedField: Field?
    private enum Field { case username, password }

    init(mode: AuthMode, initialUsername: String, onSuccess: @escaping () -> Void) {
        self.mode = mode
        self.onSuccess = onSuccess
        _username = State(initialValue: initialUsername)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(mode.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(GardenPalette.moss)
                    Text(mode == .login ? "Your garden is right where you left it." : "Create your account and make yourself at home.")
                        .foregroundStyle(GardenPalette.inkMuted)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username").font(.caption.weight(.semibold))
                        TextField("Username", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .username)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                        Divider()
                        Text("Password").font(.caption.weight(.semibold))
                        SecureField("Password", text: $password)
                            .textContentType(mode == .create ? .newPassword : .password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit(submit)
                    }
                    .foregroundStyle(GardenPalette.ink)
                    .padding(18)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    if mode == .create {
                        Text("Username: 3–16 characters. Password: at least 4 characters.")
                            .font(.caption)
                            .foregroundStyle(GardenPalette.inkMuted)
                    }
                    if let message {
                        Text(message).font(.subheadline).foregroundStyle(.red)
                            .accessibilityLabel("Sign-in error: \(message)")
                    }
                    Button(action: submit) {
                        Text(mode.actionTitle).frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GardenPalette.moss)
                    .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                }
                .padding(24)
            }
            .background(GardenPalette.cream.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } }
            }
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(GardenPalette.moss)
        }
    }

    private func submit() {
        let error = mode == .login ? auth.login(username: username, password: password)
            : auth.register(username: username, password: password)
        message = error
        if error == nil { password = ""; onSuccess() }
    }
}
