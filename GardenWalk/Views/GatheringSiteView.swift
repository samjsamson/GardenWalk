import SwiftUI

struct GatheringSiteView: View {
    @Environment(GameController.self) private var game
    let spot: ResourceSpotKind
    @State private var expanded = false

    private var nodes: [GatheringNode] {
        game.gatheringNodes(for: spot)
    }

    private var visibleNodes: [GatheringNode] {
        expanded ? nodes : Array(nodes.prefix(2))
    }

    var body: some View {
        if nodes.isEmpty {
            Text("Hire a worker at the General Store. Each worker you own opens a node in this area.")
                .font(.caption)
                .foregroundStyle(GardenPalette.inkMuted)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if spot == .fishingPond {
                    FishingPondLayout(nodes: visibleNodes)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 10)], spacing: 10) {
                        ForEach(visibleNodes) { node in
                            GatheringNodeCard(node: node)
                        }
                    }
                }
                if nodes.count > 2 {
                    Button(expanded ? "Collapse" : "Expand") {
                        withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(GardenPalette.moss)
                }
            }
        }
    }
}

private struct GatheringNodeCard: View {
    @Environment(GameController.self) private var game
    let node: GatheringNode

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 2) {
                nodeArt
                    .frame(width: 58, height: 52)
                if node.isOccupied {
                    WorkingWorkerView(tool: game.workerHeldTool(for: node.resource.skill))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .frame(width: 28, height: 36)
                }
            }
            Text(node.resource.name)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(node.isOccupied ? "Working" : "Empty")
                .font(.caption2)
                .foregroundStyle(node.isOccupied ? GardenPalette.moss : GardenPalette.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(GardenPalette.cream.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(node.resource.name), \(node.isOccupied ? "worker assigned" : "empty node")")
    }

    @ViewBuilder
    private var nodeArt: some View {
        switch node.resource.spot {
        case .miningSpot:
            OreRockView(resourceID: node.resource.id, variant: node.variant)
        case .treePlot, .gardenSpot:
            TreeGraphicView(resourceID: node.resource.id, variant: node.variant)
        case .fishingPond, .runeMine:
            ItemIconView(item: node.resource.primaryOutput, size: 28)
        }
    }
}

private struct WorkingWorkerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let tool: InventoryItemID
    @State private var swinging = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ItemIconView(visual: .worker, size: 34)
            ItemIconView(item: tool, size: 16)
                .rotationEffect(.degrees(swinging ? -28 : 18))
                .offset(x: 6, y: 2)
        }
        .offset(y: swinging ? -2 : 1)
        .frame(width: 40, height: 40)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.42).repeatForever(autoreverses: true)) {
                swinging = true
            }
        }
        .accessibilityHidden(true)
    }
}

private struct FishingPondLayout: View {
    let nodes: [GatheringNode]

    var body: some View {
        let side = max(220, min(360, 150 + CGFloat(nodes.count) * 16))
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: side / 2)
            let radius = side * 0.34
            ZStack {
                Circle()
                    .fill(GardenPalette.moss.opacity(0.18))
                    .frame(width: radius * 2.15, height: radius * 2.15)
                    .position(center)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.82, blue: 0.90),
                                Color(red: 0.16, green: 0.45, blue: 0.62)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: radius * 1.45, height: radius * 1.45)
                    .position(center)
                Circle()
                    .stroke(Color.white.opacity(0.45), lineWidth: 3)
                    .frame(width: radius * 0.85, height: radius * 0.7)
                    .position(x: center.x, y: center.y - radius * 0.12)
                ForEach(nodes) { node in
                    let count = max(nodes.count, 1)
                    let angle = (Double(node.index) / Double(count)) * 2 * .pi - .pi / 2
                    FishingSpotMarker(node: node)
                        .position(
                            x: center.x + CGFloat(cos(angle)) * radius,
                            y: center.y + CGFloat(sin(angle)) * radius
                        )
                }
            }
        }
        .frame(height: side)
        .accessibilityElement(children: .contain)
    }
}

private struct FishingSpotMarker: View {
    @Environment(GameController.self) private var game
    let node: GatheringNode

