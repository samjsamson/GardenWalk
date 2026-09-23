import Foundation

enum MetalTier: String, CaseIterable, Identifiable {
    case bronze
    case iron
    case steel
    case mithril
    case adamant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bronze: "Bronze"
        case .iron: "Iron"
        case .steel: "Steel"
        case .mithril: "Mithril"
        case .adamant: "Adamant"
        }
    }

    var smithingLevel: Int {
        switch self {
        case .bronze: 1
        case .iron: 15
        case .steel: 30
        case .mithril: 50
        case .adamant: 70
        }
    }

    /// Attack requirement for weapons and Defense requirement for armor of this tier.
    var combatRequirement: Int {
        switch self {
        case .bronze, .iron: 1
        case .steel: 5
        case .mithril: 20
        case .adamant: 30
        }
    }

    var bar: InventoryItemID {
        switch self {
        case .bronze: .bronzeBar
        case .iron: .ironBar
        case .steel: .steelBar
        case .mithril: .mithrilBar
        case .adamant: .adamantBar
        }
    }

    var barSellValue: Int {
        switch self {
        case .bronze: 6
        case .iron: 12
        case .steel: 24
        case .mithril: 40
        case .adamant: 70
        }
    }

    var smeltXP: Int {
        switch self {
        case .bronze: 16
        case .iron: 30
        case .steel: 44
        case .mithril: 70
        case .adamant: 100
        }
    }

    var smithXPPerBar: Int {
        switch self {
        case .bronze: 16
        case .iron: 24
        case .steel: 32
        case .mithril: 44
        case .adamant: 60
        }
    }

    var smeltIngredients: [CraftingIngredient] {
        switch self {
        case .bronze:
            [
                CraftingIngredient(item: .copperOre, quantity: 1),
                CraftingIngredient(item: .tinOre, quantity: 1)
            ]
        case .iron:
            [CraftingIngredient(item: .ironOre, quantity: 1)]
        case .steel:
            [
                CraftingIngredient(item: .ironOre, quantity: 1),
                CraftingIngredient(item: .coal, quantity: 2)
            ]
        case .mithril:
            [
                CraftingIngredient(item: .mithrilOre, quantity: 1),
                CraftingIngredient(item: .coal, quantity: 4)
            ]
        case .adamant:
            [
                CraftingIngredient(item: .adamantOre, quantity: 1),
                CraftingIngredient(item: .coal, quantity: 6)
            ]
        }
    }
}

enum ArmorPiece: String, CaseIterable {
    case helmet
    case platebody
    case platelegs
    case shield

    var displayName: String {
        switch self {
        case .helmet: "Helmet"
        case .platebody: "Chestplate"
        case .platelegs: "Platelegs"
        case .shield: "Shield"
        }
    }

    var slot: EquipmentSlot {
        switch self {
        case .helmet: .helmet
        case .platebody: .chest
        case .platelegs: .legs
        case .shield: .shield
        }
    }

    var barCost: Int {
        switch self {
        case .helmet, .shield: 2
        case .platelegs: 3
        case .platebody: 5
        }
    }

    var visual: SmithingVisual {
        switch self {
        case .helmet: .helmet
        case .platebody: .platebody
        case .platelegs: .platelegs
        case .shield: .shield
        }
    }

    func defenseBonus(for tier: MetalTier) -> Int {
        switch (self, tier) {
        case (.helmet, .bronze): 3
        case (.helmet, .iron): 5
        case (.helmet, .steel): 8
        case (.helmet, .mithril): 12
        case (.helmet, .adamant): 18
        case (.shield, .bronze): 4
        case (.shield, .iron): 7
        case (.shield, .steel): 11
        case (.shield, .mithril): 16
        case (.shield, .adamant): 23
        case (.platelegs, .bronze): 5
        case (.platelegs, .iron): 8
        case (.platelegs, .steel): 13
        case (.platelegs, .mithril): 19
        case (.platelegs, .adamant): 27
        case (.platebody, .bronze): 8
        case (.platebody, .iron): 13
        case (.platebody, .steel): 20
        case (.platebody, .mithril): 30
        case (.platebody, .adamant): 42
        }
    }
}

enum SmithWeapon: String, CaseIterable {
    case dagger
    case sword
    case scimitar

