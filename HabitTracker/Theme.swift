//
//  Theme.swift
//  HabitTracker
//

import SwiftUI

// MARK: - Design System

enum HabitTheme {

    // MARK: - Colors

    enum Colors {

        // Brand - Electric Violet
        static let brand = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.38, blue: 1.0, alpha: 1.0)   // #9460FF
            : UIColor(red: 0.46, green: 0.18, blue: 1.0, alpha: 1.0)   // #762DFF
        })

        static let brandSoft = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.38, blue: 1.0, alpha: 0.18)
            : UIColor(red: 0.46, green: 0.18, blue: 1.0, alpha: 0.10)
        })

        // Streak - Electric Orange-Red
        static let streak = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.35, blue: 0.20, alpha: 1.0)   // #FF5933
            : UIColor(red: 1.0, green: 0.24, blue: 0.10, alpha: 1.0)   // #FF3D1A
        })

        static let streakSoft = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.35, blue: 0.20, alpha: 0.15)
            : UIColor(red: 1.0, green: 0.24, blue: 0.10, alpha: 0.10)
        })

        // Success - Vivid Emerald
        static let success = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.00, green: 0.90, blue: 0.50, alpha: 1.0)  // #00E580
            : UIColor(red: 0.00, green: 0.76, blue: 0.40, alpha: 1.0)  // #00C266
        })

        static let successSoft = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.00, green: 0.90, blue: 0.50, alpha: 0.14)
            : UIColor(red: 0.00, green: 0.76, blue: 0.40, alpha: 0.09)
        })

        // Surfaces
        static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
        static let surface = Color(uiColor: .systemGroupedBackground)

        // Contribution Grid Scale (6 levels) - vivid green ramp
        static func contributionColor(level: Int, scheme: ColorScheme) -> Color {
            let isDark = scheme == .dark
            switch level {
            case 0:
                return isDark ? Color(white: 0.13) : Color(uiColor: .systemGray5)
            case 1:
                // Pale lime
                return isDark
                ? Color(red: 0.04, green: 0.40, blue: 0.22)
                : Color(red: 0.72, green: 0.98, blue: 0.80)
            case 2:
                // Bright mint
                return isDark
                ? Color(red: 0.02, green: 0.58, blue: 0.32)
                : Color(red: 0.35, green: 0.92, blue: 0.56)
            case 3:
                // Vivid green
                return isDark
                ? Color(red: 0.00, green: 0.72, blue: 0.40)
                : Color(red: 0.10, green: 0.82, blue: 0.44)
            case 4:
                // Electric emerald
                return isDark
                ? Color(red: 0.00, green: 0.84, blue: 0.46)
                : Color(red: 0.00, green: 0.73, blue: 0.38)
            default:
                // Full-blast neon green
                return isDark
                ? Color(red: 0.20, green: 1.00, blue: 0.56)
                : Color(red: 0.00, green: 0.62, blue: 0.30)
            }
        }

        static func contributionLevel(completed: Int, total: Int) -> Int {
            guard total > 0, completed > 0 else { return 0 }
            let pct = Double(completed) / Double(total)
            if pct <= 0.2 { return 1 }
            if pct <= 0.4 { return 2 }
            if pct <= 0.6 { return 3 }
            if pct <= 0.8 { return 4 }
            return 5
        }
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title2, design: .rounded).weight(.semibold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
        static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
        static let body = Font.system(.body, design: .rounded)
        static let bodyMedium = Font.system(.body, design: .rounded).weight(.medium)
        static let subheadline = Font.system(.subheadline, design: .rounded)
        static let subheadlineMedium = Font.system(.subheadline, design: .rounded).weight(.medium)
        static let caption = Font.system(.caption, design: .rounded)
        static let captionMedium = Font.system(.caption, design: .rounded).weight(.medium)
        static let caption2 = Font.system(.caption2, design: .rounded)
        static let stat = Font.system(size: 28, weight: .bold, design: .rounded)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Layout

    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let cornerRadiusSmall: CGFloat = 10
        static let cornerRadiusTiny: CGFloat = 6
        static let cardShadowRadius: CGFloat = 8
        static let cardShadowY: CGFloat = 2
        static let minTouchTarget: CGFloat = 44
        static let contributionCellSize: CGFloat = 20
        static let contributionCellSizeSmall: CGFloat = 12
    }

    // MARK: - Haptics

    enum Haptics {
        static func toggle() {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        static func success() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        static func selection() {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    // MARK: - Helpers

    static var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    static func motivationalText(completed: Int, total: Int) -> String {
        guard total > 0 else { return "Start building your habits" }
        let pct = Double(completed) / Double(total)
        switch pct {
        case 0: return "Let's get started!"
        case ..<0.5: return "You're building momentum"
        case ..<1.0: return "Almost there, keep going!"
        default: return "Perfect day!"
        }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 100
    var lineWidth: CGFloat = 10

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    HabitTheme.Colors.success,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(animatedProgress * 100))%")
                    .font(HabitTheme.Typography.stat)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var isHighlighted: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: HabitTheme.Layout.cornerRadius)
                    .fill(isHighlighted ? HabitTheme.Colors.successSoft : HabitTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HabitTheme.Layout.cornerRadius)
                    .stroke(
                        isHighlighted
                        ? HabitTheme.Colors.success.opacity(0.3)
                        : Color(.separator).opacity(0.2),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: colorScheme == .dark ? .clear : Color.black.opacity(0.04),
                radius: HabitTheme.Layout.cardShadowRadius,
                y: HabitTheme.Layout.cardShadowY
            )
    }
}

extension View {
    func cardStyle(isHighlighted: Bool = false) -> some View {
        modifier(CardStyle(isHighlighted: isHighlighted))
    }
}
