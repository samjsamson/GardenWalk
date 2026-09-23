import SwiftUI

struct ItemIconView: View {
    private let art: ItemArt
    var size: CGFloat

    init(art: ItemArt, size: CGFloat = 36) {
        self.art = art
        self.size = size
    }

    init(item: InventoryItemID, size: CGFloat = 36) {
        self.init(art: ItemArtCatalog.art(for: item), size: size)
    }

    init(visual: ItemVisual, size: CGFloat = 36) {
        self.init(art: ItemArtCatalog.art(for: visual), size: size)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(art.tint.opacity(0.18))
            glyph
                .padding(size * 0.14)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var glyph: some View {
        if let assetName = art.assetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
        } else {
            switch art.glyph {
            case .symbol:
                Image(systemName: art.fallbackSymbol)
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(art.tint)
                    .padding(size * 0.08)
            case .goldCoins:
                GoldCoinsIcon(light: art.tint, deep: art.secondaryTint)
            case .worker:
                WorkerIcon(tunic: art.tint, skin: art.secondaryTint)
            case .axe:
                AxeIcon(headLight: art.tint, headDark: art.secondaryTint)
            case .dagger(let primitive):
                DaggerIcon(bladeLight: art.tint, bladeDark: art.secondaryTint, primitive: primitive)
            case .ingot:
                IngotIcon(light: art.tint, deep: art.secondaryTint)
            case .apple:
                AppleIcon(fruit: art.tint, leaf: art.secondaryTint)
            case .ore(let bright):
                OreChunkIcon(metal: art.tint, deep: art.secondaryTint, bright: bright)
            case .sapling:
                SaplingIcon(leaf: art.tint, stem: art.secondaryTint)
            case .pickaxe:
                PickaxeIcon(headLight: art.tint, headDark: art.secondaryTint)
            case .ration:
                RationIcon(sack: art.tint, tie: art.secondaryTint)
            case .torch:
                TorchIcon(flame: art.tint, handle: art.secondaryTint)
            case .crate:
                CrateIcon(light: art.tint, deep: art.secondaryTint)
            case .backpack:
                BackpackIcon(pack: art.tint, flap: art.secondaryTint)
            case .helmet:
                HelmetIcon(light: art.tint, deep: art.secondaryTint)
            case .pants:
                PantsIcon(light: art.tint, deep: art.secondaryTint)
            case .bootPair:
                BootPairIcon(light: art.tint, deep: art.secondaryTint)
            case .quiver:
                QuiverIcon(shaft: art.tint, tip: art.secondaryTint)
            case .copperRock:
                CopperRockIcon(rock: art.tint, mineral: art.secondaryTint)
            case .woodLogs:
                WoodLogsIcon(bark: art.tint, cut: art.secondaryTint)
            case .seed:
                SeedIcon(picture: .turnip, husk: art.tint, seam: art.secondaryTint)
            case .cropSeed(let picture):
                SeedIcon(picture: picture, husk: art.tint, seam: art.secondaryTint)
            case .scimitar:
                ScimitarIcon(bladeLight: art.tint, bladeDark: art.secondaryTint)
            case .roughStone:
                RoughStoneIcon(light: art.tint, deep: art.secondaryTint)
            case .fishingRod:
                FishingRodIcon(shaft: art.secondaryTint, line: art.tint)
            case .platebody:
                PlatebodyIcon(light: art.tint, deep: art.secondaryTint)
            case .shield:
                ShieldIcon(light: art.tint, deep: art.secondaryTint)
            case .sword:
                SwordIcon(bladeLight: art.tint, bladeDark: art.secondaryTint)
            case .hammer:
                HammerIcon(head: art.tint, handle: art.secondaryTint)
            case .hide:
                HideIcon(light: art.tint, deep: art.secondaryTint)
            }
        }
    }
}

struct ItemDropLabel: View {
    let drop: InventoryItemDrop
    var iconSize: CGFloat = 18
    var prefix: String = ""
    var tint: Color = GardenPalette.ink

    var body: some View {
        HStack(spacing: 6) {
            ItemIconView(item: drop.item, size: iconSize)
            Text("\(prefix)\(drop.amount) \(drop.item.displayName)")
                .foregroundStyle(tint)
        }
    }
}

