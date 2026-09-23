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
    /// Encoded `resourceID:count` pairs. Empty string means migrated with no assignments.
    var resourceAssignmentsRaw: String? = nil

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

    /// Per-resource worker counts. Migrates legacy spot totals on first access.
    private var resourceAssignments: [String: Int] {
        get {
            migrateResourceAssignmentsIfNeeded()
            guard let resourceAssignmentsRaw, !resourceAssignmentsRaw.isEmpty else { return [:] }
            var map: [String: Int] = [:]
            for part in resourceAssignmentsRaw.split(separator: "|") {
                let pieces = part.split(separator: ":", maxSplits: 1).map(String.init)
                guard pieces.count == 2, let count = Int(pieces[1]), count > 0 else { continue }
                map[pieces[0], default: 0] += count
            }
            return map
        }
        set {
            let encoded = newValue
                .filter { $0.value > 0 }
                .map { "\($0.key):\($0.value)" }
                .sorted()
                .joined(separator: "|")
            resourceAssignmentsRaw = encoded
            syncSpotTotals(from: newValue)
        }
    }

    private func migrateResourceAssignmentsIfNeeded() {
        guard resourceAssignmentsRaw == nil else { return }
        var map: [String: Int] = [:]
        for spot in ResourceSpotKind.allCases where spot != .gardenSpot {
            let count = legacyAssignedCount(for: spot)
            guard count > 0 else { continue }
            if let focused = selectedResource(for: spot) {
                map[focused.id, default: 0] += count
            } else if let fallback = ResourceCatalog.activeResource(for: spot) {
                map[fallback.id, default: 0] += count
            }
        }
        let encoded = map
            .filter { $0.value > 0 }
            .map { "\($0.key):\($0.value)" }
            .sorted()
            .joined(separator: "|")
        resourceAssignmentsRaw = encoded
        syncSpotTotals(from: map)
    }

    private func legacyAssignedCount(for spot: ResourceSpotKind) -> Int {
        switch spot {
        case .miningSpot: miningAssigned
        case .treePlot: treeAssigned
        case .gardenSpot: gardenAssigned
        case .fishingPond: fishingAssigned
        case .runeMine: runeMineAssigned
        }
    }

    private func syncSpotTotals(from map: [String: Int]) {
        var totals: [ResourceSpotKind: Int] = [:]
        for (id, count) in map {
            guard let resource = ResourceCatalog.definition(id: id) else { continue }
            totals[resource.spot, default: 0] += count
        }
        miningAssigned = totals[.miningSpot, default: 0]
        treeAssigned = totals[.treePlot, default: 0]
        gardenAssigned = 0
        fishingAssigned = totals[.fishingPond, default: 0]
        runeMineAssigned = totals[.runeMine, default: 0]
    }

    var unassignedCount: Int {
        max(0, ownedCount - totalAssignedWorkers)
    }

    var totalAssignedWorkers: Int {
        resourceAssignments.values.reduce(0, +)
    }

    func assignedCount(forResourceID id: String) -> Int {
        resourceAssignments[id, default: 0]
    }

    func setAssignedCount(_ count: Int, forResourceID id: String) {
        var map = resourceAssignments
        let clamped = max(0, count)
        if clamped == 0 {
            map.removeValue(forKey: id)
        } else {
            map[id] = clamped
        }
        // Cap total to ownedCount by trimming this resource if needed.
        let others = map.filter { $0.key != id }.values.reduce(0, +)
        let allowed = max(0, ownedCount - others)
        if clamped > allowed {
            if allowed == 0 {
                map.removeValue(forKey: id)
            } else {
                map[id] = allowed
            }
        }
        resourceAssignments = map
    }

    func assignedCount(for spot: ResourceSpotKind) -> Int {
        ResourceCatalog.resources(for: spot).reduce(0) { $0 + assignedCount(forResourceID: $1.id) }
    }

    func setAssignedCount(_ count: Int, for spot: ResourceSpotKind) {
        let resources = ResourceCatalog.resources(for: spot).filter(\.isPlayable)
        guard let target = selectedResource(for: spot) ?? resources.first else {
            switch spot {
            case .miningSpot: miningAssigned = min(max(0, count), ownedCount)
            case .treePlot: treeAssigned = min(max(0, count), ownedCount)
            case .gardenSpot: gardenAssigned = 0
            case .fishingPond: fishingAssigned = min(max(0, count), ownedCount)
            case .runeMine: runeMineAssigned = min(max(0, count), ownedCount)
            }
            return
        }
        // Clear other resources on this spot, then set the focused one.
        var map = resourceAssignments
        for resource in resources where resource.id != target.id {
            map.removeValue(forKey: resource.id)
        }
        resourceAssignments = map
        setAssignedCount(count, forResourceID: target.id)
    }

    /// Drops stored item ids that are no longer in the catalog, including removed seeds.
    func sanitizeStorage() {
        let current = storedQuantities
        storedQuantities = current
    }
}
