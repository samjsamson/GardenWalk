import Foundation
import SwiftData

@Model
final class PlayerCombatState {
    var equippedWeaponRaw: String?
    var equippedHelmetRaw: String?
    var equippedChestRaw: String?
    var equippedLegsRaw: String?
    var equippedBootsRaw: String?
    var equippedShieldRaw: String?
    var equippedArrowsRaw: String?
    var equippedAxeRaw: String? = nil
    var equippedPickaxeRaw: String? = nil
    var equippedFishingRodRaw: String? = nil
    var combatCooldownEndTimestamp: Date?
    var combatStyleRaw: String? = nil
    var selectedSpellRaw: String? = nil
    /// Nil means full health, so older saves start unhurt.
    var currentHealth: Int? = nil

    init(
        equippedWeaponRaw: String? = nil,
        equippedHelmetRaw: String? = nil,
        equippedChestRaw: String? = nil,
        equippedLegsRaw: String? = nil,
        equippedBootsRaw: String? = nil,
        equippedShieldRaw: String? = nil,
        equippedArrowsRaw: String? = nil,
        equippedAxeRaw: String? = nil,
        equippedPickaxeRaw: String? = nil,
        equippedFishingRodRaw: String? = nil,
        combatCooldownEndTimestamp: Date? = nil
    ) {
        self.equippedWeaponRaw = equippedWeaponRaw
        self.equippedHelmetRaw = equippedHelmetRaw
        self.equippedChestRaw = equippedChestRaw
        self.equippedLegsRaw = equippedLegsRaw
        self.equippedBootsRaw = equippedBootsRaw
        self.equippedShieldRaw = equippedShieldRaw
        self.equippedArrowsRaw = equippedArrowsRaw
        self.equippedAxeRaw = equippedAxeRaw
        self.equippedPickaxeRaw = equippedPickaxeRaw
        self.equippedFishingRodRaw = equippedFishingRodRaw
        self.combatCooldownEndTimestamp = combatCooldownEndTimestamp
    }

    func equippedItem(in slot: EquipmentSlot) -> InventoryItemID? {
        let raw: String?
        switch slot {
        case .helmet: raw = equippedHelmetRaw
        case .chest: raw = equippedChestRaw
        case .legs: raw = equippedLegsRaw
        case .boots: raw = equippedBootsRaw
        case .weapon: raw = equippedWeaponRaw
        case .shield: raw = equippedShieldRaw
        case .arrows: raw = equippedArrowsRaw
        case .axe: raw = equippedAxeRaw
        case .pickaxe: raw = equippedPickaxeRaw
        case .fishingRod: raw = equippedFishingRodRaw
        }
        guard let raw else { return nil }
        return InventoryItemID(rawValue: raw)
    }

    func setEquippedItem(_ item: InventoryItemID?, in slot: EquipmentSlot) {
        let raw = item?.rawValue
        switch slot {
        case .helmet: equippedHelmetRaw = raw
        case .chest: equippedChestRaw = raw
        case .legs: equippedLegsRaw = raw
        case .boots: equippedBootsRaw = raw
        case .weapon: equippedWeaponRaw = raw
        case .shield: equippedShieldRaw = raw
        case .arrows: equippedArrowsRaw = raw
        case .axe: equippedAxeRaw = raw
        case .pickaxe: equippedPickaxeRaw = raw
        case .fishingRod: equippedFishingRodRaw = raw
        }
    }

    var equippedWeapon: InventoryItemID? {
        get {
            guard let equippedWeaponRaw else { return nil }
            return InventoryItemID(rawValue: equippedWeaponRaw)
        }
        set {
            equippedWeaponRaw = newValue?.rawValue
        }
    }
}
