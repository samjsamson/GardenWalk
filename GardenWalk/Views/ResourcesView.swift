import SwiftUI

struct ResourcesView: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let _ = game.stateVersion
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if game.showsWorkerStorage {
                        WorkerStorageCard()
                    }
                    AutoGathererCard()
                    ForEach(ResourceSpotKind.allCases) { spot in
                        ResourceSpotCard(spot: spot)
                    }

                    if let result = game.lastGatherResult {
                        lastResultCard(result)
                    }
                }
                .padding()
            }
            .background(GardenPalette.cream.ignoresSafeArea())
            .navigationTitle("Resources")
            .statusHUD()
        }
    }

    private func lastResultCard(_ result: GatheringResult) -> some View {
        HStack(spacing: 8) {
            Text(result.resource.name)
                .font(.subheadline.weight(.semibold))
            Text("+\(result.xpGained) XP")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
            Spacer(minLength: 8)
            ForEach(result.itemDrops) { drop in
                HStack(spacing: 2) {
                    ItemIconView(item: drop.item, size: 16)
                    Text(drop.amount.formatted())
                        .font(.caption.monospacedDigit())
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(GardenPalette.skyBottom.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct WorkerStorageCard: View {
    @Environment(GameController.self) private var game

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Worker Storage")
                    .font(.headline)
                Spacer()
                Text("\(game.workerStorageCount) / \(game.workerStorageCapacity)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(game.isWorkerStorageFull ? GardenPalette.soil : GardenPalette.leaf)
            }

            ProgressView(value: game.workerStorageFraction)
                .tint(game.isWorkerStorageFull ? GardenPalette.soil : GardenPalette.moss)

            HStack(spacing: 8) {
                ProgressView(value: game.nextWorkerTickFraction)
                    .tint(GardenPalette.leaf)
                Text(game.nextWorkerTickLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(game.isWorkerStorageFull ? GardenPalette.soil : GardenPalette.inkMuted)
                    .fixedSize()
            }

            if game.workerStorageStacks.isEmpty {
                Text("Nothing waiting")
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)
            } else {
                ForEach(game.workerStorageStacks, id: \.0) { item, amount in
                    HStack(spacing: 8) {
                        ItemIconView(item: item, size: 22)
                        Text(item.displayName)
                            .font(.subheadline)
                        Spacer()
                        Text("x\(amount)")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                    }
                }
            }

            Button("Collect All") {
                game.collectWorkerStorage()
            }
            .buttonStyle(.borderedProminent)
            .tint(GardenPalette.moss)
            .disabled(game.workerStorageStacks.isEmpty)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
    }
}

private struct ResourceSpotCard: View {
    @Environment(GameController.self) private var game
    let spot: ResourceSpotKind
    @State private var resourcesExpanded = false

    private var resources: [ResourceDefinition] {
        ResourceCatalog.resources(for: spot)
    }

    private var visibleResources: [ResourceDefinition] {
        resourcesExpanded ? resources : Array(resources.prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: spot.symbolName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(GardenPalette.moss)
                Text(spot.title)
                    .font(.headline)
                Spacer(minLength: 8)
                if spot != .gardenSpot {
                    HStack(spacing: 4) {
                        ItemIconView(visual: .worker, size: 22)
                        Text(game.assignedWorkers(for: spot).formatted())
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(GardenPalette.leaf)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(game.assignedWorkers(for: spot)) workers")
                }
            }

            if spot == .gardenSpot {
                Text("Plant seeds, wait for them to grow, then harvest food and potion ingredients. Workers are not used here.")
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)
                FarmingBoard()
            } else {
                Text("Assign idle workers to each resource with + / −. \(game.unassignedWorkerCount) idle.")
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)

                GatheringSiteView(spot: spot)

                VStack(spacing: 6) {
                    ForEach(visibleResources) { resource in
                        ResourceRow(resource: resource)
                    }
                    if resources.count > 2 {
                        Button(resourcesExpanded ? "Collapse" : "Expand") {
                            withAnimation(.easeInOut(duration: 0.2)) { resourcesExpanded.toggle() }
                        }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(GardenPalette.moss)
                    }
                }

                if spot == .runeMine {
                    Text("Mining Rune Essence grants Mining XP. The mine opens at Mining level 10.")
                        .font(.caption)
                        .foregroundStyle(GardenPalette.inkMuted)
                    AltarBoard()
                }
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
    }
}

private struct ResourceRow: View {
    @Environment(GameController.self) private var game
    let resource: ResourceDefinition

    private var assigned: Int {
        game.assignedWorkers(for: resource)
    }

    var body: some View {
        HStack(spacing: 10) {
            ItemIconView(art: ItemArtCatalog.art(for: resource), size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(resource.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if game.canGather(resource) {
                    Text("Lv \(resource.requiredLevel)")
                        .font(.caption2)
                        .foregroundStyle(GardenPalette.inkMuted)
                } else if resource.isPlayable {
                    Text("Requires Lv \(resource.requiredLevel)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GardenPalette.inkMuted)
                } else {
                    Text("Coming soon · Lv \(resource.requiredLevel)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GardenPalette.inkMuted)
                }
            }
            Spacer(minLength: 8)
            if game.canGather(resource) {
                HStack(spacing: 6) {
                    Button {
                        game.removeWorker(from: resource)
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(GardenPalette.inkMuted)
                    .disabled(!game.canRemoveWorker(from: resource))
                    .accessibilityLabel("Remove worker from \(resource.name)")

                    Text(assigned.formatted())
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(assigned > 0 ? GardenPalette.moss : GardenPalette.inkMuted)
                        .frame(minWidth: 18)

                    Button {
                        game.assignWorker(to: resource)
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(GardenPalette.moss)
                    .disabled(!game.canAssignWorker(to: resource))
                    .accessibilityLabel("Add worker to \(resource.name)")
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            assigned > 0 ? GardenPalette.moss.opacity(0.12) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .opacity(game.canGather(resource) || !resource.isPlayable ? 1 : 0.6)
    }
}
