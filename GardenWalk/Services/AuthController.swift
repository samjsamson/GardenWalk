import CryptoKit
import Foundation
import SwiftData

protocol AccountStore {
    func allAccounts() -> [LocalAccount]
    func insert(_ account: LocalAccount) throws
}

struct LocalAccountStore: AccountStore {
    let modelContext: ModelContext

    func allAccounts() -> [LocalAccount] {
        (try? modelContext.fetch(FetchDescriptor<LocalAccount>())) ?? []
    }

    func insert(_ account: LocalAccount) throws {
        modelContext.insert(account)
        do {
            try modelContext.save()
        } catch {
            modelContext.delete(account)
            throw error
        }
    }
}

enum PasswordHasher {
    static func makeSalt() -> String {
        UUID().uuidString
    }

    static func hash(password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + password).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
@Observable
final class AuthController {
    private let store: AccountStore
    private let defaults: UserDefaults
    private let sessionKey = "gardenwalk.session.username"

    private(set) var currentUsername: String?

    init(store: AccountStore, defaults: UserDefaults = .standard) {
        self.store = store
        self.defaults = defaults
    }

    var isSignedIn: Bool {
        currentUsername != nil
    }

    var accounts: [LocalAccount] {
        store.allAccounts().sorted {
            if $0.createdAt == $1.createdAt { return $0.username < $1.username }
            return $0.createdAt < $1.createdAt
        }
    }

    var currentAccount: LocalAccount? {
        currentUsername.flatMap { account(named: $0) }
    }

    /// The oldest pre-existing account keeps the original shared garden.
    func usesLegacyGarden(_ account: LocalAccount) -> Bool {
        account.gameStoreID == nil && accounts.first(where: { $0.gameStoreID == nil })?.username == account.username
    }

    var hasAccount: Bool {
        !store.allAccounts().isEmpty
    }

    func restoreSession() {
        guard let saved = defaults.string(forKey: sessionKey) else { return }
        if store.allAccounts().contains(where: { $0.username.compare(saved, options: .caseInsensitive) == .orderedSame }) {
            currentUsername = saved
        } else {
            defaults.removeObject(forKey: sessionKey)
        }
    }

    @discardableResult
    func register(username: String, password: String) -> String? {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if let message = validate(username: name, password: password) {
            return message
        }
        if account(named: name) != nil {
            return "That username is already taken."
        }

        let salt = PasswordHasher.makeSalt()
        let account = LocalAccount(
            username: name,
            passwordHash: PasswordHasher.hash(password: password, salt: salt),
            passwordSalt: salt
        )
        do {
            try store.insert(account)
        } catch {
            return "Your account could not be saved. Please try again."
        }
        signIn(name)
        return nil
    }

    @discardableResult
    func login(username: String, password: String) -> String? {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let account = account(named: name) else {
            return "No account exists with that username."
        }
        let hash = PasswordHasher.hash(password: password, salt: account.passwordSalt)
        guard hash == account.passwordHash else {
            return "Incorrect password."
        }
        signIn(account.username)
        return nil
    }

    func signOut() {
        currentUsername = nil
        defaults.removeObject(forKey: sessionKey)
    }

    private func signIn(_ username: String) {
        currentUsername = username
        defaults.set(username, forKey: sessionKey)
    }

    private func account(named username: String) -> LocalAccount? {
        store.allAccounts().first { $0.username.compare(username, options: .caseInsensitive) == .orderedSame }
    }

    private func validate(username: String, password: String) -> String? {
        if username.count < 3 {
            return "Username must be at least 3 characters."
        }
        if username.count > 16 {
            return "Username must be 16 characters or fewer."
        }
        if password.count < 4 {
            return "Password must be at least 4 characters."
        }
        return nil
    }
}