private struct GoldCoinsIcon: View {
    let light: Color
    let deep: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                coin(side: side * 0.62)
                    .position(x: side * 0.62, y: side * 0.58)
                coin(side: side * 0.62)
                    .position(x: side * 0.48, y: side * 0.46)
                coin(side: side * 0.62)
                    .position(x: side * 0.36, y: side * 0.34)
            }
            .frame(width: side, height: side)
        }
    }

    private func coin(side: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: [light, ItemPalette.gold, deep], startPoint: .top, endPoint: .bottom)
                )
            Circle()
                .stroke(deep, lineWidth: max(1, side * 0.08))
                .padding(side * 0.12)
            Circle()
                .stroke(light.opacity(0.9), lineWidth: max(0.5, side * 0.05))
                .padding(side * 0.22)
        }
        .frame(width: side, height: side)
        .shadow(color: deep.opacity(0.25), radius: 0.5, y: 0.5)
    }
}

private struct WorkerIcon: View {
    let tunic: Color
    let skin: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(ItemPalette.wood)
                    .frame(width: side * 0.46, height: side * 0.16)
                    .position(x: side * 0.50, y: side * 0.16)
                Circle()
                    .fill(skin)
                    .frame(width: side * 0.34, height: side * 0.34)
                    .position(x: side * 0.50, y: side * 0.32)
                RoundedRectangle(cornerRadius: side * 0.14, style: .continuous)
                    .fill(tunic)
                    .frame(width: side * 0.52, height: side * 0.40)
                    .position(x: side * 0.50, y: side * 0.68)
                Capsule()
                    .fill(skin)
                    .frame(width: side * 0.10, height: side * 0.22)
                    .position(x: side * 0.28, y: side * 0.62)
                Capsule()
                    .fill(skin)
                    .frame(width: side * 0.10, height: side * 0.22)
                    .position(x: side * 0.72, y: side * 0.62)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct AxeIcon: View {
    let headLight: Color
    let headDark: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(
                        LinearGradient(colors: [ItemPalette.woodLight, ItemPalette.wood], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: side * 0.16, height: side * 0.70)
                    .position(x: side * 0.50, y: side * 0.60)
                AxeHeadShape()
                    .fill(
                        LinearGradient(colors: [headLight, headDark], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: side * 0.78, height: side * 0.38)
                    .position(x: side * 0.50, y: side * 0.28)
                AxeHeadShape()
                    .stroke(headDark.opacity(0.55), lineWidth: 0.8)
                    .frame(width: side * 0.78, height: side * 0.38)
                    .position(x: side * 0.50, y: side * 0.28)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct AxeHeadShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.width * 0.18, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.82))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.width * 0.18, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private struct DaggerIcon: View {
    let bladeLight: Color
    let bladeDark: Color
    var primitive: Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let bladeWidth = side * (primitive ? 0.46 : 0.34)
            ZStack {
                DaggerBladeShape(primitive: primitive)
                    .fill(
                        LinearGradient(colors: [bladeLight, bladeDark], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: bladeWidth, height: side * 0.56)
                    .position(x: side * 0.50, y: side * 0.30)
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(bladeDark)
                    .frame(width: side * 0.52, height: side * 0.08)
                    .position(x: side * 0.50, y: side * 0.58)
                RoundedRectangle(cornerRadius: side * 0.05, style: .continuous)
                    .fill(
                        LinearGradient(colors: [ItemPalette.woodLight, ItemPalette.wood], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: side * 0.16, height: side * 0.26)
                    .position(x: side * 0.50, y: side * 0.74)
                Circle()
                    .fill(bladeDark)
                    .frame(width: side * 0.16, height: side * 0.16)
                    .position(x: side * 0.50, y: side * 0.90)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct DaggerBladeShape: Shape {
    var primitive: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        if primitive {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.38))
            path.addLine(to: CGPoint(x: rect.width * 0.78, y: rect.height * 0.58))
            path.addLine(to: CGPoint(x: rect.maxX * 0.92, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.width * 0.08, y: rect.height * 0.48))
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

private struct IngotIcon: View {
    let light: Color
    let deep: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                IngotShape()
                    .fill(
                        LinearGradient(colors: [light, ItemPalette.bronze, deep], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: side * 0.92, height: side * 0.48)
                    .position(x: side * 0.50, y: side * 0.54)
                IngotTopShape()
                    .fill(light.opacity(0.95))
                    .frame(width: side * 0.72, height: side * 0.20)
                    .position(x: side * 0.50, y: side * 0.40)
                IngotShape()
                    .stroke(deep.opacity(0.7), lineWidth: 0.8)
                    .frame(width: side * 0.92, height: side * 0.48)
                    .position(x: side * 0.50, y: side * 0.54)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct IngotShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.14
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - inset * 0.35, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset * 0.35, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct IngotTopShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.16, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.84, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct OreChunkIcon: View {
    let metal: Color
    let deep: Color
    var bright: Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                OreChunkShape()
                    .fill(
                        LinearGradient(
                            colors: [metal, deep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                OreFacetShape()
                    .fill((bright ? ItemPalette.silverLight : ItemPalette.ironLight).opacity(bright ? 0.95 : 0.55))
                    .frame(width: side * 0.42, height: side * 0.28)
                    .position(x: side * 0.40, y: side * 0.36)
                if bright {
                    Circle()
                        .fill(.white)
                        .frame(width: side * 0.12, height: side * 0.12)
                        .position(x: side * 0.34, y: side * 0.32)
                }
            }
            .frame(width: side, height: side)
        }
    }
}

private struct OreChunkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.24, y: rect.height * 0.30))
        path.addLine(to: CGPoint(x: rect.width * 0.46, y: rect.height * 0.10))
        path.addLine(to: CGPoint(x: rect.width * 0.78, y: rect.height * 0.20))
        path.addLine(to: CGPoint(x: rect.width * 0.94, y: rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.width * 0.74, y: rect.height * 0.90))
        path.addLine(to: CGPoint(x: rect.width * 0.32, y: rect.height * 0.92))
        path.addLine(to: CGPoint(x: rect.width * 0.08, y: rect.height * 0.58))
        path.closeSubpath()
        return path
    }
}

private struct OreFacetShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.28, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.width * 0.70, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct AppleIcon: View {
    let fruit: Color
    let leaf: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [fruit.opacity(0.85), fruit], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: side * 0.72, height: side * 0.72)
                    .position(x: side * 0.50, y: side * 0.58)
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(ItemPalette.wood)
                    .frame(width: side * 0.08, height: side * 0.16)
                    .position(x: side * 0.50, y: side * 0.20)
                Ellipse()
                    .fill(leaf)
                    .frame(width: side * 0.28, height: side * 0.14)
                    .rotationEffect(.degrees(-30))
                    .position(x: side * 0.66, y: side * 0.22)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct SaplingIcon: View {
    let leaf: Color
    let stem: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.04, style: .continuous)
                    .fill(stem)
                    .frame(width: side * 0.10, height: side * 0.48)
                    .position(x: side * 0.50, y: side * 0.66)
                Ellipse()
                    .fill(leaf)
                    .frame(width: side * 0.34, height: side * 0.22)
                    .rotationEffect(.degrees(-35))
                    .position(x: side * 0.34, y: side * 0.38)
                Ellipse()
                    .fill(leaf.opacity(0.9))
                    .frame(width: side * 0.34, height: side * 0.22)
                    .rotationEffect(.degrees(35))
                    .position(x: side * 0.66, y: side * 0.36)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct PickaxeIcon: View {
    let headLight: Color
    let headDark: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.06, style: .continuous)
                    .fill(
                        LinearGradient(colors: [ItemPalette.woodLight, ItemPalette.wood], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: side * 0.14, height: side * 0.72)
                    .rotationEffect(.degrees(28))
                    .position(x: side * 0.46, y: side * 0.58)
                PickaxeHeadShape()
                    .fill(LinearGradient(colors: [headLight, headDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.72, height: side * 0.34)
                    .position(x: side * 0.52, y: side * 0.28)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct PickaxeHeadShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.15))
        path.addLine(to: CGPoint(x: rect.width * 0.42, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.55, y: rect.height * 0.42))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.62, y: rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.height * 0.48))
        path.closeSubpath()
        return path
    }
}

private struct RationIcon: View {
    let sack: Color
    let tie: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                    .fill(LinearGradient(colors: [sack, ItemPalette.wood], startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.62, height: side * 0.58)
                    .position(x: side * 0.50, y: side * 0.60)
                Capsule()
                    .fill(tie)
                    .frame(width: side * 0.16, height: side * 0.28)
                    .position(x: side * 0.50, y: side * 0.28)
                Circle()
                    .fill(tie)
                    .frame(width: side * 0.16, height: side * 0.16)
                    .position(x: side * 0.50, y: side * 0.18)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct TorchIcon: View {
    let flame: Color
    let handle: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(handle)
                    .frame(width: side * 0.16, height: side * 0.55)
                    .position(x: side * 0.50, y: side * 0.68)
                FlameShape()
                    .fill(LinearGradient(colors: [ItemPalette.goldLight, flame, Color(red: 0.85, green: 0.32, blue: 0.10)], startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.42, height: side * 0.48)
                    .position(x: side * 0.50, y: side * 0.32)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.height * 0.62), control: CGPoint(x: rect.maxX, y: rect.height * 0.15))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.height * 0.62), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.height * 0.15))
        return path
    }
}

