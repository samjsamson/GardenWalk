import Foundation

struct SkillLevelProgress: Equatable {
    let level: Int
    let xpIntoLevel: Int
    let xpForNextLevel: Int

    var progressFraction: Double {
        guard xpForNextLevel > 0 else { return 1 }
        return min(1, Double(xpIntoLevel) / Double(xpForNextLevel))
    }

    var isMaxLevel: Bool {
        level >= SkillProgressService.maxLevel
    }
}

enum SkillProgressService {
    static let maxLevel = 99

    /// Total XP required to reach `level` using the OSRS curve.
    /// Level 1 = 0 XP, level 2 = 83 XP, level 99 = 13,034,431 XP.
    static func totalXP(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }

        var points = 0.0
        for n in 1..<level {
            points += floor(Double(n) + 300.0 * pow(2.0, Double(n) / 7.0))
        }
        return Int(floor(points / 4.0))
    }

    static func level(forTotalXP xp: Int) -> Int {
        guard xp > 0 else { return 1 }
        for level in stride(from: maxLevel, through: 1, by: -1) {
            if xp >= totalXP(forLevel: level) {
                return level
            }
        }
        return 1
    }

    static func progress(forTotalXP xp: Int) -> SkillLevelProgress {
        let currentLevel = level(forTotalXP: xp)
        let xpAtCurrentLevel = totalXP(forLevel: currentLevel)

        if currentLevel >= maxLevel {
            return SkillLevelProgress(level: maxLevel, xpIntoLevel: 0, xpForNextLevel: 0)
        }

        let xpAtNextLevel = totalXP(forLevel: currentLevel + 1)
        return SkillLevelProgress(
            level: currentLevel,
            xpIntoLevel: xp - xpAtCurrentLevel,
            xpForNextLevel: xpAtNextLevel - xpAtCurrentLevel
        )
    }

    static func addXP(_ amount: Int, to skill: SkillProgress) {
        guard amount > 0 else { return }
        let cap = totalXP(forLevel: maxLevel + 1) - 1
        skill.totalXP = min(cap, skill.totalXP + amount)
    }
}
