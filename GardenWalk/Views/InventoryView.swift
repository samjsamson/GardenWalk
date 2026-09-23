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
                    EquipmentBoard()

                    let stacks = game.inventory.nonEmptyStacks()
                    let bag = stacks.filter { $0.0.equipmentSlot == nil }
                    let food = bag.filter { FarmingCatalog.healAmount(for: $0.0) != nil && FarmingCatalog.potion(for: $0.0) == nil }
                    let potions = bag.filter { FarmingCatalog.potion(for: $0.0) != nil }
                    let tools = bag.filter { isTool($0.0) }
                    let resources = bag.filter { isResource($0.0) }
                    let other = bag.filter {
                        FarmingCatalog.healAmount(for: $0.0) == nil
                            && FarmingCatalog.potion(for: $0.0) == nil
                            && !isTool($0.0)
                            && !isResource($0.0)
                    }
                    let gear = stacks.filter { $0.0.equipmentSlot != nil }

                    if gear.isEmpty && bag.isEmpty {
                        ContentUnavailableView(
                            "No items yet",
                            systemImage: "tray",
                            description: Text("Gather resources or visit the General Store on Home.")
                        )
                        .padding(.top, 12)
                    }

                    section("Equipment", items: gear, kind: .gear)
                    section("Food", items: food, kind: .food)
                    section("Potions", items: potions, kind: .potion)
                    section("Resources", items: resources, kind: .resource)
                    section("Tools", items: tools, kind: .tool)
                    section("Other", items: other, kind: .other)
                }
                .padding()
            }
            .background(GardenPalette.cream.ignoresSafeArea())
            .navigationTitle("Inventory")
            .statusHUD()
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
        case gear, food, potion, resource, tool, other
    }

    @ViewBuilder
    private func section(_ title: String, items: [(InventoryItemID, Int)], kind: SectionKind) -> some View {
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
                        case .gear:
                            GearInventoryRow(item: item, quantity: quantity) {
                                game.equip(item)
                            }
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
                        case .potion:
                            EffectInventoryRow(
                                item: item,
                                quantity: quantity,
                                effect: potionEffect(item),
                                actionTitle: "Drink",
                                canUse: game.canUse(item),
                                onInspect: { inspectedItem = item },
                                onUse: { game.use(item) }
                            )
                        default:
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

    private func potionEffect(_ item: InventoryItemID) -> String {
        FarmingCatalog.potion(for: item)?.effect ?? item.effect
    }

    private func isTool(_ item: InventoryItemID) -> Bool {
        switch item {
        case .stoneAxe, .copperAxe, .bronzeAxe, .ironAxe, .steelAxe,
             .stonePickaxe, .copperPickaxe, .bronzePickaxe, .ironPickaxe, .steelPickaxe,
             .fishingRod, .hammer, .torch, .autoGatherer:
            true
        default:
            false
        }
    }

    private func isResource(_ item: InventoryItemID) -> Bool {
        switch item {
        case .gold, .copperOre, .tinOre, .ironOre, .coal, .silverOre, .goldOre, .mithrilOre, .adamantOre,
             .wood, .stone, .bronzeBar, .ironBar, .steelBar, .mithrilBar, .adamantBar, .leather,
             .runeEssence, .airRune, .waterRune, .earthRune, .fireRune, .mindRune, .bones:
            true
        default:
            false
        }
    }
}

private struct EffectInventoryRow: View {
    let item: InventoryItemID
    let quantity: Int
    let effect: String
    var actionTitle: String = "Use"
    let canUse: Bool
    let onInspect: () -> Void
    let onUse: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onInspect) {
                ItemIconView(item: item, size: 40)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(item.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(effect)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GardenPalette.moss)
                        .lineLimit(2)
                }
                Text("×\(quantity)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(GardenPalette.inkMuted)
            }
            Spacer(minLength: 4)
            Button(actionTitle, action: onUse)
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(GardenPalette.moss)
                .disabled(!canUse)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct CompactInventoryRow: View {
    let item: InventoryItemID
    let quantity: Int
    let canUse: Bool
    let onInspect: () -> Void
    let onUse: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onInspect) {
                ItemIconView(item: item, size: 40)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("×\(quantity)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(GardenPalette.inkMuted)
            }
            Spacer(minLength: 4)
            if canUse {
                Button("Use", action: onUse)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(GardenPalette.moss)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct GearInventoryRow: View {
    let item: InventoryItemID
    let quantity: Int
    let onEquip: () -> Void

    private var record: SmithingItemRecord? {
        SmithingCatalog.record(for: item)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ItemIconView(item: item, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let tier = record?.tierName {
                    Text(tier)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GardenPalette.moss)
                }
                if let requirement = record?.requirementText ?? EquipmentCatalog.requirementText(for: item) {
                    Text(requirement)
                        .font(.caption2)
                        .foregroundStyle(GardenPalette.inkMuted)
                }
                if let stats = record?.statsText ?? EquipmentCatalog.combatStatsText(for: item) {
                    Text(stats)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GardenPalette.leaf)
                }
                Text("\(quantity) in bag")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(GardenPalette.inkMuted)
            }
            Spacer(minLength: 4)
            Button("Equip", action: onEquip)
                .font(.caption.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(GardenPalette.moss)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ItemDetailPopup: View {
    let item: InventoryItemID
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            VStack(spacing: 12) {
                ItemIconView(item: item, size: 72)
                Text(item.displayName)
                    .font(.headline)
                Text(item.summary)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GardenPalette.inkMuted)
                Text(item.effect)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GardenPalette.moss)
                Button("Close", action: onClose)
                    .buttonStyle(.borderedProminent)
                    .tint(GardenPalette.moss)
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(24)
        }
    }
}