private struct CrateIcon: View {
    let light: Color
    let deep: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(LinearGradient(colors: [light, deep], startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.78, height: side * 0.62)
                    .position(x: side * 0.50, y: side * 0.58)
                Rectangle()
                    .fill(deep.opacity(0.85))
                    .frame(width: side * 0.78, height: side * 0.08)
                    .position(x: side * 0.50, y: side * 0.36)
                Rectangle()
                    .fill(deep.opacity(0.55))
                    .frame(width: side * 0.06, height: side * 0.50)
                    .position(x: side * 0.36, y: side * 0.62)
                Rectangle()
                    .fill(deep.opacity(0.55))
                    .frame(width: side * 0.06, height: side * 0.50)
                    .position(x: side * 0.64, y: side * 0.62)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct BackpackIcon: View {
    let pack: Color
    let flap: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                    .fill(pack)
                    .frame(width: side * 0.62, height: side * 0.70)
                    .position(x: side * 0.50, y: side * 0.58)
                RoundedRectangle(cornerRadius: side * 0.10, style: .continuous)
                    .fill(flap)
                    .frame(width: side * 0.50, height: side * 0.28)
                    .position(x: side * 0.50, y: side * 0.36)
                Capsule()
                    .stroke(flap, lineWidth: side * 0.06)
                    .frame(width: side * 0.28, height: side * 0.22)
                    .position(x: side * 0.50, y: side * 0.16)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct HelmetIcon: View {
    let light: Color
    let deep: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                HelmetDome()
                    .fill(LinearGradient(colors: [light, deep], startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.78, height: side * 0.62)
                    .position(x: side * 0.50, y: side * 0.42)
                Capsule()
                    .fill(deep)
                    .frame(width: side * 0.92, height: side * 0.14)
                    .position(x: side * 0.50, y: side * 0.62)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.black.opacity(0.55))
                    .frame(width: side * 0.42, height: side * 0.08)
                    .position(x: side * 0.50, y: side * 0.48)
                Capsule()
                    .fill(light.opacity(0.85))
                    .frame(width: side * 0.16, height: side * 0.28)
                    .position(x: side * 0.34, y: side * 0.32)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct HelmetDome: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct PantsIcon: View {
    let light: Color
    let deep: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(deep)
                    .frame(width: side * 0.72, height: side * 0.18)
                    .position(x: side * 0.50, y: side * 0.22)
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(LinearGradient(colors: [light, deep], startPoint: .leading, endPoint: .trailing))
                    .frame(width: side * 0.28, height: side * 0.62)
                    .position(x: side * 0.34, y: side * 0.58)
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(LinearGradient(colors: [light, deep], startPoint: .leading, endPoint: .trailing))
                    .frame(width: side * 0.28, height: side * 0.62)
                    .position(x: side * 0.66, y: side * 0.58)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct BootPairIcon: View {
    let light: Color
    let deep: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                BootShape()
                    .fill(LinearGradient(colors: [light, deep], startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.42, height: side * 0.55)
                    .position(x: side * 0.32, y: side * 0.55)
                BootShape()
                    .fill(deep)
                    .frame(width: side * 0.42, height: side * 0.55)
                    .position(x: side * 0.68, y: side * 0.58)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct BootShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.28, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.height * 0.62))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.72))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.72))
        path.addLine(to: CGPoint(x: rect.width * 0.28, y: rect.height * 0.62))
        path.closeSubpath()
        return path
    }
}

