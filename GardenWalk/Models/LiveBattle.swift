import Foundation

struct LiveBattle: Equatable {
    var enemy: EnemyDefinition
    var enemyHP: Int
    var playerHP: Int
    var maxPlayerHP: Int
    var message: String
    var magicXP: Int
    var usedMelee: Bool
    var rounds: Int
    var finished: Bool
    var victory: Bool
    var drops: [InventoryItemDrop]
    var lastEnemyDamage: Int
    var lastPlayerDamage: Int
}
