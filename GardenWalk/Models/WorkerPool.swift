import Foundation
import SwiftData

@Model
final class WorkerPool {
    var ownedCount: Int
    var miningAssigned: Int
    var treeAssigned: Int
    var gardenAssigned: Int
    var fishingAssigned: Int = 0
    var runeMineAssigned: Int = 0
    /// Encoded `itemID:quantity` pairs separated by `|`.
    var storageRaw: String? = nil
    var miningResourceID: String? = nil
    var treeResourceID: String? = nil
    var gardenResourceID: String? = nil
    var fishingResourceID: String? = nil
    var runeMineResourceID: String? = nil

    func selectedResource(for spot: ResourceSpotKind) -> ResourceDefinition? {
        let id: String?
        switch spot {
        case .miningSpot: id = miningResourceID
        case .treePlot: id = treeResourceID
        case .gardenSpot: id = gardenResourceID
        case .fishingPond: id = fishingResourceID
        case .runeMine: id = runeMineResourceID
        }
        if let id, let resource = ResourceCatalog.definition(id: id),
           resource.spot == spot, resource.isPlayable {
            return resource
        }
        return ResourceCatalog.activeResource(for: spot)
    }

    func selectResource(_ resource: ResourceDefinition) {
        switch resource.spot {
        case .miningSpot: miningResourceID = resource.id
        case .treePlot: treeResourceID = resource.id
        case .gardenSpot: gardenResourceID = resource.id
        case .fishingPond: fishingResourceID = resource.id
        case .runeMine: runeMineResourceID = resource.id
        }
    }

    init(
        ownedCount: Int = 0,
        miningAssigned: Int = 0,
        treeAssigned: Int = 0,
        gardenAssigned: Int = 0,
        storageRaw: String? = nil
    ) {
        self.ownedCount = ownedCount
        self.miningAssigned = miningAssigned
        self.treeAssigned = treeAssigned
        self.gardenAssigned = gardenAssigned
        self.storageRaw = storageRaw
    }

    var storedItemCount: Int {
        storedQuantities.values.reduce(0, +)
    }

    var storedStacks: [(InventoryItemID, Int)] {
        InventoryItemID.inventoryDisplayOrder.compactMap { item in
            guard let amount = storedQuantities[item], amount > 0 else { return nil }
            return (item, amount)
        }
    }

    func addStored(_ item: InventoryItemID, amount: Int) {
        guard amount > 0 else { return }
        var quantities = storedQuantities
        quantities[item, default: 0] += amount
        storedQuantities = quantities
    }

    func clearStorage() {
        storageRaw = nil
    }

    private var storedQuantities: [InventoryItemID: Int] {
        get {
            guard let storageRaw, !storageRaw.isEmpty else { return [:] }
            var quantities: [InventoryItemID: Int] = [:]
            for part in storageRaw.split(separator: "|") {
                let pieces = part.split(separator: ":", maxSplits: 1).map(String.init)
                guard pieces.count == 2,
                      let item = InventoryItemID(rawValue: pieces[0]),
                      let amount = Int(pieces[1]),
                      amount > 0 else { continue }
                quantities[item, default: 0] += amount
            }
            return quantities
        }
        set {
            let encoded = newValue
                .filter { $0.value > 0 }
                .map { "\($0.key.rawValue):\($0.value)" }
                .sorted()
                .joined(separator: "|")
            storageRaw = encoded.isEmpty ? nil : encoded
        }
    }

    var unassignedCount: Int {
        max(0, ownedCount - miningAssigned - treeAssigned - gardenAssigned - fishingAssigned - runeMineAssigned)
    }

    func assignedCount(for spot: ResourceSpotKind) -> Int {
        switch spot {
        case .miningSpot: miningAssigned
        case .treePlot: treeAssigned
        case .gardenSpot: gardenAssigned
        case .fishingPond: fishingAssigned
        case .runeMine: runeMineAssigned
        }
    }

    func setAssignedCount(_ count: Int, for spot: ResourceSpotKind) {
        let clamped = min(max(0, count), ownedCount)
        switch spot {
        case .miningSpot: miningAssigned = clamped
        case .treePlot: treeAssigned = clamped
        case .gardenSpot: gardenAssigned = clamped
        case .fishingPond: fishingAssigned = clamped
        case .runeMine: runeMineAssigned = clamped
        }
    }

    /// Drops stored item ids that are no longer in the catalog, including removed seeds.
    func sanitizeStorage() {
        let current = storedQuantities
        storedQuantities = current
    }
}