private struct QuiverIcon: View {
    let shaft: Color
    let tip: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Capsule()
                    .fill(shaft)
                    .frame(width: side * 0.46, height: side * 0.62)
                    .position(x: side * 0.52, y: side * 0.62)
                arrow(side: side, x: side * 0.38, rotation: -8)
                arrow(side: side, x: side * 0.52, rotation: 0)
                arrow(side: side, x: side * 0.66, rotation: 8)
            }
            .frame(width: side, height: side)
        }
    }

    private func arrow(side: CGFloat, x: CGFloat, rotation: Double) -> some View {
        ZStack {
            Capsule()
                .fill(ItemPalette.woodLight)
                .frame(width: side * 0.06, height: side * 0.55)
            Triangle()
                .fill(tip)
                .frame(width: side * 0.14, height: side * 0.16)
                .offset(y: -side * 0.32)
            HStack(spacing: 0) {
                Triangle().fill(GardenPalette.leaf).frame(width: side * 0.08, height: side * 0.1)
                Triangle().fill(GardenPalette.leaf).frame(width: side * 0.08, height: side * 0.1)
            }
            .offset(y: side * 0.18)
        }
        .rotationEffect(.degrees(rotation))
        .position(x: x, y: side * 0.42)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct CopperRockIcon: View {
    let rock: Color
    let mineral: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoughRockShape()
                    .fill(LinearGradient(colors: [rock, ItemPalette.stoneDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle()
                    .fill(mineral)
                    .frame(width: side * 0.22, height: side * 0.18)
                    .position(x: side * 0.38, y: side * 0.42)
                Circle()
                    .fill(ItemPalette.copperLight)
                    .frame(width: side * 0.16, height: side * 0.14)
                    .position(x: side * 0.62, y: side * 0.58)
                Capsule()
                    .fill(mineral.opacity(0.9))
                    .frame(width: side * 0.28, height: side * 0.08)
                    .rotationEffect(.degrees(-24))
                    .position(x: side * 0.48, y: side * 0.50)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct RoughStoneIcon: View {
    let light: Color
    let deep: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoughRockShape()
                    .fill(LinearGradient(colors: [light, deep], startPoint: .top, endPoint: .bottom))
                Path { path in
                    path.move(to: CGPoint(x: side * 0.28, y: side * 0.34))
                    path.addLine(to: CGPoint(x: side * 0.48, y: side * 0.55))
                    path.addLine(to: CGPoint(x: side * 0.70, y: side * 0.46))
                }
                .stroke(deep, lineWidth: 1.2)
                Capsule()
                    .fill(ItemPalette.stoneLight.opacity(0.7))
                    .frame(width: side * 0.22, height: side * 0.1)
                    .rotationEffect(.degrees(18))
                    .position(x: side * 0.40, y: side * 0.36)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct RoughRockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.22, y: rect.height * 0.28))
        path.addLine(to: CGPoint(x: rect.width * 0.48, y: rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.width * 0.80, y: rect.height * 0.26))
        path.addLine(to: CGPoint(x: rect.width * 0.92, y: rect.height * 0.58))
        path.addLine(to: CGPoint(x: rect.width * 0.70, y: rect.height * 0.90))
        path.addLine(to: CGPoint(x: rect.width * 0.30, y: rect.height * 0.88))
        path.addLine(to: CGPoint(x: rect.width * 0.10, y: rect.height * 0.56))
        path.closeSubpath()
        return path
    }
}

private struct WoodLogsIcon: View {
    let bark: Color
    let cut: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                log(side: side, y: side * 0.72)
                log(side: side, y: side * 0.52)
                log(side: side, y: side * 0.32)
            }
            .frame(width: side, height: side)
        }
    }

    private func log(side: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(bark)
                .frame(width: side * 0.78, height: side * 0.22)
            Circle()
                .fill(cut)
                .frame(width: side * 0.2, height: side * 0.2)
                .overlay(Circle().stroke(bark, lineWidth: 1))
                .offset(x: -side * 0.28)
        }
        .position(x: side * 0.50, y: y)
    }
}

