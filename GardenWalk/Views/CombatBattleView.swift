import SwiftUI

struct CombatBattleView: View {
    @Environment(GameController.self) private var game
    @Environment(AuthController.self) private var auth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let enemy: EnemyDefinition
    let onClose: () -> Void

    @State private var countdownText = "3"
    @State private var showCountdown = true
    @State private var playerHP = 1
    @State private var enemyHP = 1
    @State private var maxPlayerHP = 1
    @State private var maxEnemyHP = 1
    @State private var playerHit = false
    @State private var enemyHit = false
    @State private var damagePop: DamagePop?
    @State private var result: CombatResult?
    @State private var showLoot = false
    @State private var showDefeat = false
    @State private var countdownFinished = false
    @State private var choosing = false
    @State private var showSpells = false
    @State private var resolving = false
    @State private var message = ""
    @State private var magicXP = 0
    @State private var battleTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [GardenPalette.skyTop, GardenPalette.skyBottom, GardenPalette.cream],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                enemySide
                Spacer(minLength: 8)
                if choosing && !showLoot && !showDefeat {
                    commandPanel
                }
                Spacer(minLength: 8)
                playerSide
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)

            Ellipse()
                .fill(GardenPalette.moss.opacity(0.16))
                .frame(height: 70)
                .padding(.horizontal, 36)
                .offset(y: 20)
                .allowsHitTesting(false)

            if showCountdown {
                Text(countdownText)
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundStyle(GardenPalette.ink)
                    .shadow(color: .white.opacity(0.8), radius: 8)
                    .transition(.scale.combined(with: .opacity))
            }

            if showLoot, let result {
                CombatLootPopup(result: result, magicXP: magicXP, onClose: onClose)
            } else if showDefeat {
                CombatDefeatPopup(enemyName: enemy.name, magicXP: magicXP, onClose: onClose)
            }
        }
        .overlay(alignment: .topTrailing) {
            StatusHUD()
                .padding(.top, 12)
                .padding(.trailing, 16)
        }
        .interactiveDismissDisabled()
        .onAppear {
            if maxEnemyHP == 1 && enemy.health > 1 {
                maxPlayerHP = max(1, game.playerCombatHealth)
                maxEnemyHP = max(1, enemy.health)
                playerHP = min(maxPlayerHP, game.currentHitPoints)
                enemyHP = maxEnemyHP
            }
            guard battleTask == nil else { return }
            battleTask = Task { await playBattle() }
        }
    }

    private var enemySide: some View {
        HStack {
            Spacer(minLength: 24)
            VStack(alignment: .trailing, spacing: 8) {
                CombatantStatus(
                    name: enemy.name,
                    level: enemy.requiredCombatLevel,
                    currentHP: enemyHP,
                    maxHP: maxEnemyHP,
                    alignment: .trailing
                )
                Text(enemy.icon)
                    .font(.system(size: 78))
                    .scaleEffect(enemyHit ? 0.9 : 1)
                    .offset(x: enemyHit ? 8 : 0)
                    .overlay(alignment: .top) {
                        if let damagePop, damagePop.hitsPlayer == false {
                            FloatingDamageLabel(amount: damagePop.amount)
                        }
                    }
            }
        }
    }

    private var playerSide: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                CombatantStatus(
                    name: auth.currentUsername ?? "You",
                    level: game.combatLevel,
                    currentHP: playerHP,
                    maxHP: maxPlayerHP,
                    alignment: .leading
                )
                PlayerSilhouette(
                    helmet: game.equippedItem(in: .helmet),
                    chest: game.equippedItem(in: .chest),
                    legs: game.equippedItem(in: .legs),
                    boots: game.equippedItem(in: .boots),
                    weapon: game.equippedItem(in: .weapon),
                    shield: game.equippedItem(in: .shield),
                    skinTone: game.skinTone,
                    clothingTone: game.clothingTone
                )
                .scaleEffect(0.62)
                .frame(width: 120, height: 140)
                .scaleEffect(playerHit ? 0.94 : 1)
                .offset(x: playerHit ? -8 : 0)
                .overlay(alignment: .top) {
                    if let damagePop, damagePop.hitsPlayer {
                        FloatingDamageLabel(amount: damagePop.amount)
                    }
                }
            }
            Spacer(minLength: 24)
        }
    }

    private func playBattle() async {
        maxPlayerHP = max(1, game.playerCombatHealth)
        maxEnemyHP = max(1, enemy.health)
        if !countdownFinished {
            playerHP = min(maxPlayerHP, game.currentHitPoints)
            enemyHP = maxEnemyHP
            for beat in ["3", "2", "1", "Fight!"] {
                countdownText = beat
                try? await Task.sleep(for: .milliseconds(500))
                if Task.isCancelled { return }
            }
            countdownFinished = true
            withAnimation(.easeOut(duration: 0.2)) {
                showCountdown = false
            }
        }

        guard game.beginLiveBattle(enemy) else {
            onClose()
            return
        }
        message = game.liveBattle?.message ?? ""
        choosing = true
    }

    private var commandPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(GardenPalette.ink)
                    .lineLimit(2)
            }
            if showSpells {
                spellPanel
            } else {
                HStack(spacing: 12) {
                    Button {
                        strike()
                    } label: {
                        Text("Attack")
                            .font(.title3.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    Button {
                        showSpells = true
                    } label: {
                        Text("Magic")
                            .font(.title3.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(GardenPalette.moss)
                .controlSize(.large)
                .disabled(resolving)
            }
        }
        .padding(12)
        .frame(maxWidth: 360)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var spellPanel: some View {
        let spells = MagicCatalog.spells.filter { game.skillLevel(for: .magic) >= $0.requiredMagicLevel }
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Magic \(game.skillLevel(for: .magic))")
                    .font(.caption.weight(.bold))
                Spacer()
                Button("Back") { showSpells = false }
                    .font(.caption.weight(.semibold))
            }
            if spells.isEmpty {
                Text("Raise Magic to unlock a spell.")
                    .font(.caption2)
                    .foregroundStyle(GardenPalette.inkMuted)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(spells) { spell in
                        spellRow(spell)
                    }
                }
            }
            .frame(maxHeight: 176)
        }
    }

    private func spellRow(_ spell: SpellDefinition) -> some View {
        let missing = game.missingRunes(for: spell)
        let ready = missing.isEmpty && !resolving
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(spell.name)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("Magic \(spell.requiredMagicLevel)")
                    .font(.caption2)
                    .foregroundStyle(GardenPalette.inkMuted)
            }
            Text("Hit \(game.magicStrikePower(for: spell)) · \(spell.magicXP) Magic XP")
                .font(.caption2)
                .foregroundStyle(GardenPalette.inkMuted)
            Text(game.runeCostLine(for: spell))
                .font(.caption2.monospacedDigit())
            if !missing.isEmpty {
                Text("Missing \(missing.map { "\($0.quantity) \($0.item.displayName)" }.joined(separator: ", "))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.65, green: 0.16, blue: 0.14))
            }
            Button("Cast") { cast(spell) }
                .font(.caption.weight(.bold))
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(GardenPalette.moss)
                .disabled(!ready)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            missing.isEmpty ? GardenPalette.moss.opacity(0.08) : Color.gray.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    private func strike() {
        guard !resolving else { return }
        resolving = true
        showSpells = false
        game.liveMeleeStrike()
        battleTask = Task { await presentAction() }
    }

    private func cast(_ spell: SpellDefinition) {
        guard !resolving, game.canCast(spell) else { return }
        resolving = true
        showSpells = false
        game.liveCast(spell)
        battleTask = Task { await presentAction() }
    }

    private func presentAction() async {
        guard let battle = game.liveBattle else {
            resolving = false
            return
        }
        message = battle.message
        let hitDelay: Duration = reduceMotion ? .milliseconds(160) : .milliseconds(380)
        if battle.lastEnemyDamage > 0 {
            enemyHP = battle.enemyHP
            enemyHit = true
            damagePop = DamagePop(amount: battle.lastEnemyDamage, hitsPlayer: false)
            try? await Task.sleep(for: hitDelay)
            enemyHit = false
        }
        if battle.lastPlayerDamage > 0 {
            playerHP = max(0, battle.playerHP)
            playerHit = true
            damagePop = DamagePop(amount: battle.lastPlayerDamage, hitsPlayer: true)
            try? await Task.sleep(for: hitDelay)
            playerHit = false
        }
        if battle.finished {
            magicXP = battle.magicXP
            result = game.lastCombatResult
            choosing = false
            showSpells = false
            if battle.victory {
                playerHP = max(1, battle.playerHP)
                enemyHP = 0
                showLoot = true
            } else {
                playerHP = 0
                showDefeat = true
            }
        }
        resolving = false
    }
}

private struct DamagePop: Identifiable {
    let id = UUID()
    let amount: Int
    let hitsPlayer: Bool
}

private struct CombatantStatus: View {
    let name: String
    let level: Int
    let currentHP: Int
    let maxHP: Int
    let alignment: HorizontalAlignment

    private var fraction: Double {
        guard maxHP > 0 else { return 0 }
        return min(1, max(0, Double(currentHP) / Double(maxHP)))
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(name)
                .font(.headline)
            Text("Lv \(level)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GardenPalette.inkMuted)
            CombatHealthBar(fraction: fraction)
                .frame(width: 150, height: 12)
            Text("\(max(0, currentHP)) / \(maxHP) HP")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(GardenPalette.ink)
        }
        .padding(10)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct CombatHealthBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.12))
                Capsule()
                    .fill(fraction > 0.35 ? GardenPalette.leaf : Color(red: 0.75, green: 0.22, blue: 0.18))
                    .frame(width: max(0, geo.size.width * fraction))
            }
        }
        .animation(.easeOut(duration: 0.3), value: fraction)
    }
}

