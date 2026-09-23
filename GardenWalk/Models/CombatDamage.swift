import Foundation

/// Shared melee combat math. Accuracy and damage are separate rolls.
enum CombatDamage {
    /// Player melee hit chance floor / ceiling. Early fights should usually connect.
    static let minHitChance = 0.72
    static let maxHitChance = 0.98
    /// OSRS tick length used to express attack speed in seconds.
    static let secondsPerTick: TimeInterval = 0.6

    /// Maximum melee hit before defense softens it.
    static func meleeMaxHit(
        attackLevel: Int,
        strengthLevel: Int,
        weaponAttack: Int,
        weaponStrength: Int,
        attackBoost: Int = 0,
        strengthBoost: Int = 0
    ) -> Int {
        let effective = max(1, attackLevel + attackBoost) + max(0, strengthLevel + strengthBoost) / 2 + 8
        let bonus = max(0, weaponAttack) + max(0, weaponStrength)
        // Tuned so early bronze gear deals a few damage, not splash zeroes.
        let hit = (effective * (bonus + 64)) / 400
        if hit <= 0, weaponAttack > 0 || attackLevel > 1 {
            return 1
        }
        return max(0, hit)
    }

    /// Chance to land a melee hit. Weak enemies are easy to hit.
    static func meleeHitChance(
        attackLevel: Int,
        weaponAttack: Int,
        enemyDefense: Int,
        attackBoost: Int = 0
    ) -> Double {
        let attack = Double(max(1, attackLevel + attackBoost))
        let bonus = Double(max(0, weaponAttack))
        let defense = Double(max(0, enemyDefense))
        let raw = 0.82 + attack * 0.008 + bonus * 0.006 - defense * 0.025
        return min(maxHitChance, max(minHitChance, raw))
    }

    /// Softens max hit by defense without wiping early hits to 0.
    static func damageAfterDefense(maxHit: Int, enemyDefense: Int) -> Int {
        guard maxHit > 0 else { return 0 }
        return max(1, maxHit - max(0, enemyDefense) / 3)
    }

    /// Attack interval in seconds from an OSRS-style tick speed (4 → 2.4s, 5 → 3.0s).
    static func attackIntervalSeconds(ticks: Int) -> TimeInterval {
        Double(max(1, ticks)) * secondsPerTick
    }

    static func attackIntervalLabel(ticks: Int) -> String {
        let seconds = attackIntervalSeconds(ticks: ticks)
        if seconds == floor(seconds) {
            return "\(Int(seconds))s"
        }
        return String(format: "%.1fs", seconds)
    }

    /// One melee swing: accuracy first, then damage 1…max on a hit.
    static func resolveMeleeSwing(
        maxHit: Int,
        attackLevel: Int,
        weaponAttack: Int,
        enemyDefense: Int,
        attackBoost: Int = 0,
        using generator: inout some RandomNumberGenerator
    ) -> (hit: Bool, damage: Int) {
        let chance = meleeHitChance(
            attackLevel: attackLevel,
            weaponAttack: weaponAttack,
            enemyDefense: enemyDefense,
            attackBoost: attackBoost
        )
        guard Double.random(in: 0..<1, using: &generator) < chance else {
            return (false, 0)
        }
        let capped = damageAfterDefense(maxHit: maxHit, enemyDefense: enemyDefense)
        guard capped > 0 else {
            return (true, 0)
        }
        return (true, Int.random(in: 1...capped, using: &generator))
    }

    /// Creature hit chance against the player.
    static func creatureHitChance(creatureAttack: Int, playerDefense: Int) -> Double {
        let attack = Double(max(0, creatureAttack))
        let defense = Double(max(0, playerDefense))
        let raw = 0.62 + attack * 0.035 - defense * 0.02
        return min(0.90, max(0.28, raw))
    }

    /// Enemy swing: can miss; a landed hit rolls 0…max so splash zeroes are possible.
    static func resolveCreatureSwing(
        creatureAttack: Int,
        playerDefense: Int,
        using generator: inout some RandomNumberGenerator
    ) -> (hit: Bool, damage: Int) {
        let chance = creatureHitChance(creatureAttack: creatureAttack, playerDefense: playerDefense)
        guard Double.random(in: 0..<1, using: &generator) < chance else {
            return (false, 0)
        }
        let capped = max(0, creatureAttack - max(0, playerDefense) / 3)
        guard capped > 0 else {
            return (true, 0)
        }
        return (true, Int.random(in: 0...capped, using: &generator))
    }
}