    var displayName: String {
        switch self {
        case .dagger: "Dagger"
        case .sword: "Sword"
        case .scimitar: "Scimitar"
        }
    }

    /// OSRS attack interval in ticks. Lower is faster.
    var attackSpeed: Int {
        switch self {
        case .dagger, .scimitar: 4
        case .sword: 5
        }
    }

    var barCost: Int {
        switch self {
        case .dagger: 1
        case .sword, .scimitar: 2
        }
    }

    var visual: SmithingVisual {
        switch self {
        case .dagger: .dagger
        case .sword: .sword
        case .scimitar: .scimitar
        }
    }

    func attackBonus(for tier: MetalTier) -> Int {
        switch (self, tier) {
        case (.dagger, .bronze): 6
        case (.dagger, .iron): 9
        case (.dagger, .steel): 12
        case (.dagger, .mithril): 17
        case (.dagger, .adamant): 23
        case (.scimitar, .bronze): 8
        case (.scimitar, .iron): 11
        case (.scimitar, .steel): 15
        case (.scimitar, .mithril): 21
        case (.scimitar, .adamant): 28
        case (.sword, .bronze): 9
        case (.sword, .iron): 13
        case (.sword, .steel): 18
        case (.sword, .mithril): 25
        case (.sword, .adamant): 33
        }
    }

    func strengthBonus(for tier: MetalTier) -> Int {
        switch (self, tier) {
        case (.dagger, .bronze): 4
        case (.dagger, .iron): 6
        case (.dagger, .steel): 9
        case (.dagger, .mithril): 13
        case (.dagger, .adamant): 18
        case (.scimitar, .bronze): 6
        case (.scimitar, .iron): 8
        case (.scimitar, .steel): 12
        case (.scimitar, .mithril): 17
        case (.scimitar, .adamant): 23
        case (.sword, .bronze): 7
        case (.sword, .iron): 10
        case (.sword, .steel): 14
        case (.sword, .mithril): 20
        case (.sword, .adamant): 27
        }
    }
}

enum SmithTool: String, CaseIterable {
    case axe
    case pickaxe
    case fishingRod

    var displayName: String {
        switch self {
        case .axe: "Axe"
        case .pickaxe: "Pickaxe"
        case .fishingRod: "Fishing Rod"
        }
    }

    var slot: EquipmentSlot {
        switch self {
        case .axe: .axe
        case .pickaxe: .pickaxe
        case .fishingRod: .fishingRod
        }
    }

    var skill: SkillKind {
        switch self {
        case .axe: .woodcutting
        case .pickaxe: .mining
        case .fishingRod: .fishing
        }
    }

    var visual: SmithingVisual {
        switch self {
        case .axe: .axe
        case .pickaxe: .pickaxe
        case .fishingRod: .fishingRod
        }
    }

    var barCost: Int {
        switch self {
        case .axe, .pickaxe: 2
        case .fishingRod: 1
        }
    }

    func yieldBonus(for tier: MetalTier) -> Double {
        switch tier {
        case .bronze: 0.15
        case .iron: 0.20
        case .steel: 0.25
        case .mithril: 0.30
        case .adamant: 0.35
        }
    }
}

enum SmithingVisual {
    case ore
    case bar
    case hammer
    case leather
    case helmet
    case platebody
    case platelegs
    case shield
    case boots
    case dagger
    case sword
    case scimitar
    case axe
    case pickaxe
    case fishingRod
}

struct SmithingItemRecord: Equatable {
    let item: InventoryItemID
    let name: String
    let summary: String
    let effect: String
    let sellValue: Int
    let visual: SmithingVisual
    let tier: MetalTier?
    let tierName: String?
    let slot: EquipmentSlot?
    let requiredSkill: SkillKind?
    let requiredLevel: Int?
    let defenseBonus: Int
    let attackBonus: Int
    let strengthBonus: Int
    let bar: InventoryItemID?
    let barCost: Int?
    let smithingLevel: Int?
    let smithingXP: Int?
    let attackSpeed: Int?
    let weaponKind: String?
    var workerYieldBonus: Double = 0
    var workerSkill: SkillKind? = nil

    var requirementText: String? {
        guard let requiredSkill, let requiredLevel else { return nil }
        return "\(requiredSkill.displayName) \(requiredLevel)"
    }

