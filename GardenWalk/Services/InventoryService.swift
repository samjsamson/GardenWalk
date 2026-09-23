import Foundation
import SwiftData

@MainActor
final class InventoryService {
    private let modelContext: ModelContext
    private var entries: [InventoryItemID: InventoryEntry] = [:]

    init(modelContext: ModelContext, storedEntries: [InventoryEntry]) {
        self.modelContext = modelContext
        self.entries = Dictionary(uniqueKeysWithValues: storedEntries.compactMap { entry in
            guard let item = entry.item else { return nil }
            return (item, entry)
        })

        for item in InventoryItemID.allCases where self.entries[item] == nil {
            let startingQuantity = item == .gold ? 20 : 0
            let created = InventoryEntry(itemID: item, quantity: startingQuantity)
            modelContext.insert(created)
            self.entries[item] = created
        }
    }

    func quantity(of item: InventoryItemID) -> Int {
        entries[item]?.quantity ?? 0
    }

    func add(_ item: InventoryItemID, amount: Int) {
        guard amount > 0 else { return }
        entry(for: item).quantity += amount
    }

    @discardableResult
    func remove(_ item: InventoryItemID, amount: Int) -> Bool {
        guard amount > 0, quantity(of: item) >= amount else { return false }
        entry(for: item).quantity -= amount
        return true
    }

    func nonEmptyStacks() -> [(InventoryItemID, Int)] {
        InventoryItemID.inventoryDisplayOrder.compactMap { item in
            let amount = quantity(of: item)
            guard amount > 0 else { return nil }
            return (item, amount)
        }
    }

    func apply(drops: [InventoryItemDrop]) {
        for drop in drops {
            add(drop.item, amount: drop.amount)
        }
    }

    private func entry(for item: InventoryItemID) -> InventoryEntry {
        if let existing = entries[item] {
            return existing
        }
        let created = InventoryEntry(itemID: item)
        modelContext.insert(created)
        entries[item] = created
        return created
    }

    static func loadEntries(from context: ModelContext) -> [InventoryEntry] {
        (try? context.fetch(FetchDescriptor<InventoryEntry>())) ?? []
    }

    /// Maps retired tool ids onto the tiered tools and deletes unsupported seeds.
    static func migrateRetiredItems(in context: ModelContext) {
        let entries = (try? context.fetch(FetchDescriptor<InventoryEntry>())) ?? []
        let replacements = [
            "pickaxe": InventoryItemID.stonePickaxe.rawValue,
            "basicAxe": InventoryItemID.stoneAxe.rawValue,
            "breezeMote": InventoryItemID.airRune.rawValue,
            "tideMote": InventoryItemID.waterRune.rawValue,
            "stoneMote": InventoryItemID.earthRune.rawValue,
            "emberMote": InventoryItemID.fireRune.rawValue,
            "focusShard": InventoryItemID.mindRune.rawValue
        ]
        let removed: Set<String> = [
            "appleSeed", "oakSapling", "seedPack", "treeBranch", "mysteryCrate",
            "workerRations", "lootBag", "hammer"
        ]

        for entry in entries {
            if removed.contains(entry.itemID) {
                context.delete(entry)
                continue
            }
            guard let replacement = replacements[entry.itemID] else { continue }
            if let existing = entries.first(where: { $0 !== entry && $0.itemID == replacement }) {
                existing.quantity += max(0, entry.quantity)
                context.delete(entry)
            } else {
                entry.itemID = replacement
            }
        }
        try? context.save()
    }
}
