import Foundation
import SwiftData

@Model
final class LocalAccount {
    var username: String
    var passwordHash: String
    var passwordSalt: String
    var createdAt: Date
    // Nil identifies accounts created before separate character saves existed.
    var gameStoreID: String? = nil
    var previewEquipmentJSON: String? = nil
    var previewCombatLevel: Int? = nil
    var previewSkinToneRaw: String? = nil
    var previewClothingToneRaw: String? = nil

    var previewEquipment: [String: String] {
        guard let data = previewEquipmentJSON?.data(using: .utf8),
              let equipment = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return equipment
    }

    func previewItem(in slot: EquipmentSlot) -> InventoryItemID? {
        previewEquipment[slot.rawValue].flatMap(InventoryItemID.init(rawValue:))
    }

    init(username: String, passwordHash: String, passwordSalt: String, createdAt: Date = .now) {
        self.username = username
        self.passwordHash = passwordHash
        self.passwordSalt = passwordSalt
        self.createdAt = createdAt
        self.gameStoreID = UUID().uuidString
    }
}
