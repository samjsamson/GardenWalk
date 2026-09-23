import Foundation

enum WeaponCatalog {
    static func attackPower(for weapon: InventoryItemID?) -> Int {
        EquipmentCatalog.attackPower(for: weapon)
    }

    static func isEquippableWeapon(_ item: InventoryItemID) -> Bool {
        EquipmentCatalog.slot(for: item) == .weapon
    }
}
