import SwiftUI

struct AutoGathererCard: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let owned = game.inventory.quantity(of: .autoGatherer) > 0
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ItemIconView(item: .autoGatherer, size: 28)
                Text("Auto-Gatherer")
                    .font(.headline)
                Spacer()
                if owned {
                    Text(progressLabel)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(GardenPalette.moss)
                }
            }
            Text("Requires Total Level \(AutoGathererBalance.requiredTotalLevel). Buy one from the General Store for \(AutoGathererBalance.price) gold. It places 1 copper ore, wood, or shrimp into Worker Storage every \(Int(AutoGathererBalance.interval)) seconds and grants the same skill XP as gathering that resource by hand.")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
            if owned {
                ProgressView(value: progress)
                    .tint(GardenPalette.moss)
                Text("Owned. Collect its output from Worker Storage. Selling the machine stops it.")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GardenPalette.leaf)
            } else {
                Text("Total Level \(game.totalLevel) / \(AutoGathererBalance.requiredTotalLevel)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(game.totalLevel >= AutoGathererBalance.requiredTotalLevel ? GardenPalette.moss : GardenPalette.inkMuted)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
    }

    private var progress: Double {
        min(1, game.playerRecord.autoGatherProgress / AutoGathererBalance.interval)
    }

    private var progressLabel: String {
        let remaining = max(0, Int(ceil(AutoGathererBalance.interval - game.playerRecord.autoGatherProgress)))
        return "Next in \(remaining)s"
    }
}

struct FarmingBoard: View {
    @Environment(GameController.self) private var game
    @State private var plantingPlot: Int?

    var body: some View {
        let _ = game.stateVersion
        VStack(alignment: .leading, spacing: 10) {
            Text("Farming \(game.skillLevel(for: .farming))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GardenPalette.moss)
            ForEach(0..<FarmPlotCodec.count, id: \.self) { index in
                plotRow(index)
            }
            if let label = game.boostRemainingLabel(game.playerRecord.gatherBoostEnd) {
                Text("Gatherer's Brew \(label)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GardenPalette.moss)
            }
        }
        .sheet(item: Binding(
            get: { plantingPlot.map(PlotPickerID.init(id:)) },
            set: { plantingPlot = $0?.id }
        )) { picker in
            SeedPickerSheet(plotIndex: picker.id) {
                plantingPlot = nil
            }
            .environment(game)
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func plotRow(_ index: Int) -> some View {
        let unlock = game.plotUnlockLevel(index)
        let plot = game.farmPlots[index]
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Plot \(index + 1)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if game.skillLevel(for: .farming) < unlock {
                    Text("Farming \(unlock)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GardenPalette.inkMuted)
                }
            }
            if game.skillLevel(for: .farming) < unlock {
                Text("Locked")
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)
            } else if let cropID = plot.cropID, let crop = FarmingCatalog.crop(id: cropID) {
                growingRow(crop, index: index)
            } else {
                Button {
                    plantingPlot = index
                } label: {
                    HStack {
                        Text("Empty · Tap to plant")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Image(systemName: "leaf")
                            .font(.caption)
                    }
                    .foregroundStyle(GardenPalette.moss)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(GardenPalette.moss.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func growingRow(_ crop: CropDefinition, index: Int) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = game.growthRemaining(for: game.farmPlots[index], now: context.date)
            let ready = remaining <= 0
            HStack(spacing: 8) {
                ItemIconView(item: crop.harvest, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(crop.name)
                        .font(.caption.weight(.semibold))
                    Text(ready ? "Ready · \(crop.harvestQuantity) \(crop.harvest.displayName)" : "\(Int(ceil(remaining)))s left")
                        .font(.caption2)
                        .foregroundStyle(ready ? GardenPalette.moss : GardenPalette.inkMuted)
                }
                Spacer()
                Button("Harvest") {
                    game.harvestPlot(index)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(GardenPalette.moss)
                .disabled(!ready)
            }
        }
    }
}

private struct PlotPickerID: Identifiable {
    let id: Int
}

private struct SeedPickerSheet: View {
    @Environment(GameController.self) private var game
    let plotIndex: Int
    let onClose: () -> Void

    var body: some View {
        let _ = game.stateVersion
        NavigationStack {
            List {
                ForEach(FarmingCatalog.crops) { crop in
                    let owned = game.inventory.quantity(of: crop.seed)
                    let canPlant = game.canPlant(crop, in: plotIndex)
                    Button {
                        game.plant(crop, in: plotIndex)
                        onClose()
                    } label: {
                        HStack(spacing: 10) {
                            ItemIconView(item: crop.seed, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(crop.seed.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(GardenPalette.ink)
                                Text("Owned \(owned) · Farming \(crop.farmingLevel) · \(Int(crop.growth))s")
                                    .font(.caption2)
                                    .foregroundStyle(GardenPalette.inkMuted)
                                Text("Grows \(crop.harvestQuantity)× \(crop.harvest.displayName)")
                                    .font(.caption2)
                                    .foregroundStyle(GardenPalette.moss)
                            }
                            Spacer()
                            if !canPlant {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(GardenPalette.inkMuted)
                            }
                        }
                    }
                    .disabled(!canPlant)
                }
            }
            .navigationTitle("Plant Plot \(plotIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
        }
    }
}
