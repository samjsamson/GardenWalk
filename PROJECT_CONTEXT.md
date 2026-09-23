# GardenWalk — Project Context

Native iOS resource-gathering / idle-progression game built with **Swift**, **SwiftUI**, and **SwiftData**. Originally conceived as a walking-rewards app; now a self-contained gathering, crafting, worker-automation, and combat game. The product name in Xcode is **GardenWalk** (user may refer to it as Oak & Ore).

**Target:** iOS 17+ · **Bundle ID:** `com.gardenwalk.GardenWalk`

---

## Architecture Overview

Modular, data-driven design. Game logic lives in **services** and **catalog enums**; persistence in **SwiftData @Model** types; UI in **SwiftUI views**. A single `@Observable` **`GameController`** orchestrates everything and is injected via `.environment(game)`.

```
GardenWalkApp
  └─ RootView → AuthController (local account) → GameController(modelContext)
       └─ AppTabView (4 tabs)
            ├─ HomeView      (store, crafting, combat link)
            ├─ InventoryView (stackable items, equip weapons)
            ├─ ResourcesView (manual gather + worker assign)
            └─ ProfileView   (skill stats)
```

**State refresh pattern:** `GameController.stateVersion` increments on save; views read `let _ = game.stateVersion` to re-render. Background timers (workers, combat cooldown) also bump `stateVersion` every second when active.

---

## Implemented Systems

### 1. Skills (OSRS XP curve)
- **Mining**, **Woodcutting**, **Farming**, **Smithing** — levels 1–99
- XP formula implemented in `SkillProgressService` (not hardcoded table)
- Level 2 = 83 total XP; level 99 = 13,034,431 total XP
- XP earned from manual gathering and worker production

### 2. Inventory (stackable items)
- Extensible `InventoryItemID` enum + SwiftData `InventoryEntry` (one row per item type, quantity stack)
- `InventoryService` handles add/remove/apply-drops
- New players start with **20 Gold**

### 3. Resource gathering
- Three spots on **Resources** tab: Mining Spot, Tree Plot, Garden Spot
- Data-driven `ResourceDefinition` in `ResourceCatalog`
- **Playable now:** Copper Ore (Mining 1, 40% Stone), Tin Ore (Mining 5), Iron Ore (Mining 10), Silver Ore (Mining 20), Oak (wood/branch), Willow (Woodcutting 20, wood), Apple Tree (apples/seeds)
- **Locked until content is wired:** Maple (Woodcutting 35), Rose Bush (Farming 25), Raspberries (Farming 40). They show "Requires Level X" and cannot be gathered yet
- Bronze is not mined. Bronze Bar is smelted from 1 Copper Ore + 1 Tin Ore
- Manual **Gather** requires the resource's `requiredLevel` in its skill. Under-level nodes show a short level label such as "Lv 5" instead of a Gather button
- Manual **Gather** → skill XP + primary output + optional secondary drops
- Chance-based **Loot Bag** / **Seed Pack** bonuses → animated full-screen reveal (`RewardRevealView`)

### 4. Workers
- Buy **Worker** for 10 Gold at General Store (`StoreCatalog`)
- Assign/remove workers per resource spot (counts stored in `WorkerPool`)
- Auto-production while app runs: **+1 resource / 30s / worker** + small skill XP
- Logic in `WorkerProductionService` (in-memory progress timers; not persisted)

### 5. Crafting
- Data-driven `CraftingRecipeDefinition` + `CraftingCatalog` + `CraftingService`
- Categories: **Tools**, **Smithing**, **Weapons**
- Recipes: Stone Axe, Stone Dagger, Copper Dagger (Smithing 1, +25 Smithing XP), Bronze Bar (1 Copper + 1 Tin, +20 Smithing XP), Bronze Dagger (1 Bronze Bar, Smithing 5, +40 Smithing XP)
- `requiredSkill` / `requiredSkillLevel` are enforced in `CraftingService.canCraft`
- Crafting XP is granted by `GameController.craft` from `skillXP` when `requiredSkill` is set
- Tree Branch dismantle: 1 branch → 5 wood (Inventory action)

### 6. General Store
- Extensible `StoreListing` / `StoreCatalog`
- Buy and sell. Sell prices live on `ItemCatalog` (`sellValue`); higher-tier ores sell for more
- Sells Worker (10), Apple Seed (2), Oak Sapling (4), Pickaxe (8), Basic Axe (8), Worker Rations (5), Torch (15), Mystery Crate (20), Backpack Upgrade (25, price scales with tier)
- Listings are data-driven (`StoreListing`: product, price, quantity, category, optional skill and prerequisite)
- Worker Rations: use from Inventory to make one assigned worker gather 25% faster for 10 minutes
- Mystery Crate: open from Inventory; rolls the shared drop table
- Backpack Upgrade: persists `inventoryCapacity` and `backpackTier` on `PlayerRecord` (capacity is not enforced yet)

