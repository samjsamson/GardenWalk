import Foundation
import SwiftData

@Model
final class SkillProgress {
    @Attribute(.unique) var skillKindRaw: String
    var totalXP: Int

    init(skillKind: SkillKind, totalXP: Int = 0) {
        self.skillKindRaw = skillKind.rawValue
        self.totalXP = totalXP
    }

    var skillKind: SkillKind {
        SkillKind(rawValue: skillKindRaw) ?? .mining
    }
}
