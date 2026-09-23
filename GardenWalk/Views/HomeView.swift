import SwiftUI

private enum StoreMode: String, CaseIterable, Identifiable {
    case buy
    case sell

    var id: String { rawValue }
}

struct HomeView: View {
    @Environment(GameController.self) private var game
    @State private var storeMode: StoreMode = .buy
    @State private var sellQuantities: [String: Int] = [:]
    @State private var buyQuantities: [String: Int] = [:]
    @State private var inspectedListing: StoreListing?
    @State private var showStore = false
    @State private var storeExpanded = false
    @State private var sellExpanded = false
    @State private var showCombat = false
    @State private var combatExpanded = false
    @State private var battlingEnemy: EnemyDefinition?

    var body: some View {
        let _ = game.stateVersion
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    tasksSection
                    combatSection
                    generalStoreSection
                }
                .padding()
            }
            .background(GardenPalette.cream.ignoresSafeArea())
            .navigationTitle("GardenWalk")
            .statusHUD()
            .overlay {
                if let inspectedListing {
                    StoreItemPopup(
                        listing: inspectedListing,
                        price: game.price(for: inspectedListing)
                    ) {
                        self.inspectedListing = nil
                    }
                }
            }
            .sheet(isPresented: $showStore) {
                fullSheet(title: "General Store") {
                    storeContents(limit: nil)
                }
            }
            .sheet(isPresented: $showCombat) {
                NavigationStack {
                    CombatView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showCombat = false }
                            }
                        }
                }
                .environment(game)
            }
            .fullScreenCover(item: $battlingEnemy) { enemy in
                CombatBattleView(enemy: enemy) {
                    battlingEnemy = nil
                }
                .environment(game)
            }
        }
    }

    private func fullSheet<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding()
            }
            .background(GardenPalette.cream.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismissSheet() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    StatusHUD()
                }
            }
            .overlay {
                if let inspectedListing {
                    StoreItemPopup(
                        listing: inspectedListing,
                        price: game.price(for: inspectedListing)
                    ) {
                        self.inspectedListing = nil
                    }
                }
            }
        }
        .environment(game)
    }

    private func dismissSheet() {
        showStore = false
    }

    private var combatPool: [EnemyDefinition] {
        let ready = EnemyCatalog.all.filter { $0.isAvailable && game.combatLevel >= $0.requiredCombatLevel }
        if ready.isEmpty { return Array(EnemyCatalog.all.prefix(3)) }
        return ready.sorted { $0.requiredCombatLevel > $1.requiredCombatLevel }
    }

    private var combatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Combat") { showCombat = true }
                Spacer()
                if game.isCombatOnCooldown {
                    Text("Next fight in \(game.combatCooldownLabel)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GardenPalette.moss)
                }
            }
            Text("Creatures you can fight")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
            ForEach(window(combatPool, expanded: combatExpanded)) { enemy in
                EnemyCard(
                    enemy: enemy,
                    combatLevel: game.combatLevel,
                    canFight: game.canFight(enemy),
                    blockReason: game.fightBlockReason(enemy),
                    onFight: { battlingEnemy = enemy }
                )
            }
            if combatPool.count > 3 {
                expandButton(combatExpanded) { combatExpanded.toggle() }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var tasksSection: some View {
        if let task = game.currentTask() {
            let progress = game.taskProgress(task)
            let ready = game.isTaskReady(task)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Starter Tasks")
                        .font(.headline)
                    Spacer()
                    Text(game.taskStepLabel(for: task))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GardenPalette.moss)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.title3.weight(.semibold))
                    Text(task.requirement)
                        .font(.subheadline)
                        .foregroundStyle(GardenPalette.inkMuted)
                    HStack {
                        Text(ready ? "Completed" : "Progress")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ready ? GardenPalette.moss : GardenPalette.inkMuted)
                        Spacer()
                        Text("\(progress.current) / \(progress.goal)")
                            .font(.caption.monospacedDigit().weight(.semibold))
                    }
                    ProgressView(value: Double(progress.current), total: Double(max(progress.goal, 1)))
                        .tint(GardenPalette.moss)
                    HStack(spacing: 4) {
                        Text("Reward")
                            .font(.caption)
                            .foregroundStyle(GardenPalette.inkMuted)
                        Text("+\(task.goldReward)")
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(ItemPalette.goldDeep)
                        ItemIconView(item: .gold, size: 16)
                        Spacer()
                        Button(ready ? "Claim" : "In progress") {
                            game.claim(task)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(GardenPalette.moss)
                        .disabled(!ready)
                    }
                }
            }
            .padding()
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(GardenPalette.moss.opacity(0.35), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
        }
    }

    private var generalStoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("General Store") { showStore = true }
                Spacer()
                GoldBalanceLabel(amount: game.inventory.quantity(of: .gold))
            }
            storeContents(limit: 3)
        }
        .cardStyle()
    }

    @ViewBuilder
    private func storeContents(limit: Int?) -> some View {
        Picker("Store", selection: $storeMode) {
            Text("Buy").tag(StoreMode.buy)
            Text("Sell").tag(StoreMode.sell)
        }
        .pickerStyle(.segmented)

        if storeMode == .buy {
            ForEach(StoreCategory.allCases) { category in
                let listings = StoreCatalog.all.filter { $0.category == category }
                if !listings.isEmpty {
                    Text(category.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GardenPalette.moss)
                    let cap = limit.map { storeExpanded ? listings.count : min(2, $0) }
                    let shown = limited(listings, to: cap, expanded: false)
                    ForEach(shown) { listing in
                        buyRow(listing)
                    }
                }
            }
            if limit != nil, StoreCatalog.all.count > 6 {
                expandButton(storeExpanded) { storeExpanded.toggle() }
            }
        } else {
            sellSection(limit: limit)
        }
    }

    private func buyRow(_ listing: StoreListing) -> some View {
        let owned = game.ownsUniqueTool(listing)
        let quantity = buyQuantity(for: listing)
        let maxQuantity = game.maxPurchaseQuantity(for: listing)
        return StoreListingRow(
            listing: listing,
            quantity: quantity,
            totalCost: game.purchaseCost(listing, quantity: quantity),
            status: game.storeStatus(for: listing),
            footnote: listing.product == .worker ? game.workerCapNotice : nil,
            isOwned: owned,
            canDecrease: !owned && quantity > 1,
            canIncrease: !owned && maxQuantity > quantity,
            canMax: !owned && maxQuantity >= 1,
            canPurchase: !owned && game.canPurchase(listing, quantity: quantity),
            onInspect: { inspectedListing = listing },
            onDecrease: { changeBuyQuantity(for: listing, delta: -1) },
            onIncrease: { changeBuyQuantity(for: listing, delta: 1) },
            onMax: { buyQuantities[listing.id] = maxQuantity },
            onPurchase: {
                game.purchase(listing, quantity: quantity)
                buyQuantities[listing.id] = 1
            }
        )
    }

    @ViewBuilder
    private func sellSection(limit: Int?) -> some View {
        let stacks = game.sellableStacks()
        if stacks.isEmpty {
            Text("Nothing to sell")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
        } else {
            let shown = limited(stacks, to: limit, expanded: sellExpanded)
            ForEach(shown, id: \.0) { item, owned in
                let quantity = sellQuantity(for: item, owned: owned)
                SellItemRow(
                    item: item,
                    owned: owned,
                    quantity: quantity,
                    totalPayout: item.sellValue * quantity,
                    onDecrease: { changeSellQuantity(for: item, owned: owned, delta: -1) },
                    onIncrease: { changeSellQuantity(for: item, owned: owned, delta: 1) },
                    onMax: { sellQuantities[item.rawValue] = owned },
                    onSell: {
                        game.sell(item, quantity: quantity)
                        sellQuantities[item.rawValue] = 1
                    },
                    onSellAll: {
                        game.sellAll(item)
                        sellQuantities[item.rawValue] = 1
                    }
                )
            }
            if limit != nil, stacks.count > 3 {
                expandButton(sellExpanded) { sellExpanded.toggle() }
            }
        }
    }

    private func sellQuantity(for item: InventoryItemID, owned: Int) -> Int {
        let stored = sellQuantities[item.rawValue] ?? 1
        return min(max(1, stored), max(1, owned))
    }

    private func buyQuantity(for listing: StoreListing) -> Int {
        let maxQuantity = game.maxPurchaseQuantity(for: listing)
        let stored = buyQuantities[listing.id] ?? 1
        guard maxQuantity >= 1 else { return 1 }
        return min(max(1, stored), maxQuantity)
    }

    private func changeBuyQuantity(for listing: StoreListing, delta: Int) {
        let maxQuantity = max(1, game.maxPurchaseQuantity(for: listing))
        let next = buyQuantity(for: listing) + delta
        buyQuantities[listing.id] = min(max(1, next), maxQuantity)
    }

    private func changeSellQuantity(for item: InventoryItemID, owned: Int, delta: Int) {
        let next = sellQuantity(for: item, owned: owned) + delta
        sellQuantities[item.rawValue] = min(max(1, next), owned)
    }

    private func sectionTitle(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
            }
            .foregroundStyle(GardenPalette.ink)
        }
        .buttonStyle(.plain)
    }

    private func expandButton(_ expanded: Bool, action: @escaping () -> Void) -> some View {
        Button(expanded ? "Collapse" : "Expand", action: action)
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(GardenPalette.moss)
    }

    private func window<T>(_ items: [T], expanded: Bool) -> [T] {
        expanded ? items : Array(items.prefix(3))
    }

    private func limited<T>(_ items: [T], to limit: Int?, expanded: Bool) -> [T] {
        guard let limit, !expanded else { return items }
        return Array(items.prefix(limit))
    }
}