### 7. Combat (MVP)
- Accessible from **Home → Combat** (`CombatView`)
- Data-driven `EnemyDefinition` / `EnemyCatalog` + reusable `DropTableEntry` / `DropTableService`
- **Rat** available (guaranteed win for testing); Cow, Skeleton, Pig, Goblin, Thief locked ("Coming Soon")
- Instant fight resolution via `CombatService` (player attack power vs enemy health+defense)
- **2-minute global cooldown** after victory, persisted in `PlayerCombatState.combatCooldownEndTimestamp`
- Equipment slots on Inventory (`EquipmentSlot`): Helmet, Chest, Legs, Boots, Weapon, Shield, Arrows. Daggers equip to Weapon. Attack power still comes from `EquipmentCatalog` (1/3/5/6/8)
- Equipped items stay in the inventory stack and show **Equipped**. Tapping a filled slot unequips it. One item per slot; a new equip replaces the previous one without changing quantities

### 8. Rewards / loot
- `RewardManager` opens seed packs and loot bags during gathering
- Combat uses generic drop tables rolled on victory

---

## SwiftData Models

| Model | Purpose |
|-------|---------|
| `SkillProgress` | Per-skill total XP (`skillKindRaw`, `totalXP`) |
| `InventoryEntry` | Stackable item quantity (`itemID`, `quantity`) |
| `WorkerPool` | Owned workers + per-spot assignment counts |
| `PlayerCombatState` | Equipped weapon + combat cooldown end timestamp |

Registered in `GardenWalkApp.modelContainer(for:)`.

---

## Key Catalogs (static data — add content here)

| File | Contents |
|------|----------|
| `InventoryItemID` | All item IDs, names, weapon flag |
| `ItemArt` / `ItemIconView` | Item categories, asset name or drawn glyph, material tints |
| `ResourceCatalog` | Resource nodes per spot (stats, drops, worker config) |
| `CraftingCatalog` | Crafting recipes by category |
| `StoreCatalog` | General Store listings |
| `EnemyCatalog` | Enemy stats, availability, drop tables |
| `WeaponCatalog` | Equippable weapons + attack power |
| `SkillKind` | Mining / Woodcutting / Farming metadata |

---

## Services

| Service | Role |
|---------|------|
| `GameController` | Central orchestrator; all player actions go through here |
| `InventoryService` | Read/write inventory stacks |
| `SkillProgressService` | OSRS XP curve, level/progress calculation |
| `GatheringService` | Manual resource gather + bonus loot rolls |
| `WorkerProductionService` | Timer-based worker output |
| `CraftingService` | Recipe validation + craft execution |
| `RewardManager` | Seed pack / loot bag contents |
| `CombatService` | Fight resolution |
| `DropTableService` | Generic drop-table rolling |

---

## Views

| View | Tab / Nav | Purpose |
|------|-----------|---------|
| `HomeView` | Home | Combat link, General Store, Crafting |
| `InventoryView` | Inventory | Item grid, equip weapons, dismantle branch |
| `ResourcesView` | Resources | Spot cards, gather, worker assign/remove |
| `ProfileView` | Profile | Skill stats (OSRS progress bars), overview |
| `CombatView` | Home → push | Enemy list, fight, cooldown, results |
| `RewardRevealView` | Modal | Seed pack / loot bag animation |
| `SkillStatRow` | Profile | Reusable skill XP bar component |
| `AppTabView` | Root tabs | Tab shell + reward fullScreenCover |

**Theme:** `GardenPalette` (moss, leaf, cream, sky gradients)

---

## Current Gameplay Loop

1. **Gather** manually on Resources (or assign Workers for passive income while app is open)
2. Earn **skill XP** and stack **resources** in Inventory
3. **Craft** tools/weapons on Home. Copper Dagger and Bronze Bar train **Smithing**; Bronze Dagger requires Smithing 5
4. **Equip** a weapon in Inventory (Bronze Dagger is 6 attack)
5. **Fight** Rat on Combat screen → earn Gold / loot → 2-min cooldown
6. Spend **Gold** on Workers → assign to spots → accelerate resource generation
7. Bonus **Seed Packs** / **Loot Bags** from gathering trigger reveal animations

---

## Inventory Items (current)

Gold, Copper Ore, Tin Ore, Iron Ore, Silver Ore, Wood, Tree Branch, Apple, Apple Seed, Oak Sapling, Stone, Loot Bag, Seed Pack, Mystery Crate, Stone Axe, Pickaxe, Basic Axe, Worker Rations, Torch, Stone Dagger, Copper Dagger, Bronze Bar, Bronze Dagger, Milk, Cow Meat, Bones, Pork Meat, Steel Dagger

