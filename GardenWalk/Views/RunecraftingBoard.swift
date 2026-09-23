import SwiftUI

struct AltarBoard: View {
    @Environment(GameController.self) private var game
    @State private var craftingAltar: AltarDefinition?

    var body: some View {
        let _ = game.stateVersion
        VStack(alignment: .leading, spacing: 8) {
            Text("Altars")
                .font(.subheadline.weight(.semibold))
            Text("Craft Rune Essence into runes. This grants Runecrafting XP. Quick Craft uses \(game.altarBatchLimit()) essence\(game.inventory.quantity(of: .runePouch) > 0 ? " with your pouch" : "").")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
            ForEach(RunecraftingCatalog.altars) { altar in
                altarRow(altar)
            }
        }
        .sheet(item: $craftingAltar) { altar in
            AltarQuantitySheet(altar: altar) {
                craftingAltar = nil
            }
            .environment(game)
            .presentationDetents([.medium])
        }
    }

    private func altarRow(_ altar: AltarDefinition) -> some View {
        let level = game.skillLevel(for: .runecrafting)
        let locked = level < altar.runecraftingLevel
        let quick = game.maxAltarCraft(altar)
        let absolute = game.maxAltarCraftAbsolute(altar)
        return HStack(spacing: 8) {
            ItemIconView(item: altar.rune, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(altar.name)
                    .font(.caption.weight(.semibold))
                Text(locked
                     ? "Runecrafting \(altar.runecraftingLevel)"
                     : "\(altar.runesPerEssence) \(altar.rune.displayName) · \(altar.xp) XP each")
                    .font(.caption2)
                    .foregroundStyle(GardenPalette.inkMuted)
            }
            Spacer(minLength: 4)
            Button(quick > 1 ? "Craft \(quick)" : "Craft") {
                game.craftAtAltar(altar)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(GardenPalette.moss)
            .disabled(locked || quick == 0)
            Button("Craft X") {
                craftingAltar = altar
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(GardenPalette.moss)
            .disabled(locked || absolute == 0)
        }
    }
}

private struct AltarQuantitySheet: View {
    @Environment(GameController.self) private var game
    let altar: AltarDefinition
    let onClose: () -> Void
    @State private var quantity = 1

    private var maximum: Int { game.maxAltarCraftAbsolute(altar) }

    var body: some View {
        let _ = game.stateVersion
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    ItemIconView(item: altar.rune, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(altar.name)
                            .font(.headline)
                        Text("Essence \(game.inventory.quantity(of: .runeEssence)) · Max \(maximum)")
                            .font(.caption)
                            .foregroundStyle(GardenPalette.inkMuted)
                    }
                }
                Text("Makes \(altar.runesPerEssence * quantity) \(altar.rune.displayName) · +\(altar.xp * quantity) Runecrafting XP")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GardenPalette.moss)

                HStack(spacing: 8) {
                    ForEach([1, 5, 10], id: \.self) { preset in
                        Button("\(preset)") {
                            quantity = min(preset, max(1, maximum))
                        }
                        .buttonStyle(.bordered)
                        .disabled(maximum < preset && preset != 1)
                    }
                    Button("Max") {
                        quantity = max(1, maximum)
                    }
                    .buttonStyle(.bordered)
                    .disabled(maximum < 1)
                }

                HStack(spacing: 12) {
                    Button("-") { quantity = max(1, quantity - 1) }
                        .disabled(quantity <= 1)
                    TextField("Qty", value: $quantity, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 64)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: quantity) { _, value in
                            quantity = min(max(1, value), max(1, maximum))
                        }
                    Button("+") { quantity = min(maximum, quantity + 1) }
                        .disabled(quantity >= maximum)
                }
                .buttonStyle(.bordered)

                Button("Craft \(quantity)") {
                    game.craftAtAltar(altar, quantity: quantity)
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .tint(GardenPalette.moss)
                .disabled(maximum < 1)
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding()
            .navigationTitle("Craft Runes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
            .onAppear {
                quantity = min(max(1, game.altarBatchLimit()), max(1, maximum))
            }
        }
    }
}
