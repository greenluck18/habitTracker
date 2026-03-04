//
//  CatRoomView.swift
//  HabitTracker
//

import SwiftUI

// MARK: - CatRoomView (top-level coordinator)

struct CatRoomView: View {
    @EnvironmentObject var viewModel: HabitViewModel
    @ObservedObject var catVM: CatViewModel
    @State private var showingNamePrompt = false
    @State private var nameInput = ""

    var body: some View {
        VStack(spacing: 0) {
            headerView
            CatSceneView(catVM: catVM)
                .padding(.horizontal, HabitTheme.Spacing.lg)
                .padding(.top, HabitTheme.Spacing.xs)
                .padding(.bottom, HabitTheme.Spacing.sm)
            InventoryView(catVM: catVM)
        }
        .onAppear {
            if catVM.needsName { showingNamePrompt = true }
            catVM.startIdleAnimations()
        }
        .onDisappear {
            catVM.stopIdleAnimations()
        }
        .sheet(isPresented: $showingNamePrompt) {
            NamePromptSheet(catVM: catVM, nameInput: $nameInput)
        }
    }

    private var headerView: some View {
        HStack(spacing: HabitTheme.Spacing.sm) {
            if !catVM.profile.name.isEmpty {
                Text(catVM.profile.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text("·")
                    .foregroundColor(.secondary)
                Text(catVM.catState.label)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            if catVM.effectiveStreak > 0 {
                Label("Day \(catVM.effectiveStreak)", systemImage: "flame.fill")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(HabitTheme.Colors.brand)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(HabitTheme.Colors.brand.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, HabitTheme.Spacing.lg)
        .padding(.top, HabitTheme.Spacing.sm)
        .padding(.bottom, HabitTheme.Spacing.xs)
    }
}

// MARK: - Name Prompt Sheet

private struct NamePromptSheet: View {
    @ObservedObject var catVM: CatViewModel
    @Binding var nameInput: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: HabitTheme.Spacing.xl) {
                Spacer()
                // Animated cat preview
                CatView(catState: .peeking, animationState: .idle)
                    .frame(width: 110, height: 150)
                    .scaleEffect(1.4)
                    .padding(.bottom, HabitTheme.Spacing.md)

                VStack(spacing: HabitTheme.Spacing.sm) {
                    Text("Meet your cat!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("Give your companion a name.\nComplete habits daily to help them grow!")
                        .font(HabitTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HabitTheme.Spacing.xl)
                }

                TextField("Cat's name", text: $nameInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 18, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HabitTheme.Spacing.xl)
                    .limitInputLength(value: $nameInput, length: 20)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        catVM.setName(trimmed.isEmpty ? "Kitty" : trimmed)
                        dismiss()
                    }
                    .font(HabitTheme.Typography.bodyMedium)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - CatSceneView (room + cat + items + sparkles)

struct CatSceneView: View {
    @ObservedObject var catVM: CatViewModel
    private let sceneHeight: CGFloat = 296

    var body: some View {
        GeometryReader { geo in
            ZStack {
                roomBackground(size: geo.size)

                // Placed room items
                ForEach(catVM.profile.placedItems) { item in
                    RoomItemView(item: item, catVM: catVM, sceneSize: geo.size)
                }

                // Cat character
                CatView(catState: catVM.catState, animationState: catVM.animationState)
                    .frame(width: 110, height: 150)
                    .position(
                        x: catVM.catPositionX * geo.size.width,
                        y: geo.size.height * 0.68
                    )
                    .animation(.spring(response: 1.2, dampingFraction: 0.75), value: catVM.catPositionX)

                // Sparkle burst overlay
                sparkleOverlay(size: geo.size)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: sceneHeight)
        .clipShape(RoundedRectangle(cornerRadius: HabitTheme.Layout.cornerRadius))
    }

    // MARK: Room Background

    private func roomBackground(size: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            // Wall
            LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.92, blue: 0.97),
                    Color(red: 0.82, green: 0.87, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // Floor/wall divider
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color(red: 0.62, green: 0.50, blue: 0.38).opacity(0.55))
                    .frame(height: 2)
                // Floor
                LinearGradient(
                    colors: [
                        Color(red: 0.80, green: 0.68, blue: 0.53),
                        Color(red: 0.72, green: 0.60, blue: 0.46)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: size.height * 0.35)
            }
        }
    }

    // MARK: Sparkle Overlay

    private func sparkleOverlay(size: CGSize) -> some View {
        let sparkleColors: [Color] = [.yellow, .orange, .pink, .purple, .cyan, .green, .yellow, .orange]
        let catX = catVM.catPositionX * size.width
        let catY = size.height * 0.58

        return ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * .pi / 4
                SparkleShape()
                    .fill(sparkleColors[i])
                    .frame(width: 14, height: 14)
                    .offset(
                        x: catVM.showSparkles ? CGFloat(cos(angle)) * 62 : 0,
                        y: catVM.showSparkles ? CGFloat(sin(angle)) * 62 : 0
                    )
                    .opacity(catVM.showSparkles ? 1 : 0)
                    .scaleEffect(catVM.showSparkles ? 1 : 0.1)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.03),
                        value: catVM.showSparkles
                    )
            }
        }
        .position(x: catX, y: catY)
    }
}

