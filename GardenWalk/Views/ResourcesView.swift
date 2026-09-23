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
                HStack(spacing: 8) {
                    Button {
                        game.assignWorker(to: spot)
                    } label: {
                        Image(systemName: "plus").frame(width: 24, height: 28)
                    }
                    .accessibilityLabel("Add worker to \(spot.title)")
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(GardenPalette.moss)
                    .disabled(!game.canAssignWorker(to: spot))

                    Button {
                        game.removeWorker(from: spot)
                    } label: {
                        Image(systemName: "minus").frame(width: 24, height: 28)
                    }
                    .accessibilityLabel("Remove worker from \(spot.title)")
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(GardenPalette.inkMuted)
                    .disabled(!game.canRemoveWorker(from: spot))

                    Spacer(minLength: 0)

                    Text("\(game.unassignedWorkerCount) idle")
                        .font(.caption2)
                        .foregroundStyle(GardenPalette.inkMuted)
                }

                Text("Tap + to place an idle worker on an empty node. Collect what they produce from Worker Storage.")
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

    var body: some View {
        Button {
            if game.canGather(resource) {
                game.selectWorkerResource(resource)
            }
        } label: {
            HStack(spacing: 10) {
                ItemIconView(art: ItemArtCatalog.art(for: resource), size: 32)
                Text(resource.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                trailing
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isFocused ? GardenPalette.moss.opacity(0.12) : Color.clear,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(!game.canGather(resource))
        .opacity(game.canGather(resource) ? 1 : 0.6)
    }

    private var isFocused: Bool {
        game.focusedResource(for: resource.spot)?.id == resource.id
    }

    @ViewBuilder
    private var trailing: some View {
            if game.canGather(resource) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(isFocused ? "Gathering" : "Lv \(resource.requiredLevel)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GardenPalette.moss)
                    if !isFocused {
                        Text("Tap to focus")
                            .font(.caption2)
                            .foregroundStyle(GardenPalette.inkMuted)
                    }
                }
            } else if resource.isPlayable {
            Text("Requires Lv \(resource.requiredLevel)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GardenPalette.inkMuted)
        } else {
            Text("Coming soon · Lv \(resource.requiredLevel)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GardenPalette.inkMuted)
                .multilineTextAlignment(.trailing)
        }
    }
}