private struct FloatingDamageLabel: View {
    let amount: Int
    @State private var rise = false

    var body: some View {
        Text("-\(amount)")
            .font(.title2.bold())
            .foregroundStyle(Color(red: 0.72, green: 0.12, blue: 0.1))
            .shadow(color: .white, radius: 2)
            .offset(y: rise ? -28 : 0)
            .opacity(rise ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) { rise = true }
            }
            .allowsHitTesting(false)
    }
}

private struct CombatLootPopup: View {
    let result: CombatResult
    var magicXP: Int = 0
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 12) {
                Text("Victory!")
                    .font(.title2.bold())
                    .foregroundStyle(GardenPalette.moss)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Loot")
                    .font(.headline)
                if result.drops.isEmpty {
                    Text("No items this time.")
                        .font(.subheadline)
                        .foregroundStyle(GardenPalette.inkMuted)
                } else {
                    ForEach(result.drops) { drop in
                        ItemDropLabel(drop: drop)
                    }
                }
                Text("\(result.xpGained) Combat XP")
                    .font(.subheadline.weight(.semibold))
                if magicXP > 0 {
                    Text("\(magicXP) Magic XP")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GardenPalette.moss)
                }
                Button("Continue", action: onClose)
                    .buttonStyle(.borderedProminent)
                    .tint(GardenPalette.moss)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(24)
        }
    }
}

private struct CombatDefeatPopup: View {
    let enemyName: String
    var magicXP: Int = 0
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Defeat")
                    .font(.title2.bold())
                    .foregroundStyle(Color(red: 0.65, green: 0.16, blue: 0.14))
                Text("You were defeated by a \(enemyName). You return safely.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GardenPalette.ink)
                if magicXP > 0 {
                    Text("You keep \(magicXP) Magic XP from spells you cast.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(GardenPalette.moss)
                }
                Button("Return", action: onClose)
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
