import SwiftUI

struct ProfileView: View {
    @Environment(GameController.self) private var game
    @Environment(AuthController.self) private var auth
    @State private var inspectedItem: InventoryItemID?
    @State private var collapsed: Set<String> = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        let _ = game.stateVersion
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    EquipmentBoard()

                    let stacks = game.inventory.nonEmptyStacks()
                    let bag = stacks.filter { $0.0.equipmentSlot == nil }
                    let potions = bag.filter { FarmingCatalog.potion(for: $0.0) != nil }
                    let tools = bag.filter { InventoryClassification.isTool($0.0) }
                    let other = bag.filter {
                        FarmingCatalog.healAmount(for: $0.0) == nil
                            && FarmingCatalog.potion(for: $0.0) == nil
                            && !InventoryClassification.isTool($0.0)
                            && !InventoryClassification.isResource($0.0)
                    }
                    let gear = stacks.filter { $0.0.equipmentSlot != nil }

                    section("Equipment", items: gear, kind: .gear)
                    statsSection
                    toolsSection(bagTools: tools)
                    section("Potions", items: potions, kind: .potion)
                    section("Other", items: other, kind: .other)

                    if gear.isEmpty && bag.isEmpty {
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
            .navigationTitle(auth.currentUsername ?? "Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        StatusHUD()
                        Button("Sign Out") {
                            auth.signOut()
                        }
                        .font(.caption.weight(.semibold))
                    }
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

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stats")
                .font(.headline)
            Text("Total Level \(game.totalLevel)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(GardenPalette.moss)
            Text("The sum of every skill level.")
                .font(.caption2)
                .foregroundStyle(GardenPalette.inkMuted)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(SkillKind.allCases) { skill in
                    SkillStatTile(skill: skill, progress: game.progress(for: skill))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private enum SectionKind {
        case gear, potion, tool, other
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

    private func toolsSection(bagTools: [(InventoryItemID, Int)]) -> some View {
        let open = !collapsed.contains("Tools")
        return VStack(alignment: .leading, spacing: 10) {
            Button {
                if open { collapsed.insert("Tools") } else { collapsed.remove("Tools") }
            } label: {
                HStack {
                    Text("Tools").font(.headline)
                    Spacer()
                    Image(systemName: open ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GardenPalette.inkMuted)
                }
                .foregroundStyle(GardenPalette.ink)
            }
            .buttonStyle(.plain)
            if open {
                ToolEquipStatusRow(title: "Pickaxe", slot: .pickaxe)
                ToolEquipStatusRow(title: "Axe", slot: .axe)
                ToolEquipStatusRow(title: "Fishing Rod", slot: .fishingRod)
                ForEach(bagTools, id: \.0) { item, quantity in
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
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func potionEffect(_ item: InventoryItemID) -> String {
        FarmingCatalog.potion(for: item)?.effect ?? item.effect
    }
}

private struct ToolEquipStatusRow: View {
    @Environment(GameController.self) private var game
    let title: String
    let slot: EquipmentSlot

    var body: some View {
        let equipped = game.equippedItem(in: slot)
        HStack(spacing: 10) {
            Image(systemName: slot.emptySymbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(GardenPalette.moss)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let equipped {
                    Text(equipped.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GardenPalette.moss)
                    if let tier = SmithingCatalog.record(for: equipped)?.tierName {
                        Text(tier)
                            .font(.caption2)
                            .foregroundStyle(GardenPalette.inkMuted)
                    }
                } else {
                    Text("Not Equipped")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GardenPalette.soil)
                }
            }
            Spacer(minLength: 4)
            if let equipped {
                ItemIconView(item: equipped, size: 32)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SkillStatTile: View {
    let skill: SkillKind
    let progress: SkillLevelProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(skill.emoji)
                .font(.body)
            Text(skill.displayName)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Lv \(progress.level)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(GardenPalette.moss)
            if progress.isMaxLevel {
                Text("Max")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GardenPalette.leaf)
            } else {
                SkillXPBar(fraction: progress.progressFraction)
                Text("\(progress.xpIntoLevel.formatted()) / \(progress.xpForNextLevel.formatted())")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(GardenPalette.inkMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct SkillXPBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.15))
                Capsule()
                    .fill(GardenPalette.moss)
                    .frame(width: max(4, geometry.size.width * fraction))
            }
        }
        .frame(height: 4)
    }
}

enum InventoryClassification {
    static func isTool(_ item: InventoryItemID) -> Bool {
        switch item {
        case .stoneAxe, .copperAxe, .bronzeAxe, .ironAxe, .steelAxe, .mithrilAxe, .adamantAxe,
             .stonePickaxe, .copperPickaxe, .bronzePickaxe, .ironPickaxe, .steelPickaxe, .mithrilPickaxe, .adamantPickaxe,
             .fishingRod, .copperFishingRod, .bronzeFishingRod, .ironFishingRod, .steelFishingRod, .mithrilFishingRod, .adamantFishingRod,
             .torch, .autoGatherer:
            true
        default:
            false
        }
    }

    static func isResource(_ item: InventoryItemID) -> Bool {
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

struct EffectInventoryRow: View {
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

struct CompactInventoryRow: View {
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

struct ItemDetailPopup: View {
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
