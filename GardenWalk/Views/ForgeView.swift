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

    var body: some View {
        let _ = game.stateVersion
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
            .padding()
        }
        .background(GardenPalette.cream.ignoresSafeArea())
        .navigationTitle("Forge")
        .navigationBarTitleDisplayMode(.inline)
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
            if game.inventory.quantity(of: .hammer) == 0 {
                Text("You need a hammer to smith items.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GardenPalette.soil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(GardenPalette.soil.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Text("Your hammer stays in your bag. It is not used up.")
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Leather")
                    .font(.headline)
                Text("Boots made without the anvil. Leather boots are sold at the General Store.")
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)
                ForEach(CraftingCatalog.recipes(in: .smithing)) { recipe in
                    LeatherCraftCard(recipe: recipe)
                }
            }
        }
    }

    private func quantity(for id: String, maximum: Int) -> Int {
        let stored = quantities[id] ?? 1
        if maximum <= 0 { return 1 }
        return min(max(1, stored), maximum)
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
    private var hasHammer: Bool { game.inventory.quantity(of: .hammer) > 0 }
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
            .disabled(!levelMet || !hasHammer || maximum < 1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(levelMet ? 1 : 0.72)
    }

    private var buttonTitle: String {
        if !levelMet { return "Requires Smithing \(recipe.requiredSmithingLevel)" }
        if !hasHammer { return "Needs a hammer" }
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
                if let stats = SmithingCatalog.record(for: recipe.output)?.statsText {
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
