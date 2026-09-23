import Foundation
import SwiftData

enum PlayerProgression {
    static let baseInventoryCapacity = 40
    static let backpackCapacityPerTier = 20
    static let workerRationDuration: TimeInterval = 10 * 60
    static let workerRationSpeedBonus = 0.25
    static let workerRationWorkerCount = 1
}

enum WorkerBalance {
    /// Per-worker production interval used by every resource node.
    static let productionInterval: TimeInterval = 30
    /// Total items that can wait in Worker Storage before production pauses.
    static let storageCapacity = 80
    /// Capacity after purchasing the Worker Storage Upgrade from the General Store.
    static let expandedStorageCapacity = 120
    static let baseWorkerCap = 10
    static let expandedWorkerCap = 20
    /// Starting Total Level is one level in each skill. Four more levels expand the worker cap.
    static let expandedUnlockTotalLevel = 15
}

@Model
final class PlayerRecord {
    var inventoryCapacity: Int
    var backpackTier: Int
    var workerRationEffectEnd: Date?
    var skinToneRaw: String? = nil
    var clothingToneRaw: String? = nil
    var completedTaskIDsRaw: String?
    var hasExpandedWorkerStorage: Bool = false
    var hasAssignedWorker: Bool = false
    var hasCollectedWorkerOutput: Bool = false
    var hasSoldItem: Bool = false
    var hasPurchasedNonWorkerItem: Bool = false
    var hasMinedCopper: Bool = false
    var hasMinedTin: Bool = false
    var hasSmeltedBronzeBar: Bool = false
    var hasObtainedHammer: Bool = false
    var hasOpenedAnvil: Bool = false
    var hasSmithedBronzeItem: Bool = false
    var hasEquippedBronzeGear: Bool = false
    var farmPlotsRaw: String? = nil
    var autoGatherProgress: Double = 0
    var autoGatherIndex: Int = 0
    var attackBoostEnd: Date? = nil
    var strengthBoostEnd: Date? = nil
    var defenseBoostEnd: Date? = nil
    var magicBoostEnd: Date? = nil
    var gatherBoostEnd: Date? = nil

    init(
        inventoryCapacity: Int = PlayerProgression.baseInventoryCapacity,
        backpackTier: Int = 0,
        workerRationEffectEnd: Date? = nil,
        completedTaskIDsRaw: String? = nil
    ) {
        self.inventoryCapacity = inventoryCapacity
        self.backpackTier = backpackTier
        self.workerRationEffectEnd = workerRationEffectEnd
        self.completedTaskIDsRaw = completedTaskIDsRaw
    }

    var completedTaskIDs: Set<String> {
        get {
            Set((completedTaskIDsRaw ?? "").split(separator: ",").map(String.init).filter { !$0.isEmpty })
        }
        set {
            completedTaskIDsRaw = newValue.sorted().joined(separator: ",")
        }
    }
}
