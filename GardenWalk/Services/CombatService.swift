import Foundation

enum CombatBalance {
    static let globalCooldownSeconds: TimeInterval = 120
}

@MainActor
struct CombatService {
    func canFight(_ enemy: EnemyDefinition, combatLevel: Int, isOnCooldown: Bool) -> Bool {
        enemy.isAvailable && combatLevel >= enemy.requiredCombatLevel && !isOnCooldown
    }

    func resolveFight<G: RandomNumberGenerator>(
        enemy: EnemyDefinition,
        playerAttackPower: Int,
        playerHealth: Int,
        playerDefense: Int,
        using generator: inout G
    ) -> CombatResult {
        // The player strikes first each round; a defeated enemy cannot retaliate.
        let damageDealt = CombatDamage.damageAfterDefense(
            maxHit: playerAttackPower,
            enemyDefense: enemy.defense
        )
        let damageTaken = CombatDamage.damageAfterDefense(
            maxHit: enemy.attack,
            enemyDefense: playerDefense
        )
        let roundsToWin = damageDealt > 0 ? max(1, (enemy.health + damageDealt - 1) / damageDealt) : Int.max
        let roundsToLose = damageTaken > 0 ? max(1, (playerHealth + damageTaken - 1) / damageTaken) : Int.max
        let victory = enemy.guaranteedVictory || (damageDealt > 0 && roundsToWin <= roundsToLose)
        let rounds = victory
            ? (enemy.guaranteedVictory && damageDealt == 0 ? 1 : min(roundsToWin, 50))
            : min(roundsToLose == Int.max ? 1 : roundsToLose, 50)
        let playback = Self.playback(
            rounds: rounds,
            victory: victory,
            playerHealth: playerHealth,
            enemyHealth: enemy.health,
            damageDealt: damageDealt,
            damageTaken: damageTaken
        )

        var drops: [InventoryItemDrop] = []
        if victory {
            drops = DropTableService.rollDrops(from: enemy.dropTable, using: &generator)
        }

        return CombatResult(
            enemy: enemy,
            victory: victory,
            playerAttackPower: playerAttackPower,
            xpGained: victory ? enemy.combatXP : 0,
            rounds: rounds,
            remainingHealth: playback.remainingHealth,
            drops: drops,
            blows: playback.blows
        )
    }

    /// Player strikes first. A blow that drops either side to 0 HP ends the fight.
    private static func playback(
        rounds: Int,
        victory: Bool,
        playerHealth: Int,
        enemyHealth: Int,
        damageDealt: Int,
        damageTaken: Int
    ) -> (blows: [CombatBlow], remainingHealth: Int) {
        var playerHP = max(0, playerHealth)
        var enemyHP = max(0, enemyHealth)
        var blows: [CombatBlow] = []
        var nextID = 0

        for _ in 1...max(rounds, 1) {
            if enemyHP <= 0 || playerHP <= 0 { break }

            let strike = damageDealt > 0 ? damageDealt : (victory ? enemyHP : 0)
            let dealt = min(strike, enemyHP)
            enemyHP -= dealt
            blows.append(CombatBlow(id: nextID, target: .enemy, damage: dealt, healthAfter: enemyHP))
            nextID += 1
            if enemyHP <= 0 { break }

            let taken = min(damageTaken, victory ? playerHP - 1 : playerHP)
            guard taken > 0 else { continue }
            playerHP -= taken
            blows.append(CombatBlow(id: nextID, target: .player, damage: taken, healthAfter: playerHP))
            nextID += 1
            if playerHP <= 0 { break }
        }

        let remainingHealth = victory ? max(1, playerHP) : 0
        return (blows, remainingHealth)
    }
}
