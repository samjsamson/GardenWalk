import SwiftUI

struct CombatView: View {
    @Environment(GameController.self) private var game
    @State private var battlingEnemy: EnemyDefinition?

    var body: some View {
        let _ = game.stateVersion
        ScrollView {
            VStack(spacing: 20) {
                playerLoadoutCard
                cooldownCard
                enemyList
            }
            .padding()
        }
        .background(GardenPalette.cream.ignoresSafeArea())
        .navigationTitle("Combat")
        .statusHUD()
        .fullScreenCover(item: $battlingEnemy) { enemy in
            CombatBattleView(enemy: enemy) {
                battlingEnemy = nil
            }
        }
    }

    private var playerLoadoutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your loadout")
                .font(.headline)
            Text("Combat Level \(game.combatLevel)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GardenPalette.moss)
            ProgressView(value: game.progress(for: .combat).progressFraction)
                .tint(GardenPalette.moss)
            Text("Health \(game.currentHitPoints) / \(game.playerCombatHealth) · Defense \(game.playerCombatDefense)")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
            Text("Health carries between fights. Eat food from your bag to recover. In a fight, choose Attack or Magic. Every fight has a 2-minute recovery.")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
            HStack {
                Text("Attack power")
                Spacer()
                Text("\(game.playerAttackPower)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(GardenPalette.moss)
            }
            Text("Magic \(game.skillLevel(for: .magic))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GardenPalette.moss)
            if let attack = game.boostRemainingLabel(game.playerRecord.attackBoostEnd) {
                Text("Keen Oil \(attack)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GardenPalette.moss)
            }
            if let strength = game.boostRemainingLabel(game.playerRecord.strengthBoostEnd) {
                Text("Oak Draught \(strength)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GardenPalette.moss)
            }
            if let defense = game.boostRemainingLabel(game.playerRecord.defenseBoostEnd) {
                Text("Bark Tincture \(defense)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GardenPalette.moss)
            }
            if let magic = game.boostRemainingLabel(game.playerRecord.magicBoostEnd) {
                Text("Spark Philter \(magic)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GardenPalette.moss)
            }
            if let weapon = game.equippedWeapon {
                HStack(spacing: 6) {
                    ItemIconView(item: weapon, size: 22)
                    Text("Equipped: \(weapon.displayName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GardenPalette.leaf)
                }
            } else {
                Text("No weapon equipped")
                    .font(.caption)
                    .foregroundStyle(GardenPalette.inkMuted)
            }
        }
        .padding()
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    @ViewBuilder
    private var cooldownCard: some View {
        if game.isCombatOnCooldown {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(GardenPalette.moss)
                Text("Next fight available in \(game.combatCooldownLabel)")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(GardenPalette.skyBottom.opacity(0.55), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var enemyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enemies")
                .font(.headline)

            ForEach(EnemyCatalog.all) { enemy in
                EnemyCard(
                    enemy: enemy,
                    combatLevel: game.combatLevel,
                    canFight: game.canFight(enemy),
                    blockReason: game.fightBlockReason(enemy),
                    onFight: { battlingEnemy = enemy }
                )
            }
        }
        .padding()
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

}

struct EnemyCard: View {
    let enemy: EnemyDefinition
    let combatLevel: Int
    let canFight: Bool
    let blockReason: String?
    let onFight: () -> Void

    private var dropItems: [InventoryItemID] {
        var seen: [InventoryItemID] = []
        for entry in enemy.dropTable where !seen.contains(entry.item) {
            seen.append(entry.item)
        }
        return seen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(enemy.icon)
                    .font(.system(size: 36))
                VStack(alignment: .leading, spacing: 2) {
                    Text(enemy.name)
                        .font(.headline)
                    Text("Combat Lv \(enemy.requiredCombatLevel) · \(enemy.combatXP) XP per victory")
                        .font(.caption)
                        .foregroundStyle(GardenPalette.moss)
                    Text(enemy.difficultyLabel)
                        .font(.caption)
                        .foregroundStyle(GardenPalette.inkMuted)
                }
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dropItems, id: \.self) { item in
                        HStack(spacing: 4) {
                            ItemIconView(item: item, size: 16)
                            Text(item.displayName)
                                .font(.caption2)
                                .foregroundStyle(GardenPalette.inkMuted)
                        }
                    }
                }
            }

            if enemy.isAvailable && combatLevel >= enemy.requiredCombatLevel {
                Button("Fight", action: onFight)
                    .buttonStyle(.borderedProminent)
                    .tint(GardenPalette.moss)
                    .disabled(!canFight)
                if let blockReason, !canFight {
                    Text(blockReason)
                        .font(.caption2)
                        .foregroundStyle(GardenPalette.inkMuted)
                }
            } else {
                Label("Requires Combat Level \(enemy.requiredCombatLevel)", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GardenPalette.inkMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.12), in: Capsule())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(combatLevel >= enemy.requiredCombatLevel ? 1 : 0.7)
    }
}