private struct SeedIcon: View {
    let picture: SeedPicture
    let husk: Color
    let seam: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                switch picture {
                case .turnip:
                    Circle()
                        .fill(LinearGradient(colors: [husk, seam], startPoint: .top, endPoint: .bottom))
                        .frame(width: side * 0.62, height: side * 0.62)
                        .position(x: side * 0.50, y: side * 0.56)
                    Capsule()
                        .fill(seam)
                        .frame(width: side * 0.10, height: side * 0.28)
                        .position(x: side * 0.50, y: side * 0.28)
                case .carrot:
                    SeedShape()
                        .fill(LinearGradient(colors: [husk, seam], startPoint: .top, endPoint: .bottom))
                        .frame(width: side * 0.28, height: side * 0.78)
                        .position(x: side * 0.50, y: side * 0.52)
                    Capsule()
                        .fill(GardenPalette.leaf)
                        .frame(width: side * 0.08, height: side * 0.22)
                        .position(x: side * 0.50, y: side * 0.16)
                case .cabbage:
                    Circle()
                        .fill(seam)
                        .frame(width: side * 0.70, height: side * 0.70)
                        .position(x: side * 0.50, y: side * 0.52)
                    Circle()
                        .fill(husk)
                        .frame(width: side * 0.42, height: side * 0.42)
                        .position(x: side * 0.46, y: side * 0.48)
                case .pumpkin:
                    Circle()
                        .fill(LinearGradient(colors: [husk, seam], startPoint: .top, endPoint: .bottom))
                        .frame(width: side * 0.72, height: side * 0.72)
                        .position(x: side * 0.50, y: side * 0.54)
                    Capsule()
                        .fill(seam.opacity(0.85))
                        .frame(width: side * 0.06, height: side * 0.62)
                        .position(x: side * 0.50, y: side * 0.54)
                    Capsule()
                        .fill(GardenPalette.moss)
                        .frame(width: side * 0.16, height: side * 0.12)
                        .position(x: side * 0.50, y: side * 0.22)
                case .herb:
                    Capsule()
                        .fill(husk)
                        .frame(width: side * 0.22, height: side * 0.55)
                        .rotationEffect(.degrees(-28))
                        .position(x: side * 0.40, y: side * 0.48)
                    Capsule()
                        .fill(seam)
                        .frame(width: side * 0.22, height: side * 0.55)
                        .rotationEffect(.degrees(28))
                        .position(x: side * 0.62, y: side * 0.48)
                case .glowcap:
                    Capsule()
                        .fill(seam)
                        .frame(width: side * 0.12, height: side * 0.34)
                        .position(x: side * 0.50, y: side * 0.68)
                    Circle()
                        .fill(LinearGradient(colors: [husk, seam], startPoint: .top, endPoint: .bottom))
                        .frame(width: side * 0.62, height: side * 0.42)
                        .position(x: side * 0.50, y: side * 0.40)
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: side * 0.10, height: side * 0.10)
                        .position(x: side * 0.40, y: side * 0.38)
                }
            }
            .frame(width: side, height: side)
        }
    }
}

