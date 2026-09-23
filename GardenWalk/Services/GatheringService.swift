import Foundation

@MainActor
struct GatheringService {
    let rewardManager: RewardManager

    func performManualGather(
        resource: ResourceDefinition,
        inventory: InventoryService,
        using generator: inout some RandomNumberGenerator
    ) -> GatheringResult {
        var itemDrops: [InventoryItemDrop] = [
            InventoryItemDrop(item: resource.primaryOutput, amount: resource.primaryAmount)
        ]

        for secondary in resource.secondaryDrops {
            if Double.random(in: 0..<1, using: &generator) < secondary.chance {
                itemDrops.append(InventoryItemDrop(item: secondary.item, amount: secondary.amount))
            }
        }

        inventory.apply(drops: itemDrops)

        return GatheringResult(
            resource: resource,
            xpGained: resource.xpReward,
            itemDrops: itemDrops
        )
    }
}