// MARK: - RoomItemView (draggable item in scene)

struct RoomItemView: View {
    let item: PlacedItem
    @ObservedObject var catVM: CatViewModel
    let sceneSize: CGSize

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        Text(item.milestone.emoji)
            .font(.system(size: 40))
            .shadow(color: .black.opacity(isDragging ? 0.18 : 0), radius: 8, y: 4)
            .scaleEffect(isDragging ? 1.18 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        let newX = (item.normalizedX * sceneSize.width + value.translation.width) / sceneSize.width
                        let newY = (item.normalizedY * sceneSize.height + value.translation.height) / sceneSize.height
                        if item.milestone == .ball {
                            catVM.ballThrown(toNormalizedX: newX)
                        }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                            catVM.moveItem(id: item.id, normalizedX: newX, normalizedY: newY)
                        }
                        dragOffset = .zero
                        HabitTheme.Haptics.selection()
                    }
            )
            .position(
                x: item.normalizedX * sceneSize.width + dragOffset.width,
                y: item.normalizedY * sceneSize.height + dragOffset.height
            )
            .accessibilityLabel("\(item.milestone.displayName) in room, drag to reposition")
    }
}

// MARK: - InventoryView (bottom item bar)

struct InventoryView: View {
    @ObservedObject var catVM: CatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: HabitTheme.Spacing.xs) {
            Text("Items")
                .font(HabitTheme.Typography.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, HabitTheme.Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HabitTheme.Spacing.md) {
                    ForEach(CatMilestone.allCases) { milestone in
                        InventoryItemCell(
                            milestone: milestone,
                            isUnlocked: catVM.unlockedMilestones.contains(milestone),
                            isPlaced: catVM.isPlaced(milestone),
                            onTap: {
                                if catVM.unlockedMilestones.contains(milestone) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        catVM.toggleItem(milestone)
                                    }
                                    HabitTheme.Haptics.selection()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, HabitTheme.Spacing.lg)
                .padding(.vertical, HabitTheme.Spacing.xs)
            }
        }
    }
}

