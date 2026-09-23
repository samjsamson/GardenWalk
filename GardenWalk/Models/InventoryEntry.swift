import Foundation
import SwiftData

@Model
final class InventoryEntry {
    @Attribute(.unique) var itemID: String
    var quantity: Int

    init(itemID: InventoryItemID, quantity: Int = 0) {
        self.itemID = itemID.rawValue
        self.quantity = quantity
    }

    var item: InventoryItemID? {
        InventoryItemID(rawValue: itemID)
    }
}