private extension View {
    func cardStyle() -> some View {
        padding()
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

private struct StoreListingRow: View {
    let listing: StoreListing
    let quantity: Int
    let totalCost: Int
    let status: String?
    let footnote: String?
    var isOwned: Bool = false
    let canDecrease: Bool
    let canIncrease: Bool
    let canMax: Bool
    let canPurchase: Bool
    let onInspect: () -> Void
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    let onMax: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onInspect) {
                    ItemIconView(art: ItemArtCatalog.art(for: listing), size: 40)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    Text(listing.name)
                        .font(.subheadline.weight(.semibold))
                    if let status {
                        Text(status)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isOwned ? GardenPalette.moss : GardenPalette.leaf)
                    }
                    if !isOwned {
                        HStack(spacing: 3) {
                            Text(totalCost.formatted())
                                .font(.caption.weight(.semibold).monospacedDigit())
                            ItemIconView(item: .gold, size: 14)
                        }
                    }
                }
                Spacer(minLength: 8)
                if isOwned {
                    Text("Owned")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(GardenPalette.moss)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(GardenPalette.moss.opacity(0.12), in: Capsule())
                } else {
                    Button("Buy", action: onPurchase)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(GardenPalette.moss)
                        .disabled(!canPurchase)
                }
            }
            if !isOwned {
                HStack(spacing: 6) {
                    Button("-", action: onDecrease)
                        .disabled(!canDecrease)
                    Text(quantity.formatted())
                        .font(.caption.monospacedDigit())
                        .frame(minWidth: 16)
                    Button("+", action: onIncrease)
                        .disabled(!canIncrease)
                    Button("Max", action: onMax)
                        .disabled(!canMax)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            if let footnote {
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(GardenPalette.inkMuted)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StoreItemPopup: View {
    let listing: StoreListing
    let price: Int
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            VStack(spacing: 12) {
                ItemIconView(art: ItemArtCatalog.art(for: listing), size: 72)
                Text(listing.name)
                    .font(.headline)
                Text(listing.summary)
                    .font(.subheadline)
                    .foregroundStyle(GardenPalette.inkMuted)
                    .multilineTextAlignment(.center)
                Text(listing.effect)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                HStack(spacing: 4) {
                    Text(price.formatted())
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                    ItemIconView(item: .gold, size: 16)
                }
                Button("Done", action: onClose)
                    .buttonStyle(.borderedProminent)
                    .tint(GardenPalette.moss)
            }
            .padding(20)
            .frame(maxWidth: 300)
            .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(32)
        }
    }
}

private struct SellItemRow: View {
    let item: InventoryItemID
    let owned: Int
    let quantity: Int
    let totalPayout: Int
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    let onMax: () -> Void
    let onSell: () -> Void
    let onSellAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ItemIconView(item: item, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text("\(owned) owned")
                        .font(.caption2)
                        .foregroundStyle(GardenPalette.inkMuted)
                }
                Spacer(minLength: 4)
                HStack(spacing: 3) {
                    Text(totalPayout.formatted())
                        .font(.caption.weight(.semibold).monospacedDigit())
                    ItemIconView(item: .gold, size: 14)
                }
                Button("Sell", action: onSell)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(GardenPalette.moss)
                Button("Sell All", action: onSellAll)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(GardenPalette.moss)
                    .disabled(owned <= 0)
            }
            HStack(spacing: 6) {
                Button("-", action: onDecrease)
                    .disabled(quantity <= 1)
                Text(quantity.formatted())
                    .font(.caption.monospacedDigit())
                    .frame(minWidth: 16)
                Button("+", action: onIncrease)
                    .disabled(quantity >= owned)
                Button("Max", action: onMax)
                    .disabled(owned < 1)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

