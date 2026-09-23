import SwiftUI

private enum ForgeStation: String, CaseIterable, Identifiable {
    case furnace
    case anvil

    var id: String { rawValue }

    var title: String {
        switch self {
        case .furnace: "Furnace"
        case .anvil: "Anvil"
        }
    }
}

struct ForgeView: View {
    @Environment(GameController.self) private var game
    @State private var station: ForgeStation = .furnace
    @State private var quantities: [String: Int] = [:]
    @State private var expandedCrafting: Set<String> = []
    @State private var craftingSheet: CraftingSheet?

    var body: some View {
        let _ = game.stateVersion
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                forgeBlock
                altarsBlock
                craftingBlock
            }
            .padding()
        }
        .background(GardenPalette.cream.ignoresSafeArea())
        .navigationTitle("Forge")
        .navigationBarTitleDisplayMode(.large)
        .statusHUD()
        .onAppear {
            if station == .anvil {
                game.markAnvilVisited()
            }
        }
        .onChange(of: station) { _, newStation in
            if newStation == .anvil {
                game.markAnvilVisited()
            }
        }
        .sheet(item: $craftingSheet) { sheet in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        craftingContents(sheet)
                    }
                    .padding()
                }
                .background(GardenPalette.cream.ignoresSafeArea())
                .navigationTitle(sheet.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { craftingSheet = nil }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        StatusHUD()
                    }
                }
            }
            .environment(game)
        }
    }

    private var forgeBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Forge")
                .font(.headline)
            Picker("Station", selection: $station) {
                ForEach(ForgeStation.allCases) { station in
                    Text(station.title).tag(station)
                }
            }
            .pickerStyle(.segmented)

            switch station {
            case .furnace:
                furnace
            case .anvil:
                anvil
            }
        }
    }

    private var altarsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Runecrafting")
                .font(.headline)
            AltarBoard()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    private var furnace: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smelt ore into bars. Smithing level gates the hotter metals.")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
            ForEach(SmithingCatalog.smelting) { recipe in
                SmeltRecipeCard(
                    recipe: recipe,
                    quantity: quantity(for: recipe.id, maximum: game.maxSmeltCount(recipe)),
                    onChange: { quantities[recipe.id] = $0 },
                    onSmelt: { game.smelt(recipe, quantity: quantity(for: recipe.id, maximum: game.maxSmeltCount(recipe))) }
                )
            }
        }
    }

    private var anvil: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smith bars into weapons, armor, and gathering tools at the anvil.")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)

            VStack(alignment: .leading, spacing: 8) {
                Text("Leather")
                    .font(.headline)
                Text("Boots made from leather. Soft leather boots are also sold at the General Store.")
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)
                ForEach(CraftingCatalog.recipes(in: .smithing)) { recipe in
                    LeatherCraftCard(recipe: recipe)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Copper")
                    .font(.headline)
                Text("Smithing 1 · Copper Ore + Wood")
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)
                ForEach(CraftingCatalog.copperForgeTools) { recipe in
                    LeatherCraftCard(recipe: recipe)
                }
            }

            ForEach(MetalTier.allCases) { tier in
                VStack(alignment: .leading, spacing: 8) {
                    Text(tier.displayName)
                        .font(.headline)
                    Text("Smithing \(tier.smithingLevel) · \(tier.bar.displayName)")
                        .font(.caption)
                        .foregroundStyle(GardenPalette.inkMuted)
                    ForEach(SmithingCatalog.smithingRecipes(in: tier)) { recipe in
                        SmithRecipeCard(
                            recipe: recipe,
                            quantity: quantity(for: recipe.id, maximum: game.maxSmithCount(recipe)),
                            onChange: { quantities[recipe.id] = $0 },
                            onSmith: { game.smith(recipe, quantity: quantity(for: recipe.id, maximum: game.maxSmithCount(recipe))) }
                        )
                    }
                }
            }
        }
    }

    private var craftingBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                craftingSheet = .all
            } label: {
                HStack(spacing: 6) {
                    Text("Crafting")
                        .font(.headline)
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
                .foregroundStyle(GardenPalette.ink)
            }
            .buttonStyle(.plain)

            ForEach(CraftingCategory.allCases) { category in
                let recipes = CraftingCatalog.recipes(in: category)
                if !recipes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            craftingSheet = .category(category)
                        } label: {
                            HStack(spacing: 4) {
                                Text(category.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption2)
                            }
                            .foregroundStyle(GardenPalette.moss)
                        }
                        .buttonStyle(.plain)
                        let shown = expandedCrafting.contains(category.id) ? recipes : Array(recipes.prefix(3))
                        ForEach(shown) { recipe in
                            craftRow(recipe)
                        }
                        if recipes.count > 3 {
                            Button(expandedCrafting.contains(category.id) ? "Collapse" : "Expand") {
                                if expandedCrafting.contains(category.id) {
                                    expandedCrafting.remove(category.id)
                                } else {
                                    expandedCrafting.insert(category.id)
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(GardenPalette.moss)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    @ViewBuilder
    private func craftingContents(_ sheet: CraftingSheet) -> some View {
        switch sheet {
        case .all:
            ForEach(CraftingCategory.allCases) { category in
                let recipes = CraftingCatalog.recipes(in: category)
                if !recipes.isEmpty {
                    Text(category.displayName)
                        .font(.headline)
                        .foregroundStyle(GardenPalette.moss)
                    ForEach(recipes) { recipe in
                        craftRow(recipe)
                    }
                }
            }
        case .category(let category):
            ForEach(CraftingCatalog.recipes(in: category)) { recipe in
                craftRow(recipe)
            }
        }
    }

    private func craftRow(_ recipe: CraftingRecipeDefinition) -> some View {
        ForgeCraftingRow(
            item: recipe.output,
            title: recipe.output.displayName,
            detail: recipe.materialsDescription,
            isEnabled: game.canCraft(recipe),
            outputQuantity: recipe.outputQuantity
        ) {
            game.craft(recipe)
        }
    }

    private func quantity(for id: String, maximum: Int) -> Int {
        let stored = quantities[id] ?? 1
        if maximum <= 0 { return 1 }
        return min(max(1, stored), maximum)
    }
}

struct ForgeHubView: View {
    var body: some View {
        NavigationStack {
            ForgeView()
        }
    }
}

private enum CraftingSheet: Identifiable {
    case all
    case category(CraftingCategory)

    var id: String {
        switch self {
        case .all: "all"
        case .category(let category): category.id
        }
    }

    var title: String {
        switch self {
        case .all: "Crafting"
        case .category(let category): category.displayName
        }
    }
}

private struct SmeltRecipeCard: View {
    @Environment(GameController.self) private var game
    let recipe: SmeltingRecipe
    let quantity: Int
    let onChange: (Int) -> Void
    let onSmelt: () -> Void

    private var maximum: Int { game.maxSmeltCount(recipe) }
    private var levelMet: Bool { game.skillLevel(for: .smithing) >= recipe.requiredSmithingLevel }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ItemIconView(item: recipe.output, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.output.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text("Smithing \(recipe.requiredSmithingLevel) · +\(recipe.xpReward) XP")
                        .font(.caption)
                        .foregroundStyle(GardenPalette.inkMuted)
                }
                Spacer()
                Text("\(game.inventory.quantity(of: recipe.output)) owned")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(GardenPalette.inkMuted)
            }
            Text(consumptionLine)
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
            Text("Can make \(maximum)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(maximum > 0 ? GardenPalette.moss : GardenPalette.inkMuted)
            quantityControls
            Button(levelMet ? "Smelt" : "Requires Smithing \(recipe.requiredSmithingLevel)") {
                onSmelt()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(GardenPalette.moss)
            .disabled(!levelMet || maximum < 1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(levelMet ? 1 : 0.72)
    }

    private var consumptionLine: String {
        let parts = recipe.ingredients.map { ingredient in
            let owned = game.inventory.quantity(of: ingredient.item)
            return "\(ingredient.quantity * quantity) \(ingredient.item.displayName) (\(owned) owned)"
        }
        return "Uses \(parts.joined(separator: " and "))"
    }

    private var quantityControls: some View {
        HStack(spacing: 8) {
            Button("-") { onChange(quantity - 1) }
                .disabled(quantity <= 1)
            Text(quantity.formatted())
                .font(.caption.monospacedDigit())
                .frame(minWidth: 20)
            Button("+") { onChange(quantity + 1) }
                .disabled(maximum < 1 || quantity >= maximum)
            Button("Max") { onChange(max(maximum, 1)) }
                .disabled(maximum < 1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

private struct SmithRecipeCard: View {
    @Environment(GameController.self) private var game
    let recipe: SmithingRecipe
    let quantity: Int
    let onChange: (Int) -> Void
    let onSmith: () -> Void

    private var levelMet: Bool { game.skillLevel(for: .smithing) >= recipe.requiredSmithingLevel }
    private var ownedBars: Int { game.inventory.quantity(of: recipe.bar) }
    private var maximum: Int { game.maxSmithCount(recipe) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ItemIconView(item: recipe.output, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.output.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text("Smithing \(recipe.requiredSmithingLevel)")
                        .font(.caption)
                        .foregroundStyle(GardenPalette.inkMuted)
                    if let stats = SmithingCatalog.record(for: recipe.output)?.statsText {
                        Text(stats)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(GardenPalette.moss)
                    }
                }
                Spacer(minLength: 4)
            }
            Text("\(recipe.barsRequired) \(recipe.bar.displayName) · \(ownedBars) owned · +\(recipe.xpReward) XP")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
            if quantity > 1 {
                Text("Uses \(recipe.barsRequired * quantity) bars for \(quantity).")
                    .font(.caption2)
                    .foregroundStyle(GardenPalette.inkMuted)
            }
            quantityControls
            Button(buttonTitle) {
                onSmith()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(GardenPalette.moss)
            .disabled(!levelMet || maximum < 1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(levelMet ? 1 : 0.72)
    }

    private var buttonTitle: String {
        if !levelMet { return "Requires Smithing \(recipe.requiredSmithingLevel)" }
        return "Smith"
    }

    private var quantityControls: some View {
        HStack(spacing: 8) {
            Button("-") { onChange(quantity - 1) }
                .disabled(quantity <= 1)
            Text(quantity.formatted())
                .font(.caption.monospacedDigit())
                .frame(minWidth: 20)
            Button("+") { onChange(quantity + 1) }
                .disabled(maximum < 1 || quantity >= maximum)
            Button("Max") { onChange(max(maximum, 1)) }
                .disabled(maximum < 1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

private struct LeatherCraftCard: View {
    @Environment(GameController.self) private var game
    let recipe: CraftingRecipeDefinition

    var body: some View {
        HStack(spacing: 10) {
            ItemIconView(item: recipe.output, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.output.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(recipe.detailDescription)
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)
                if let stats = SmithingCatalog.record(for: recipe.output)?.statsText
                    ?? EquipmentCatalog.workerYieldDescription(for: recipe.output)
                    ?? EquipmentCatalog.combatStatsText(for: recipe.output) {
                    Text(stats)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GardenPalette.moss)
                }
            }
            Spacer()
            Button("Craft") { _ = game.craft(recipe) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(GardenPalette.moss)
                .disabled(!game.canCraft(recipe))
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ForgeCraftingRow: View {
    let item: InventoryItemID
    let title: String
    let detail: String
    let isEnabled: Bool
    let outputQuantity: Int
    let action: () -> Bool
    @State private var gains: [UUID] = []

    var body: some View {
        HStack(spacing: 12) {
            ItemIconView(item: item, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)
            }
            Spacer()
            Button("Craft") {
                guard action() else { return }
                gains.append(UUID())
            }
            .buttonStyle(.borderedProminent)
            .tint(GardenPalette.moss)
            .disabled(!isEnabled)
            .overlay(alignment: .top) {
                ForEach(gains, id: \.self) { id in
                    ForgeCraftGainLabel(quantity: outputQuantity) {
                        gains.removeAll { $0 == id }
                    }
                }
            }
        }
    }
}

private struct ForgeCraftGainLabel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let quantity: Int
    let onFinish: () -> Void
    @State private var floating = false

    var body: some View {
        Text("+\(quantity)")
            .font(.title3.bold())
            .foregroundStyle(GardenPalette.leaf)
            .shadow(color: .white, radius: 2)
            .offset(y: floating && !reduceMotion ? -46 : -8)
            .opacity(floating ? 0 : 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                withAnimation(.easeOut(duration: 0.85)) { floating = true }
                do { try await Task.sleep(for: .milliseconds(900)) }
                catch { return }
                onFinish()
            }
    }
}