    var statsText: String? {
        var parts: [String] = []
        if defenseBonus > 0 { parts.append("Defense Bonus +\(defenseBonus)") }
        if attackBonus > 0 { parts.append("Attack Bonus +\(attackBonus)") }
        if strengthBonus > 0 { parts.append("Strength Bonus +\(strengthBonus)") }
        if workerYieldBonus > 0, let workerSkill {
            let percent = Int((workerYieldBonus * 100).rounded())
            parts.append("\(workerSkill.displayName) Bonus +\(percent)%")
        }
        if let attackSpeed, let weaponKind {
            parts.append("\(weaponKind) · \(CombatDamage.attackIntervalLabel(ticks: attackSpeed))")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

struct SmeltingRecipe: Identifiable, Equatable {
    let id: String
    let output: InventoryItemID
    let outputQuantity: Int
    let ingredients: [CraftingIngredient]
    let requiredSmithingLevel: Int
    let xpReward: Int
    let tier: MetalTier

    var materialsDescription: String {
        ingredients
            .map { "\($0.quantity) \($0.item.displayName)" }
            .joined(separator: " + ")
    }
}

struct SmithingRecipe: Identifiable, Equatable {
    let id: String
    let output: InventoryItemID
    let bar: InventoryItemID
    let barsRequired: Int
    let requiredSmithingLevel: Int
    let xpReward: Int
    let tier: MetalTier

    var statsText: String {
        SmithingCatalog.record(for: output)?.statsText ?? ""
    }
}

enum SmithingCatalog {
    static let records: [SmithingItemRecord] = makeRecords()
    static let byItem: [InventoryItemID: SmithingItemRecord] = Dictionary(uniqueKeysWithValues: records.map { ($0.item, $0) })

    static let smelting: [SmeltingRecipe] = MetalTier.allCases.map { tier in
        SmeltingRecipe(
            id: "smelt-\(tier.rawValue)",
            output: tier.bar,
            outputQuantity: 1,
            ingredients: tier.smeltIngredients,
            requiredSmithingLevel: tier.smithingLevel,
            xpReward: tier.smeltXP,
            tier: tier
        )
    }

    static let smithing: [SmithingRecipe] = records.compactMap { record in
        guard let bar = record.bar, let bars = record.barCost, let level = record.smithingLevel, let xp = record.smithingXP, let tier = record.tier else {
            return nil
        }
        return SmithingRecipe(
            id: "smith-\(record.item.rawValue)",
            output: record.item,
            bar: bar,
            barsRequired: bars,
            requiredSmithingLevel: level,
            xpReward: xp,
            tier: tier
        )
    }

    static func record(for item: InventoryItemID) -> SmithingItemRecord? {
        byItem[item]
    }

    static func displayName(for item: InventoryItemID) -> String? {
        byItem[item]?.name
    }

    static func smeltingRecipe(id: String) -> SmeltingRecipe? {
        smelting.first { $0.id == id }
    }

    static func smithingRecipes(in tier: MetalTier) -> [SmithingRecipe] {
        smithing.filter { $0.tier == tier }
    }

    static func equipmentDefinitions() -> [EquippableItemDefinition] {
        records.compactMap { record in
            guard let slot = record.slot else { return nil }
            return EquippableItemDefinition(
                item: record.item,
                slot: slot,
                bonuses: EquipmentBonuses(
                    attack: record.attackBonus,
                    defense: record.defenseBonus,
                    strength: record.strengthBonus,
                    requiredLevel: record.requiredLevel,
                    requiredSkill: record.requiredSkill,
                    workerYieldBonus: record.workerYieldBonus,
                    workerSkill: record.workerSkill,
                    attackSpeed: record.attackSpeed,
                    weaponKind: record.weaponKind
                )
            )
        }
    }

    private static func makeRecords() -> [SmithingItemRecord] {
        var records: [SmithingItemRecord] = []
        records.append(contentsOf: materialRecords())
        for tier in MetalTier.allCases {
            for piece in ArmorPiece.allCases {
                records.append(armorRecord(tier, piece))
            }
            for weapon in SmithWeapon.allCases {
                records.append(weaponRecord(tier, weapon))
            }
            for tool in SmithTool.allCases {
                records.append(toolRecord(tier, tool))
            }
            if tier == .mithril || tier == .adamant {
                records.append(metalBootRecord(tier))
            }
        }
        records.append(contentsOf: leatherBootRecords())
        return records
    }

    private static func materialRecords() -> [SmithingItemRecord] {
        [
            material(.mithrilOre, name: "Mithril Ore", summary: "A blue ore found deeper in Mining.", effect: "Smelt with coal at the furnace to make a mithril bar.", sell: 18, visual: .ore, tier: .mithril),
            material(.adamantOre, name: "Adamant Ore", summary: "A green ore from the deepest rocks.", effect: "Smelt with coal at the furnace to make an adamant bar.", sell: 36, visual: .ore, tier: .adamant),
            material(.bronzeBar, name: "Bronze Bar", summary: "Smelted from copper and tin.", effect: "Used at the anvil to smith bronze equipment.", sell: MetalTier.bronze.barSellValue, visual: .bar, tier: .bronze),
            material(.ironBar, name: "Iron Bar", summary: "Smelted from iron ore.", effect: "Used at the anvil to smith iron equipment.", sell: MetalTier.iron.barSellValue, visual: .bar, tier: .iron),
            material(.steelBar, name: "Steel Bar", summary: "Smelted from iron ore and coal.", effect: "Used at the anvil to smith steel equipment.", sell: MetalTier.steel.barSellValue, visual: .bar, tier: .steel),
            material(.mithrilBar, name: "Mithril Bar", summary: "Smelted from mithril ore and coal.", effect: "Used at the anvil to smith mithril equipment.", sell: MetalTier.mithril.barSellValue, visual: .bar, tier: .mithril),
            material(.adamantBar, name: "Adamant Bar", summary: "Smelted from adamant ore and coal.", effect: "Used at the anvil to smith adamant equipment.", sell: MetalTier.adamant.barSellValue, visual: .bar, tier: .adamant),
            material(.leather, name: "Leather", summary: "Tanned hide used for boots.", effect: "Craft leather boots, or sell it at the General Store.", sell: 2, visual: .leather, tier: nil)
        ]
    }

    private static func material(
        _ item: InventoryItemID,
        name: String,
        summary: String,
        effect: String,
        sell: Int,
        visual: SmithingVisual,
        tier: MetalTier?
    ) -> SmithingItemRecord {
        SmithingItemRecord(
            item: item,
            name: name,
            summary: summary,
            effect: effect,
            sellValue: sell,
            visual: visual,
            tier: tier,
            tierName: tier?.displayName,
            slot: nil,
            requiredSkill: nil,
            requiredLevel: nil,
            defenseBonus: 0,
            attackBonus: 0,
            strengthBonus: 0,
            bar: nil,
            barCost: nil,
            smithingLevel: nil,
            smithingXP: nil,
            attackSpeed: nil,
            weaponKind: nil
        )
    }

    private static func armorRecord(_ tier: MetalTier, _ piece: ArmorPiece) -> SmithingItemRecord {
        let defense = piece.defenseBonus(for: tier)
        let bars = piece.barCost
        return gear(
            item: armorItem(tier, piece),
            name: "\(tier.displayName) \(piece.displayName)",
            summary: "\(tier.displayName) armor worn in the \(piece.slot.displayName) slot.",
            effect: "Defense +\(defense). Requires Defense \(tier.combatRequirement).",
            sell: gearSellValue(tier: tier, bars: bars),
            visual: piece.visual,
            tier: tier,
            slot: piece.slot,
            requiredSkill: .defense,
            requiredLevel: tier.combatRequirement,
            defense: defense,
            attack: 0,
            strength: 0,
            bars: bars
        )
    }

    private static func weaponRecord(_ tier: MetalTier, _ weapon: SmithWeapon) -> SmithingItemRecord {
        let attack = weapon.attackBonus(for: tier)
        let strength = weapon.strengthBonus(for: tier)
        let bars = weapon.barCost
        return gear(
            item: weaponItem(tier, weapon),
            name: "\(tier.displayName) \(weapon.displayName)",
            summary: "A \(tier.displayName.lowercased()) melee weapon.",
            effect: weaponEffect(weapon, attack: attack, strength: strength, tier: tier),
            sell: gearSellValue(tier: tier, bars: bars),
            visual: weapon.visual,
            tier: tier,
            slot: .weapon,
            requiredSkill: .attack,
            requiredLevel: tier.combatRequirement,
            defense: 0,
            attack: attack,
            strength: strength,
            bars: bars,
            attackSpeed: weapon.attackSpeed,
            weaponKind: weapon.displayName
        )
    }

    private static func toolRecord(_ tier: MetalTier, _ tool: SmithTool) -> SmithingItemRecord {
        let bars = tool.barCost
        let yield = tool.yieldBonus(for: tier)
        let percent = Int((yield * 100).rounded())
        return gear(
            item: toolItem(tier, tool),
            name: "\(tier.displayName) \(tool.displayName)",
            summary: "A \(tier.displayName.lowercased()) \(tool.displayName.lowercased()) for \(tool.skill.displayName.lowercased()).",
            effect: "\(tool.skill.displayName) Bonus +\(percent)%. Equip in the \(tool.slot.displayName) slot.",
            sell: gearSellValue(tier: tier, bars: bars),
            visual: tool.visual,
            tier: tier,
            slot: tool.slot,
            requiredSkill: nil,
            requiredLevel: nil,
            defense: 0,
            attack: 0,
            strength: 0,
            bars: bars,
            workerYieldBonus: yield,
            workerSkill: tool.skill
        )
    }

    private static func weaponEffect(_ weapon: SmithWeapon, attack: Int, strength: Int, tier: MetalTier) -> String {
        let interval = CombatDamage.attackIntervalLabel(ticks: weapon.attackSpeed)
        let rhythm = weapon.attackSpeed <= 4
            ? "It strikes twice before the enemy answers. The second strike deals half damage."
            : "It strikes once, then the enemy answers."
        return "\(weapon.displayName). Attack Bonus +\(attack), Strength Bonus +\(strength). Attack Speed \(interval). \(rhythm) Requires Attack \(tier.combatRequirement)."
    }

    private static func metalBootRecord(_ tier: MetalTier) -> SmithingItemRecord {
        let defense = tier == .mithril ? 7 : 11
        return gear(
            item: tier == .mithril ? .mithrilBoots : .adamantBoots,
            name: "\(tier.displayName) Boots",
            summary: "Metal boots smithed at the anvil.",
            effect: "Defense +\(defense). Requires Defense \(tier.combatRequirement).",
            sell: gearSellValue(tier: tier, bars: 1),
            visual: .boots,
            tier: tier,
            slot: .boots,
            requiredSkill: .defense,
            requiredLevel: tier.combatRequirement,
            defense: defense,
            attack: 0,
            strength: 0,
            bars: 1
        )
    }

    private static func leatherBootRecords() -> [SmithingItemRecord] {
        [
            boot(.leatherBoots, name: "Leather Boots", summary: "Soft boots for a first adventure.", defense: 1, required: 1, sell: 3),
            boot(.hardLeatherBoots, name: "Hard Leather Boots", summary: "Stiffer leather with a little more protection.", defense: 2, required: 1, sell: 6),
            boot(.studdedBoots, name: "Studded Boots", summary: "Leather boots reinforced with bronze studs.", defense: 4, required: 5, sell: 12)
        ]
    }

    private static func boot(
        _ item: InventoryItemID,
        name: String,
        summary: String,
        defense: Int,
        required: Int,
        sell: Int
    ) -> SmithingItemRecord {
        SmithingItemRecord(
            item: item,
            name: name,
            summary: summary,
            effect: "Defense +\(defense). Requires Defense \(required).",
            sellValue: sell,
            visual: .boots,
            tier: nil,
            tierName: "Leather",
            slot: .boots,
            requiredSkill: .defense,
            requiredLevel: required,
            defenseBonus: defense,
            attackBonus: 0,
            strengthBonus: 0,
            bar: nil,
            barCost: nil,
            smithingLevel: nil,
            smithingXP: nil,
            attackSpeed: nil,
            weaponKind: nil
        )
    }

    private static func gear(
        item: InventoryItemID,
        name: String,
        summary: String,
        effect: String,
        sell: Int,
        visual: SmithingVisual,
        tier: MetalTier,
        slot: EquipmentSlot,
        requiredSkill: SkillKind?,
        requiredLevel: Int?,
        defense: Int,
        attack: Int,
        strength: Int,
        bars: Int,
        attackSpeed: Int? = nil,
        weaponKind: String? = nil,
        workerYieldBonus: Double = 0,
        workerSkill: SkillKind? = nil
    ) -> SmithingItemRecord {
        SmithingItemRecord(
            item: item,
            name: name,
            summary: summary,
            effect: effect,
            sellValue: sell,
            visual: visual,
            tier: tier,
            tierName: tier.displayName,
            slot: slot,
            requiredSkill: requiredSkill,
            requiredLevel: requiredLevel,
            defenseBonus: defense,
            attackBonus: attack,
            strengthBonus: strength,
            bar: tier.bar,
            barCost: bars,
            smithingLevel: tier.smithingLevel,
            smithingXP: bars * tier.smithXPPerBar,
            attackSpeed: attackSpeed,
            weaponKind: weaponKind,
            workerYieldBonus: workerYieldBonus,
            workerSkill: workerSkill
        )
    }

    private static func gearSellValue(tier: MetalTier, bars: Int) -> Int {
        max(2, tier.barSellValue * bars * 2 / 3)
    }

    private static func armorItem(_ tier: MetalTier, _ piece: ArmorPiece) -> InventoryItemID {
        switch (tier, piece) {
        case (.bronze, .helmet): .bronzeHelmet
        case (.bronze, .platebody): .bronzePlatebody
        case (.bronze, .platelegs): .bronzePlatelegs
        case (.bronze, .shield): .bronzeShield
        case (.iron, .helmet): .ironHelmet
        case (.iron, .platebody): .ironPlatebody
        case (.iron, .platelegs): .ironPlatelegs
        case (.iron, .shield): .ironShield
        case (.steel, .helmet): .steelHelmet
        case (.steel, .platebody): .steelPlatebody
        case (.steel, .platelegs): .steelPlatelegs
        case (.steel, .shield): .steelShield
        case (.mithril, .helmet): .mithrilHelmet
        case (.mithril, .platebody): .mithrilPlatebody
        case (.mithril, .platelegs): .mithrilPlatelegs
        case (.mithril, .shield): .mithrilShield
        case (.adamant, .helmet): .adamantHelmet
        case (.adamant, .platebody): .adamantPlatebody
        case (.adamant, .platelegs): .adamantPlatelegs
        case (.adamant, .shield): .adamantShield
        }
    }

    private static func weaponItem(_ tier: MetalTier, _ weapon: SmithWeapon) -> InventoryItemID {
        switch (tier, weapon) {
        case (.bronze, .dagger): .bronzeDagger
        case (.bronze, .sword): .bronzeSword
        case (.bronze, .scimitar): .bronzeScimitar
        case (.iron, .dagger): .ironDagger
        case (.iron, .sword): .ironSword
        case (.iron, .scimitar): .ironScimitar
        case (.steel, .dagger): .steelDagger
        case (.steel, .sword): .steelSword
        case (.steel, .scimitar): .steelScimitar
        case (.mithril, .dagger): .mithrilDagger
        case (.mithril, .sword): .mithrilSword
        case (.mithril, .scimitar): .mithrilScimitar
        case (.adamant, .dagger): .adamantDagger
        case (.adamant, .sword): .adamantSword
        case (.adamant, .scimitar): .adamantScimitar
        }
    }

    private static func toolItem(_ tier: MetalTier, _ tool: SmithTool) -> InventoryItemID {
        switch (tier, tool) {
        case (.bronze, .axe): .bronzeAxe
        case (.bronze, .pickaxe): .bronzePickaxe
        case (.bronze, .fishingRod): .bronzeFishingRod
        case (.iron, .axe): .ironAxe
        case (.iron, .pickaxe): .ironPickaxe
        case (.iron, .fishingRod): .ironFishingRod
        case (.steel, .axe): .steelAxe
        case (.steel, .pickaxe): .steelPickaxe
        case (.steel, .fishingRod): .steelFishingRod
        case (.mithril, .axe): .mithrilAxe
        case (.mithril, .pickaxe): .mithrilPickaxe
        case (.mithril, .fishingRod): .mithrilFishingRod
        case (.adamant, .axe): .adamantAxe
        case (.adamant, .pickaxe): .adamantPickaxe
        case (.adamant, .fishingRod): .adamantFishingRod
        }
    }
}
