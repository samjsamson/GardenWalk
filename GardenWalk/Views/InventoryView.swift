import SwiftUI

struct InventoryView: View {
    @Environment(GameController.self) private var game
    @State private var inspectedItem: InventoryItemID?
    @State private var collapsed: Set<String> = []

    var body: some View {
        let _ = game.stateVersion
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    let bag = game.inventory.nonEmptyStacks().filter { $0.0.equipmentSlot == nil }
                    let food = bag.filter { FarmingCatalog.healAmount(for: $0.0) != nil && FarmingCatalog.potion(for: $0.0) == nil }
                    let items = bag.filter { InventoryClassification.isResource($0.0) }

                    inventorySection("Food", items: food, kind: .food)
                    inventorySection("Items", items: items, kind: .item)

                    if food.isEmpty && items.isEmpty {
                        ContentUnavailableView(
                            "No items yet",
                            systemImage: "tray",
                            description: Text("Gather resources or visit the General Store on Home.")
                        )
                        .padding(.top, 4)
                    }
                }
                .padding()
            }
            .background(GardenPalette.cream.ignoresSafeArea())
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StatusHUD()
                }
            }
            .overlay {
                if let inspectedItem {
                    ItemDetailPopup(item: inspectedItem) {
                        self.inspectedItem = nil
                    }
                }
            }
        }
    }

    private enum SectionKind {
        case food, item
    }

    @ViewBuilder
    private func inventorySection(_ title: String, items: [(InventoryItemID, Int)], kind: SectionKind) -> some View {
        if !items.isEmpty {
            let open = !collapsed.contains(title)
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    if open { collapsed.insert(title) } else { collapsed.remove(title) }
                } label: {
                    HStack {
                        Text(title).font(.headline)
                        Spacer()
                        Image(systemName: open ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(GardenPalette.inkMuted)
                    }
                    .foregroundStyle(GardenPalette.ink)
                }
                .buttonStyle(.plain)
                if open {
                    ForEach(items, id: \.0) { item, quantity in
                        switch kind {
                        case .food:
                            EffectInventoryRow(
                                item: item,
                                quantity: quantity,
                                effect: foodEffect(item),
                                actionTitle: "Eat",
                                canUse: game.canUse(item),
                                onInspect: { inspectedItem = item },
                                onUse: { game.use(item) }
                            )
                        case .item:
                            CompactInventoryRow(
                                item: item,
                                quantity: quantity,
                                canUse: game.canUse(item),
                                onInspect: { inspectedItem = item },
                                onUse: { game.use(item) }
                            )
                        }
                    }
                }
            }
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func foodEffect(_ item: InventoryItemID) -> String {
        if let heal = FarmingCatalog.healAmount(for: item) {
            return "+\(heal) HP"
        }
        return item.effect
    }
}
