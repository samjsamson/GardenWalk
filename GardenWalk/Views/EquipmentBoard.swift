import SwiftUI

struct EquipmentBoard: View {
    @Environment(GameController.self) private var game
    @State private var customizing = false
    @State private var pickingSlot: EquipmentSlot?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Equipment").font(.headline)
                Spacer()
                Button { customizing = true } label: {
                    Label("Customize", systemImage: "paintpalette")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(GardenPalette.moss)
            }

            HStack(alignment: .top, spacing: 8) {
                slotColumn(EquipmentSlot.paperDollLeading)
                PlayerSilhouette(
                    helmet: game.equippedItem(in: .helmet),
                    chest: game.equippedItem(in: .chest),
                    legs: game.equippedItem(in: .legs),
                    boots: game.equippedItem(in: .boots),
                    weapon: game.equippedItem(in: .weapon),
                    shield: game.equippedItem(in: .shield),
                    skinTone: game.skinTone,
                    clothingTone: game.clothingTone
                )
                .frame(maxWidth: .infinity)
                slotColumn(EquipmentSlot.paperDollTrailing)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Tools")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GardenPalette.inkMuted)
                HStack(spacing: 8) {
                    ForEach(EquipmentSlot.toolSlots) { slot in
                        EquipmentSlotButton(slot: slot, item: game.equippedItem(in: slot)) {
                            pickingSlot = slot
                        }
                    }
                }
                loadoutStats
            }
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
        .sheet(isPresented: $customizing) {
            CharacterCustomizationView(skin: game.skinTone, clothing: game.clothingTone)
                .environment(game)
        }
        .sheet(item: $pickingSlot) { slot in
            EquipmentPickerSheet(slot: slot)
                .environment(game)
                .presentationDetents([.medium, .large])
        }
    }

    private var yieldRows: [(label: String, value: String)] {
        EquipmentSlot.toolSlots.compactMap { slot in
            guard let item = game.equippedItem(in: slot),
                  let definition = EquipmentCatalog.definition(for: item),
                  let skill = definition.bonuses.workerSkill,
                  definition.bonuses.workerYieldBonus > 0 else { return nil }
            let percent = Int((definition.bonuses.workerYieldBonus * 100).rounded())
            return ("\(skill.displayName) Bonus", "+\(percent)%")
        }
    }

    private var loadoutStats: some View {
        let rows: [(String, String)] = yieldRows + [
            ("Attack Bonus", "\(game.playerAttackPower)"),
            ("Defense Bonus", "\(game.playerCombatDefense)"),
            ("Magic Bonus", "\(game.playerMagicPower)"),
            ("Attack Speed", game.attackSpeedSummary)
        ]
        return LazyVGrid(columns: [
            GridItem(.flexible(minimum: 70), spacing: 6),
            GridItem(.flexible(minimum: 70), spacing: 6)
        ], alignment: .leading, spacing: 4) {
            ForEach(rows, id: \.0) { title, value in
                HStack(spacing: 4) {
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(GardenPalette.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 2)
                    Text(value)
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(GardenPalette.moss)
                        .lineLimit(1)
                }
            }
        }
    }

    private func slotColumn(_ slots: [EquipmentSlot]) -> some View {
        VStack(spacing: 6) {
            ForEach(slots) { slot in
                EquipmentSlotButton(slot: slot, item: game.equippedItem(in: slot)) {
                    pickingSlot = slot
                }
            }
        }
    }
}

private struct EquipmentSlotButton: View {
    let slot: EquipmentSlot
    let item: InventoryItemID?
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
            VStack(spacing: 3) {
                if let item {
                    ItemIconView(item: item, size: 28)
                    Text(item.displayName)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    ItemIconView(art: ItemArtCatalog.placeholder(for: slot), size: 28)
                    Text(slot.displayName)
                        .font(.caption2)
                        .foregroundStyle(GardenPalette.inkMuted)
                        .lineLimit(1)
                }
            }
            .frame(width: 68, height: 58)
            .background(Color.gray.opacity(item == nil ? 0.05 : 0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(item == nil ? Color.gray.opacity(0.15) : GardenPalette.leaf.opacity(0.45), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.map { "\($0.displayName), equipped in \(slot.displayName). Choose a replacement." } ?? "\(slot.displayName), empty. Choose an item.")
    }
}

private struct EquipmentPickerSheet: View {
    @Environment(GameController.self) private var game
    @Environment(\.dismiss) private var dismiss
    let slot: EquipmentSlot

