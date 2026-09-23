import Foundation

struct WorkerNodePlan: Equatable {
    let key: String
    let resource: ResourceDefinition
    let yieldBonus: Double
}

struct WorkerSpotPlan: Equatable {
    let spot: ResourceSpotKind
    let interval: TimeInterval
    let nodes: [WorkerNodePlan]
}

struct WorkerNodeContribution: Equatable {
    let resource: ResourceDefinition
    let nodeCount: Int
}

struct WorkerProductionTickResult: Equatable {
    let spot: ResourceSpotKind
    let contributions: [WorkerNodeContribution]
    let cyclesCompleted: Int
    let itemDrops: [InventoryItemDrop]
    let xpGained: Int
}

struct WorkerSpeedBoost {
    /// Extra output per completed cycle for each boosted worker. `0.25` is 25% faster.
    var bonusPerWorker: Double
    var workerCount: Int
    var remainder: Double
}

struct WorkerProductionService {
    func tick(
        delta: TimeInterval,
        plans: [WorkerSpotPlan],
        progress: inout [ResourceSpotKind: TimeInterval],
        yieldRemainders: inout [String: Double],
        speedBoost: inout WorkerSpeedBoost?,
        remainingCapacity: inout Int
    ) -> [WorkerProductionTickResult] {
        var results: [WorkerProductionTickResult] = []
        var didApplyBoost = false
        let plannedSpots = Set(plans.map(\.spot))

        for spot in ResourceSpotKind.allCases where !plannedSpots.contains(spot) {
            progress[spot] = 0
        }

        for plan in plans {
            guard !plan.nodes.isEmpty else {
                progress[plan.spot] = 0
                continue
            }
            guard remainingCapacity > 0 else { continue }

            let interval = max(plan.interval, 0.001)
            let elapsed = (progress[plan.spot] ?? 0) + delta
            let availableCycles = Int(elapsed / interval)
            guard availableCycles > 0 else {
                progress[plan.spot] = elapsed
                continue
            }

            var cycles = 0
            var drops: [InventoryItemID: Int] = [:]
            var xp = 0
            var timeLeft = elapsed
            var stagedRemainders = yieldRemainders

            while cycles < availableCycles {
                var cycleDrops: [InventoryItemID: Int] = [:]
                var cycleOutput = 0
                var cycleXP = 0
                var cycleRemainders = stagedRemainders

                for node in plan.nodes {
                    let base = max(0, node.resource.workerOutputAmount)
                    let exact = Double(base) * (1 + max(0, node.yieldBonus)) + (cycleRemainders[node.key] ?? 0)
                    // Snap to thousandths so 20% of 1, five times, becomes 6 instead of 5.
                    let thousandths = Int((exact * 1000).rounded())
                    let whole = thousandths / 1000
                    cycleRemainders[node.key] = Double(thousandths % 1000) / 1000.0
                    if whole > 0 {
                        cycleDrops[node.resource.workerOutput, default: 0] += whole
                        cycleOutput += whole
                    }
                    cycleXP += node.resource.workerXP
                }

                var pendingBoostRemainder: Double?
                if speedBoost != nil, !didApplyBoost {
                    let boostedWorkers = min(speedBoost?.workerCount ?? 0, plan.nodes.count)
                    var remainder = speedBoost?.remainder ?? 0
                    let sampleAmount = max(1, plan.nodes[0].resource.workerOutputAmount)
                    remainder += (speedBoost?.bonusPerWorker ?? 0) * Double(boostedWorkers) * Double(sampleAmount)
                    let extra = Int(remainder)
                    remainder -= Double(extra)
                    pendingBoostRemainder = remainder
                    if extra > 0 {
                        cycleDrops[plan.nodes[0].resource.workerOutput, default: 0] += extra
                        cycleOutput += extra
                        cycleXP += extra * plan.nodes[0].resource.workerXP / sampleAmount
                    }
                }

                guard cycleOutput > 0, cycleOutput <= remainingCapacity else { break }

                if var boost = speedBoost, let pendingBoostRemainder, !didApplyBoost {
                    boost.remainder = pendingBoostRemainder
                    speedBoost = boost
                }

                stagedRemainders = cycleRemainders
                remainingCapacity -= cycleOutput
                for (item, amount) in cycleDrops {
                    drops[item, default: 0] += amount
                }
                xp += cycleXP
                cycles += 1
                timeLeft -= interval
            }

            if cycles > 0 {
                didApplyBoost = speedBoost != nil
                yieldRemainders = stagedRemainders
                progress[plan.spot] = cycles < availableCycles
                    ? min(timeLeft, interval - 0.001)
                    : timeLeft
                let grouped = Dictionary(grouping: plan.nodes, by: \.resource.id)
                results.append(
                    WorkerProductionTickResult(
                        spot: plan.spot,
                        contributions: grouped.values.map { nodes in
                            WorkerNodeContribution(resource: nodes[0].resource, nodeCount: nodes.count)
                        },
                        cyclesCompleted: cycles,
                        itemDrops: drops.map { InventoryItemDrop(item: $0.key, amount: $0.value) }
                            .sorted { $0.item.displayName < $1.item.displayName },
                        xpGained: xp
                    )
                )
            } else {
                progress[plan.spot] = min(elapsed, interval - 0.001)
            }
        }

        return results
    }
}
