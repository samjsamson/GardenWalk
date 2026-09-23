import CryptoKit
import Foundation
import SwiftData

@MainActor
enum CharacterSaveStore {
    static func container(for account: LocalAccount, auth: AuthController, legacy: ModelContainer) throws -> ModelContainer {
        if auth.usesLegacyGarden(account) { return legacy }
        // Hash the identifier rather than using a username as a file path.
        let identifier = account.gameStoreID ?? "existing:\(account.username.lowercased())"
        let key = SHA256.hash(data: Data(identifier.utf8)).map { String(format: "%02x", $0) }.joined()
        let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("GardenWalkCharacters", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let schema = Schema([
            SkillProgress.self, InventoryEntry.self, WorkerPool.self,
            PlayerCombatState.self, PlayerRecord.self
        ])
        let configuration = ModelConfiguration("Character", schema: schema,
            url: directory.appendingPathComponent("\(key).store"), cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func updatePreview(for account: LocalAccount, game: GameController, context: ModelContext) {
        let equipment = Dictionary(uniqueKeysWithValues: EquipmentSlot.allCases.compactMap { slot in
            game.equippedItem(in: slot).map { (slot.rawValue, $0.rawValue) }
        })
        guard account.previewEquipment != equipment || account.previewCombatLevel != game.combatLevel
            || account.previewSkinToneRaw != game.skinTone.rawValue
            || account.previewClothingToneRaw != game.clothingTone.rawValue else { return }
        guard let data = try? JSONEncoder().encode(equipment), let json = String(data: data, encoding: .utf8) else { return }
        account.previewEquipmentJSON = json
        account.previewCombatLevel = game.combatLevel
        account.previewSkinToneRaw = game.skinTone.rawValue
        account.previewClothingToneRaw = game.clothingTone.rawValue
        // Preview failure must never replace or reset the character's game save.
        try? context.save()
    }
}