    var body: some View {
        let _ = game.stateVersion
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let equipped = game.equippedItem(in: slot) {
                        equippedRow(equipped)
                    } else {
                        Text("Nothing equipped")
                            .font(.caption)
                            .foregroundStyle(GardenPalette.inkMuted)
                    }

                    let choices = game.bagItems(for: slot)
                    if choices.isEmpty {
                        Text("No \(slot.displayName.lowercased()) items in your bag.")
                            .font(.subheadline)
                            .foregroundStyle(GardenPalette.inkMuted)
                            .padding(.top, 8)
                    } else {
                        ForEach(choices, id: \.0) { item, quantity in
                            choiceRow(item, quantity: quantity)
                        }
                    }
                }
                .padding()
            }
            .background(GardenPalette.cream.ignoresSafeArea())
            .navigationTitle(slot.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func equippedRow(_ item: InventoryItemID) -> some View {
        HStack(spacing: 10) {
            ItemIconView(item: item, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.subheadline.weight(.semibold))
                Text("Equipped")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GardenPalette.leaf)
            }
            Spacer()
            Button("Unequip") {
                game.unequip(slot)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(GardenPalette.moss)
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func choiceRow(_ item: InventoryItemID, quantity: Int) -> some View {
        HStack(spacing: 10) {
            ItemIconView(item: item, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let requirement = EquipmentCatalog.requirementText(for: item) {
                    Text(requirement)
                        .font(.caption2)
                        .foregroundStyle(GardenPalette.inkMuted)
                }
                if let stats = EquipmentCatalog.combatStatsText(for: item) {
                    Text(stats)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GardenPalette.leaf)
                        .lineLimit(2)
                }
                Text("\(quantity) in bag")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(GardenPalette.inkMuted)
            }
            Spacer(minLength: 4)
            Button("Equip") {
                game.equip(item)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(GardenPalette.moss)
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct PlayerSilhouette: View {
    let helmet: InventoryItemID?
    let chest: InventoryItemID?
    let legs: InventoryItemID?
    let boots: InventoryItemID?
    let weapon: InventoryItemID?
    let shield: InventoryItemID?
    var skinTone: CharacterSkinTone = .warm
    var clothingTone: CharacterClothingTone = .forest

    private let leather = Color(red: 0.26, green: 0.17, blue: 0.12)
    private let trim = Color(red: 0.90, green: 0.73, blue: 0.39)

    var body: some View {
        ZStack {
            Ellipse().fill(GardenPalette.moss.opacity(0.09))
                .frame(width: 112, height: 160).offset(y: -2)
            Ellipse().fill(.black.opacity(0.12))
                .frame(width: 72, height: 12).offset(y: 89)
            // Cape, with a split hem and a warm lining.
            Path { path in
                path.move(to: CGPoint(x: 41, y: 65))
                path.addLine(to: CGPoint(x: 25, y: 151))
                path.addQuadCurve(to: CGPoint(x: 60, y: 151), control: CGPoint(x: 37, y: 159))
                path.addLine(to: CGPoint(x: 68, y: 140))
                path.addLine(to: CGPoint(x: 80, y: 153))
                path.addLine(to: CGPoint(x: 110, y: 146))
                path.addLine(to: CGPoint(x: 92, y: 65))
                path.closeSubpath()
            }
            .fill(clothingTone.color.gradient)
            .brightness(-0.13)
            .frame(width: 136, height: 204)

            limb(x: -13, y: 53, width: 18, height: 53, color: legs == nil ? leather : ItemPalette.iron)
            limb(x: 13, y: 53, width: 18, height: 53, color: legs == nil ? leather : ItemPalette.iron)
            ForEach([-1.0, 1.0], id: \.self) { side in
                RoundedRectangle(cornerRadius: 5)
                    .fill((boots == nil ? leather : ItemPalette.ironDeep).gradient)
                    .frame(width: 25, height: 20)
                    .overlay(alignment: .top) { Rectangle().fill(trim.opacity(0.65)).frame(height: 3) }
                    .offset(x: side * 14, y: 80)
                limb(x: side * 33, y: -1, width: 17, height: 43, color: clothingTone.color)
                    .rotationEffect(.degrees(side * -8))
                Circle().fill(skinTone.color.gradient).frame(width: 15, height: 17)
                    .offset(x: side * 38, y: 21)
                RoundedRectangle(cornerRadius: 3).fill(leather).frame(width: 17, height: 9)
                    .offset(x: side * 36, y: 13)
            }
            RoundedRectangle(cornerRadius: 13)
                .fill((chest == nil ? clothingTone.color : ItemPalette.iron).gradient)
                .frame(width: 54, height: 66)
                .overlay {
                    VStack(spacing: 7) {
                        ForEach(0..<3) { _ in Circle().fill(trim).frame(width: 3, height: 3) }
                    }.offset(y: -8)
                }
                .offset(y: 0)
            RoundedRectangle(cornerRadius: 3).fill(leather).frame(width: 57, height: 11).offset(y: 23)
            RoundedRectangle(cornerRadius: 2).stroke(trim, lineWidth: 3).frame(width: 12, height: 12).offset(y: 23)
            RoundedRectangle(cornerRadius: 4).fill(leather.gradient).frame(width: 13, height: 17).offset(x: 21, y: 30)
            // Neck, ears, face, hair and scarf give the character a friendly adventurer look.
            Capsule().fill(skinTone.color).frame(width: 16, height: 19).offset(y: -36)
            HStack(spacing: 29) {
                Circle().fill(skinTone.color).frame(width: 9, height: 12)
                Circle().fill(skinTone.color).frame(width: 9, height: 12)
            }.offset(y: -57)
            RoundedRectangle(cornerRadius: 17).fill(skinTone.color.gradient)
                .frame(width: 38, height: 42).offset(y: -60)
            hair
            HStack(spacing: 11) {
                Capsule().fill(leather).frame(width: 3, height: 5)
                Capsule().fill(leather).frame(width: 3, height: 5)
            }.offset(y: -59)
            Capsule().fill(leather.opacity(0.55)).frame(width: 8, height: 2).offset(y: -48)
            RoundedRectangle(cornerRadius: 4).fill(trim.gradient).frame(width: 32, height: 10).offset(y: -34)
            RoundedRectangle(cornerRadius: 3).fill(trim.gradient).frame(width: 10, height: 24)
                .rotationEffect(.degrees(-15)).offset(x: 14, y: -20)
            if helmet != nil {
                RoundedRectangle(cornerRadius: 14).fill(ItemPalette.iron.gradient)
                    .frame(width: 44, height: 24).offset(y: -76)
                RoundedRectangle(cornerRadius: 2).fill(trim).frame(width: 47, height: 5).offset(y: -65)
            }
            if let weapon {
                ItemIconView(item: weapon, size: 42)
                    .rotationEffect(.degrees(-20)).offset(x: 47, y: 11)
            }
            if let shield {
                ItemIconView(item: shield, size: 42).offset(x: -43, y: 8)
            }
        }
        .frame(width: 136, height: 204)
        .accessibilityHidden(true)
    }

    private var hair: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13).fill(leather.gradient)
                .frame(width: 41, height: 19).offset(y: -78)
            Capsule().fill(leather).frame(width: 24, height: 11)
                .rotationEffect(.degrees(-22)).offset(x: -10, y: -71)
            Capsule().fill(leather).frame(width: 7, height: 15).offset(x: 18, y: -67)
        }
    }

    private func limb(x: Double, y: Double, width: Double, height: Double, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 8).fill(color.gradient)
            .frame(width: width, height: height).offset(x: x, y: y)
    }
}

private struct CharacterCustomizationView: View {
    @Environment(GameController.self) private var game
    @Environment(\.dismiss) private var dismiss
    @State var skin: CharacterSkinTone
    @State var clothing: CharacterClothingTone

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    PlayerSilhouette(
                        helmet: game.equippedItem(in: .helmet), chest: game.equippedItem(in: .chest),
                        legs: game.equippedItem(in: .legs), boots: game.equippedItem(in: .boots),
                        weapon: game.equippedItem(in: .weapon), shield: game.equippedItem(in: .shield),
                        skinTone: skin, clothingTone: clothing
                    )
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Skin color").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 12) {
                            ForEach(CharacterSkinTone.allCases) { tone in
                                swatch(tone.color, title: tone.title, selected: skin == tone) { skin = tone }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Clothing color").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 12) {
                            ForEach(CharacterClothingTone.allCases) { tone in
                                swatch(tone.color, title: tone.title, selected: clothing == tone) { clothing = tone }
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(GardenPalette.cream.ignoresSafeArea())
            .navigationTitle("Your look")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        game.customizeCharacter(skin: skin, clothing: clothing)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .tint(GardenPalette.moss)
        }
    }

    private func swatch(_ color: Color, title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle().fill(color.gradient)
                .frame(width: 44, height: 44)
                .overlay {
                    if selected {
                        Image(systemName: "checkmark").font(.headline.bold()).foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.6), radius: 2)
                    }
                }
                .padding(3)
                .overlay { Circle().stroke(selected ? GardenPalette.moss : .clear, lineWidth: 2) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
