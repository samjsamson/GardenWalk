import Foundation

struct DropTableEntry: Equatable {
    let item: InventoryItemID
    let chance: Double
    let minQuantity: Int
    let maxQuantity: Int
}

enum DropTableService {
    static func rollDrops<G: RandomNumberGenerator>(
        from table: [DropTableEntry],
        using generator: inout G
    ) -> [InventoryItemDrop] {
        var merged: [InventoryItemID: Int] = [:]

        for entry in table {
            guard Double.random(in: 0..<1, using: &generator) <= entry.chance else { continue }
            let low = min(entry.minQuantity, entry.maxQuantity)
            let high = max(entry.minQuantity, entry.maxQuantity)
            let quantity = Int.random(in: low...high, using: &generator)
            guard quantity > 0 else { continue }
            merged[entry.item, default: 0] += quantity
        }

        return merged.map { InventoryItemDrop(item: $0.key, amount: $0.value) }
            .sorted { $0.item.displayName < $1.item.displayName }
    }
}