private struct FishingRodIcon: View {
    let shaft: Color
    let line: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Capsule()
                    .fill(LinearGradient(colors: [ItemPalette.woodLight, shaft], startPoint: .bottom, endPoint: .top))
                    .frame(width: side * 0.12, height: side * 0.78)
                    .rotationEffect(.degrees(-28))
                    .position(x: side * 0.46, y: side * 0.52)
                Circle()
                    .trim(from: 0.08, to: 0.62)
                    .stroke(line, style: StrokeStyle(lineWidth: max(1.5, side * 0.06), lineCap: .round))
                    .frame(width: side * 0.42, height: side * 0.42)
                    .position(x: side * 0.62, y: side * 0.40)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct SeedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.midY))
        return path
    }
}

private struct PlatebodyIcon: View {
    let light: Color
    let deep: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                PlatebodyShape()
                    .fill(LinearGradient(colors: [light, deep], startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.78, height: side * 0.82)
                    .position(x: side * 0.50, y: side * 0.52)
                Capsule()
                    .fill(light.opacity(0.85))
                    .frame(width: side * 0.10, height: side * 0.34)
                    .position(x: side * 0.50, y: side * 0.46)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct PlatebodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let neck = rect.width * 0.22
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.28))
        path.addLine(to: CGPoint(x: rect.midX - neck, y: rect.minY + rect.height * 0.18))
        path.addQuadCurve(to: CGPoint(x: rect.midX + neck, y: rect.minY + rect.height * 0.18), control: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.28))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ShieldIcon: View {
    let light: Color
    let deep: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                ShieldShape()
                    .fill(LinearGradient(colors: [light, deep], startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.72, height: side * 0.84)
                    .position(x: side * 0.50, y: side * 0.50)
                Capsule()
                    .fill(light.opacity(0.9))
                    .frame(width: side * 0.12, height: side * 0.42)
                    .position(x: side * 0.50, y: side * 0.42)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY * 0.92))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.minX, y: rect.maxY * 0.92))
        path.closeSubpath()
        return path
    }
}