    var body: some View {
        VStack(spacing: 2) {
            if node.isOccupied {
                WorkingWorkerView(tool: game.workerHeldTool(for: .fishing))
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    .frame(width: 18, height: 18)
            }
            Text(node.resource.name)
                .font(.system(size: 9, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.white.opacity(0.85), in: Capsule())
        }
        .frame(width: 64)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(node.resource.name) fishing spot, \(node.isOccupied ? "worker assigned" : "empty")")
    }
}

private struct OreRockView: View {
    let resourceID: String
    let variant: Int

    var body: some View {
        let colors = palette
        ZStack {
            RockBlob()
                .fill(colors.rock)
                .frame(width: variant % 2 == 0 ? 40 : 34, height: 30)
                .offset(x: variant % 2 == 0 ? -6 : 4, y: 6)
            RockBlob()
                .fill(colors.rock.opacity(0.85))
                .frame(width: 24, height: 20)
                .offset(x: 10, y: variant % 3 == 0 ? -4 : 0)
            Capsule()
                .fill(colors.vein)
                .frame(width: 16, height: 7)
                .rotationEffect(.degrees(variant % 2 == 0 ? -20 : 24))
                .offset(x: 2, y: 2)
            if variant % 3 != 1 {
                Circle()
                    .fill(colors.vein.opacity(0.9))
                    .frame(width: 8, height: 8)
                    .offset(x: -8, y: -6)
            }
        }
    }

    private var palette: (rock: Color, vein: Color) {
        switch resourceID {
        case "tin":
            return (ItemPalette.tin, ItemPalette.silverLight)
        case "iron":
            return (ItemPalette.iron, ItemPalette.ironLight)
        case "coal":
            return (Color(red: 0.12, green: 0.12, blue: 0.13), Color(red: 0.28, green: 0.28, blue: 0.30))
        case "silver":
            return (ItemPalette.silver, ItemPalette.silverLight)
        case "gold-ore":
            return (ItemPalette.goldDeep, ItemPalette.goldLight)
        default:
            return (ItemPalette.stone, ItemPalette.copper)
        }
    }
}

private struct RockBlob: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        return path
    }
}

private struct TreeGraphicView: View {
    let resourceID: String
    let variant: Int

    var body: some View {
        let scale: CGFloat = variant % 2 == 0 ? 1 : 0.86
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(ItemPalette.wood)
                .frame(width: 8, height: 18)
                .offset(y: 16)
            canopy
                .scaleEffect(scale)
                .offset(y: -4)
        }
    }

    @ViewBuilder
    private var canopy: some View {
        switch resourceID {
        case "oak":
            Ellipse()
                .fill(Color(red: 0.18, green: 0.42, blue: 0.20))
                .frame(width: 46, height: 28)
            Ellipse()
                .fill(GardenPalette.leaf)
                .frame(width: 22, height: 16)
                .offset(x: -8, y: -6)
        case "willow":
            ZStack {
                Ellipse()
                    .fill(Color(red: 0.42, green: 0.62, blue: 0.34))
                    .frame(width: 36, height: 16)
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(GardenPalette.moss)
                        .frame(width: 6, height: 22)
                        .offset(x: CGFloat(index - 1) * 10, y: 12)
                }
            }
        case "maple":
            Circle()
                .fill(Color(red: 0.86, green: 0.38, blue: 0.16))
                .frame(width: 34, height: 34)
            Circle()
                .fill(Color(red: 0.95, green: 0.62, blue: 0.18))
                .frame(width: 16, height: 16)
                .offset(x: 8, y: 4)
        case "apple-tree":
            Circle()
                .fill(GardenPalette.leaf)
                .frame(width: 34, height: 34)
            Circle()
                .fill(ItemPalette.apple)
                .frame(width: 8, height: 8)
                .offset(x: -6, y: 2)
            Circle()
                .fill(ItemPalette.apple)
                .frame(width: 7, height: 7)
                .offset(x: 7, y: -4)
        default:
            TreeCanopy()
                .fill(variant % 2 == 0 ? GardenPalette.leaf : GardenPalette.moss)
                .frame(width: 36, height: 32)
        }
    }
}

private struct TreeCanopy: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