*(Milk/Cow Meat/Bones/Pork Meat/Steel Dagger are defined for future enemy drops; only Rat combat + gathering sources are live.)*

---

## Important Conventions

- **Add new items:** extend `InventoryItemID` (display name) and `ItemArtCatalog` (category, asset name or glyph, tints)
- **Add new resources:** add `ResourceDefinition` to `ResourceCatalog`, set `isPlayable`
- **Add new recipes:** add to `CraftingCatalog.all`
- **Add new enemies:** add to `EnemyCatalog.all`, set `isAvailable`
- **Add store items:** add to `StoreCatalog.all`, handle purchase in `GameController.purchase`
- **Do not hardcode** per-item UI buttons for crafting/combat — use catalog iteration
- SwiftData schema changes may require **delete/reinstall** on device/simulator during development

---

## Removed / Legacy (do not reintroduce)

- HealthKit / step tracking / daily milestones
- Decorative Garden / plant Collection (`OwnedItem`, rarity-based plant cards)
- Old `PlayerProfile`, `DailyMilestoneRecord`, `ResourceInventory` flat fields

---

## Planned / Not Yet Implemented

Structured in data models but not fully wired:

- **Resources:** Maple, Rose Bush, Raspberries (locked UI; outputs are still placeholders)
- **Workers** still produce the first playable node on a spot (Copper, Oak, Apple), not Tin or Willow
- **Combat:** Attack, Strength, Defense, Hitpoints, combat levels, armor, food/healing, enemy damage to player, turn-based combat, animations
- **Enemies:** Cow, Skeleton, Pig, Goblin, Thief unlock logic
- **Workers:** offline production, upgrades, faster intervals, multiple tiers
- **Equipment stats:** defense, ranged, armor values, level requirements, durability, set bonuses (slots and attack bonuses exist)
- **Iron weapons, swords, bows** crafting (Bronze Dagger is implemented)
- **Steel Dagger** crafting (currently Thief drop only)
- **Loot Bag / Seed Pack** as openable inventory items (currently auto-opened on gather bonus)
- **Gold economy** beyond Worker purchases
- **Boss fights**, rare drop tuning, enemy unlock requirements enforcement

---

## Build & Run

```bash
open GardenWalk.xcodeproj
# Select simulator/device, Cmd+R
# Or:
xcodebuild -project GardenWalk.xcodeproj -scheme GardenWalk \
  -destination 'generic/platform=iOS Simulator' build
```

Project uses Xcode **File System Synchronized Groups** (objectVersion 77) — new Swift files under `GardenWalk/` are picked up automatically.

---

## File Tree (logical)

```
GardenWalk/
├── GardenWalkApp.swift          # App entry, modelContainer, RootView
├── Models/
│   ├── InventoryItemID.swift
│   ├── InventoryEntry.swift
│   ├── SkillKind.swift / SkillProgress.swift
│   ├── ResourceSpotKind.swift / ResourceDefinition.swift
│   ├── WorkerPool.swift
│   ├── CraftingRecipeDefinition.swift
│   ├── StoreListing.swift       # + PendingReward, GatheringResult
│   ├── EnemyDefinition.swift
│   ├── DropTableEntry.swift
│   ├── WeaponDefinition.swift
│   └── PlayerCombatState.swift
├── Services/
│   ├── GameController.swift     # START HERE for game logic changes
│   ├── InventoryService.swift
│   ├── SkillProgressService.swift
│   ├── GatheringService.swift
│   ├── WorkerProductionService.swift
│   ├── CraftingService.swift
│   ├── RewardManager.swift
│   └── CombatService.swift
├── Views/
│   ├── AppTabView.swift
│   ├── HomeView.swift
│   ├── InventoryView.swift
│   ├── ResourcesView.swift
│   ├── ProfileView.swift
│   ├── CombatView.swift
│   ├── RewardRevealView.swift
│   ├── SkillStatRow.swift
│   └── ItemIconView.swift
└── Theme/
    ├── GardenPalette.swift
    └── ItemArt.swift
```

Item icons render through `ItemIconView`. Gold, the worker, axes, daggers, and the bronze bar use drawn sprites. Other items use a tinted symbol until an asset catalog image is set on `ItemArt.assetName`.

---

## Agent Handoff Tips

1. Read `GameController.swift` first — it is the integration point for all features.
2. Prefer extending **catalog enums** over adding one-off view logic.
3. Preserve existing visual style (`GardenPalette`, white rounded cards, moss accent).
4. Keep SwiftData persistence for anything that must survive app restarts (inventory, skills, workers, cooldown, equipped weapon).
5. Run `xcodebuild` after non-trivial changes; project currently **builds clean**.