private struct ScimitarIcon: View {
    let bladeLight: Color
    let bladeDark: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                ScimitarBlade()
                    .stroke(
                        LinearGradient(colors: [bladeLight, bladeDark], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: side * 0.12, lineCap: .round)
                    )
                    .frame(width: side * 0.62, height: side * 0.62)
                    .position(x: side * 0.52, y: side * 0.36)
                Capsule()
                    .fill(ItemPalette.wood)
                    .frame(width: side * 0.34, height: side * 0.08)
                    .rotationEffect(.degrees(-24))
                    .position(x: side * 0.40, y: side * 0.66)
                Capsule()
                    .fill(bladeDark)
                    .frame(width: side * 0.08, height: side * 0.22)
                    .rotationEffect(.degrees(-24))
                    .position(x: side * 0.30, y: side * 0.80)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct ScimitarBlade: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.08),
            control: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.15)
        )
        return path
    }
}

private struct SwordIcon: View {
    let bladeLight: Color
    let bladeDark: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Capsule()
                    .fill(LinearGradient(colors: [bladeLight, bladeDark], startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.16, height: side * 0.62)
                    .position(x: side * 0.50, y: side * 0.34)
                Capsule()
                    .fill(ItemPalette.wood)
                    .frame(width: side * 0.46, height: side * 0.10)
                    .position(x: side * 0.50, y: side * 0.66)
                Capsule()
                    .fill(bladeDark)
                    .frame(width: side * 0.10, height: side * 0.22)
                    .position(x: side * 0.50, y: side * 0.82)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct HammerIcon: View {
    let head: Color
    let handle: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(LinearGradient(colors: [head, head.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.62, height: side * 0.28)
                    .position(x: side * 0.50, y: side * 0.32)
                Capsule()
                    .fill(handle)
                    .frame(width: side * 0.12, height: side * 0.55)
                    .position(x: side * 0.50, y: side * 0.66)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct HideIcon: View {
    let light: Color
    let deep: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                    .fill(LinearGradient(colors: [light, deep], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: side * 0.72, height: side * 0.56)
                    .rotationEffect(.degrees(-12))
                    .position(x: side * 0.48, y: side * 0.50)
                Capsule()
                    .fill(deep.opacity(0.45))
                    .frame(width: side * 0.36, height: side * 0.08)
                    .position(x: side * 0.50, y: side * 0.48)
            }
            .frame(width: side, height: side)
        }
    }
}