private struct InventoryItemCell: View {
    let milestone: CatMilestone
    let isUnlocked: Bool
    let isPlaced: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HabitTheme.Spacing.xs) {
                ZStack(alignment: .topTrailing) {
                    Text(milestone.emoji)
                        .font(.system(size: 34))
                        .opacity(isUnlocked ? 1 : 0.32)
                        .saturation(isUnlocked ? 1 : 0)

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(3)
                    } else if isPlaced {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(HabitTheme.Colors.success)
                            .background(Circle().fill(Color.white).padding(1))
                    }
                }
                .frame(width: 44, height: 44)

                if isUnlocked {
                    Text(milestone.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isPlaced ? HabitTheme.Colors.brand : .primary)
                        .lineLimit(1)
                } else {
                    Text("Day \(milestone.requiredStreak)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 72, height: 76)
            .background(
                RoundedRectangle(cornerRadius: HabitTheme.Layout.cornerRadiusSmall)
                    .fill(isPlaced
                          ? HabitTheme.Colors.brand.opacity(0.10)
                          : HabitTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HabitTheme.Layout.cornerRadiusSmall)
                    .stroke(isPlaced ? HabitTheme.Colors.brand.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .accessibilityLabel(
            isUnlocked
                ? "\(milestone.displayName), \(isPlaced ? "placed in room, tap to remove" : "tap to place in room")"
                : "\(milestone.displayName), locked until day \(milestone.requiredStreak)"
        )
    }
}

// MARK: - CatView (SwiftUI-drawn animated cat)

struct CatView: View {
    let catState: CatState
    let animationState: CatAnimationState

    // Animated state properties
    @State private var eyeScaleY: CGFloat = 1.0
    @State private var tailAngle: Double = 0
    @State private var lookOffset: CGFloat = 0
    @State private var jumpOffset: CGFloat = 0
    @State private var bodyPulse: CGFloat = 1.0

    // Cat color palette
    private let furMain    = Color(red: 0.84, green: 0.74, blue: 0.58)
    private let furDark    = Color(red: 0.66, green: 0.54, blue: 0.40)
    private let innerEar   = Color(red: 0.96, green: 0.76, blue: 0.80)
    private let noseColor  = Color(red: 0.91, green: 0.56, blue: 0.66)
    private let bellyColor = Color(red: 0.97, green: 0.93, blue: 0.85)
    private let boxColor   = Color(red: 0.70, green: 0.50, blue: 0.30)
    private let boxDark    = Color(red: 0.54, green: 0.36, blue: 0.18)

    var body: some View {
        ZStack {
            switch catState {
            case .inBox:
                inBoxView
            case .peeking:
                peekingView
            case .outOfBox, .idle:
                fullCatView
            }

            // Zzz overlay
            if animationState == .sleeping {
                ZzzView()
                    .offset(x: 38, y: -28)
                    .transition(.opacity)
            }
        }
        .frame(width: 110, height: 150)
        .offset(y: jumpOffset)
        .onChange(of: animationState) { _, newState in
            applyAnimation(newState)
        }
        .onAppear {
            applyAnimation(animationState)
        }
    }

    // MARK: - State Renders

    private var inBoxView: some View {
        ZStack {
            // Box
            boxView
            // Only ears poking above box
            earGroup(offset: CGPoint(x: 55, y: 55))
        }
    }

    private var peekingView: some View {
        ZStack {
            // Head behind box
            headView(at: CGPoint(x: 55, y: 58))
            // Box overlays lower part of head
            boxView
            // Ears above everything
            earGroup(offset: CGPoint(x: 55, y: 58))
        }
    }

    private var fullCatView: some View {
        ZStack {
            // Tail (behind body)
            tailView
            // Body
            bodyView
            // Head on top
            headView(at: CGPoint(x: 55, y: 46))
            // Ears
            earGroup(offset: CGPoint(x: 55, y: 46))
        }
    }

    // MARK: - Sub-views

    private var boxView: some View {
        ZStack {
            // Box body
            RoundedRectangle(cornerRadius: 6)
                .fill(boxColor)
                .frame(width: 90, height: 62)
            // Darker top strip
            Rectangle()
                .fill(boxDark.opacity(0.55))
                .frame(width: 90, height: 7)
                .offset(y: -27.5)
            // Left flap
            RoundedRectangle(cornerRadius: 3)
                .fill(boxColor.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 3).stroke(boxDark.opacity(0.3), lineWidth: 1)
                )
                .frame(width: 46, height: 8)
                .rotationEffect(.degrees(-9), anchor: .trailing)
                .offset(x: -22, y: -30)
            // Right flap
            RoundedRectangle(cornerRadius: 3)
                .fill(boxColor.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 3).stroke(boxDark.opacity(0.3), lineWidth: 1)
                )
                .frame(width: 46, height: 8)
                .rotationEffect(.degrees(9), anchor: .leading)
                .offset(x: 22, y: -30)
        }
        .position(x: 55, y: 107)
    }

    private func earGroup(offset: CGPoint) -> some View {
        ZStack {
            singleEar.position(x: offset.x - 20, y: offset.y - 28)
            singleEar.position(x: offset.x + 20, y: offset.y - 28)
        }
    }

    private var singleEar: some View {
        ZStack {
            EarShape()
                .fill(furMain)
                .frame(width: 22, height: 24)
            EarShape()
                .fill(innerEar)
                .frame(width: 12, height: 14)
                .offset(y: 4)
        }
    }

    private func headView(at point: CGPoint) -> some View {
        ZStack {
            // Head circle
            Circle()
                .fill(furMain)
                .frame(width: 54, height: 54)

            // Subtle head stripes
            RoundedRectangle(cornerRadius: 2)
                .fill(furDark.opacity(0.32))
                .frame(width: 5, height: 13)
                .rotationEffect(.degrees(8))
                .offset(x: -9, y: -10)
            RoundedRectangle(cornerRadius: 2)
                .fill(furDark.opacity(0.32))
                .frame(width: 5, height: 13)
                .rotationEffect(.degrees(-8))
                .offset(x: 9, y: -10)
            RoundedRectangle(cornerRadius: 2)
                .fill(furDark.opacity(0.25))
                .frame(width: 4, height: 10)
                .offset(y: -16)

            // Eyes
            eyeView(xOffset: -13 + lookOffset, yOffset: -1)
            eyeView(xOffset: 13 + lookOffset, yOffset: -1)

            // Nose
            Ellipse()
                .fill(noseColor)
                .frame(width: 8, height: 6)
                .offset(y: 11)

            // Whiskers
            whiskerLine(xOff: -23, yOff: 5, angle: 7)
            whiskerLine(xOff: -23, yOff: 12, angle: -7)
            whiskerLine(xOff: 23, yOff: 5, angle: -7)
            whiskerLine(xOff: 23, yOff: 12, angle: 7)
        }
        .position(x: point.x, y: point.y)
    }

    @ViewBuilder
    private func eyeView(xOffset: CGFloat, yOffset: CGFloat) -> some View {
        if animationState == .sleeping {
            // × eyes
            ZStack {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 9, height: 2.5)
                    .rotationEffect(.degrees(45))
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 9, height: 2.5)
                    .rotationEffect(.degrees(-45))
            }
            .offset(x: xOffset, y: yOffset)
        } else if animationState == .happy {
            // ^ eyes (upward arc = happy squint)
            Path { p in
                p.move(to: CGPoint(x: 0, y: 6))
                p.addQuadCurve(to: CGPoint(x: 11, y: 6), control: CGPoint(x: 5.5, y: -1))
            }
            .stroke(Color.black, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 11, height: 8)
            .offset(x: xOffset - 5.5, y: yOffset - 3)
        } else {
            // Normal blinkable eye
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 10, height: 10)
                    .scaleEffect(y: eyeScaleY)
                // Eye shine
                Circle()
                    .fill(Color.white)
                    .frame(width: 3.5, height: 3.5)
                    .scaleEffect(y: eyeScaleY)
                    .offset(x: 2.5, y: -2)
            }
            .offset(x: xOffset, y: yOffset)
        }
    }

    private func whiskerLine(xOff: CGFloat, yOff: CGFloat, angle: Double) -> some View {
        RoundedRectangle(cornerRadius: 0.5)
            .fill(Color(white: 0.5).opacity(0.65))
            .frame(width: 20, height: 1.5)
            .rotationEffect(.degrees(angle))
            .offset(x: xOff, y: yOff)
    }

    private var bodyView: some View {
        ZStack {
            // Body
            Capsule()
                .fill(furMain)
                .frame(width: 46, height: 64)
                .scaleEffect(bodyPulse)
            // Belly
            Ellipse()
                .fill(bellyColor)
                .frame(width: 28, height: 42)
                .offset(y: 4)
            // Body stripes
            RoundedRectangle(cornerRadius: 2)
                .fill(furDark.opacity(0.28))
                .frame(width: 5, height: 22)
                .offset(x: -10, y: -4)
            RoundedRectangle(cornerRadius: 2)
                .fill(furDark.opacity(0.28))
                .frame(width: 5, height: 22)
                .offset(x: 10, y: -4)
        }
        .position(x: 55, y: 100)
    }

    private var tailView: some View {
        TailShape()
            .stroke(furMain, style: StrokeStyle(lineWidth: 11, lineCap: .round))
            .frame(width: 52, height: 44)
            .rotationEffect(.degrees(tailAngle), anchor: UnitPoint(x: 0.05, y: 0.95))
            .position(x: 82, y: 114)
    }

    // MARK: - Animation Logic

    private func applyAnimation(_ state: CatAnimationState) {
        switch state {
        case .idle:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                eyeScaleY = 1.0
                tailAngle = 0
                lookOffset = 0
                jumpOffset = 0
                bodyPulse = 1.0
            }

        case .blinking:
            withAnimation(.easeInOut(duration: 0.11)) { eyeScaleY = 0.05 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                withAnimation(.easeOut(duration: 0.13)) { eyeScaleY = 1.0 }
            }

        case .waggingTail:
            withAnimation(.easeInOut(duration: 0.22).repeatCount(6, autoreverses: true)) {
                tailAngle = 26
            }

        case .lookingLeft:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { lookOffset = -7 }

        case .lookingRight:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { lookOffset = 7 }

        case .happy:
            // Quick jump
            withAnimation(.spring(response: 0.22, dampingFraction: 0.42)) { jumpOffset = -30 }
            withAnimation(.easeInOut(duration: 0.2).delay(0.05).repeatCount(3, autoreverses: true)) {
                bodyPulse = 1.06
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.6)) {
                    jumpOffset = 0
                    bodyPulse = 1.0
                }
            }

        case .sleeping:
            // Eyes handled by eyeView switch; sleeping state shows ZzzView overlay
            withAnimation(.easeInOut(duration: 0.3)) { eyeScaleY = 1.0 }
        }
    }
}

// MARK: - ZzzView (floating sleep indicator)

private struct ZzzView: View {
    @State private var animating = false

    var body: some View {
        VStack(spacing: -2) {
            Text("z")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .opacity(animating ? 0 : 0.55)
                .offset(y: animating ? -16 : 0)
            Text("z")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .opacity(animating ? 0 : 0.70)
                .offset(y: animating ? -20 : 0)
            Text("Z")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .opacity(animating ? 0 : 0.85)
                .offset(y: animating ? -24 : 0)
        }
        .foregroundColor(.indigo.opacity(0.85))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false)) {
                animating = true
            }
        }
    }
}

// MARK: - Custom Shapes

struct EarShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 4, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX + 18, y: rect.maxY - 4)
        )
        return p
    }
}

struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) * 0.5
        let innerR = outerR * 0.42
        let points = 6
        var p = Path()
        for i in 0..<(points * 2) {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let r = i.isMultiple(of: 2) ? outerR : innerR
            let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * r,
                             y: center.y + CGFloat(sin(angle)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}
