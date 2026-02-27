//
//  YearContributionGrid.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import SwiftUI

struct YearContributionGrid: View {
    let year: Int
    @EnvironmentObject var viewModel: HabitViewModel
    let onDateTap: (Date) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: HabitTheme.Spacing.sm), count: 3), spacing: HabitTheme.Spacing.sm) {
            ForEach(1...12, id: \.self) { month in
                MonthBlockView(
                    year: year,
                    month: month,
                    onDateTap: onDateTap
                )
            }
        }
    }
}

// MARK: - Month Block View

struct MonthBlockView: View {
    let year: Int
    let month: Int
    @EnvironmentObject var viewModel: HabitViewModel
    let onDateTap: (Date) -> Void

    @Environment(\.colorScheme) private var colorScheme
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: HabitTheme.Spacing.xs) {
            // Month header
            HStack {
                Text(monthName)
                    .font(HabitTheme.Typography.captionMedium)

                Spacer()

                Text("\(completedDays)/\(totalDays)")
                    .font(HabitTheme.Typography.caption2)
                    .foregroundColor(.secondary)
            }

            // Month grid
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 1), count: 7), spacing: 1) {
                ForEach(monthDays, id: \.date) { day in
                    MonthContributionCell(
                        date: day.date,
                        completionCount: day.completionCount,
                        totalHabits: viewModel.habits.count,
                        isToday: calendar.isDateInToday(day.date),
                        isCurrentMonth: day.isCurrentMonth,
                        onTap: {
                            onDateTap(day.date)
                        }
                    )
                }
            }
        }
        .padding(HabitTheme.Spacing.sm)
        .background(HabitTheme.Colors.cardBackground)
        .cornerRadius(HabitTheme.Layout.cornerRadiusSmall)
        .overlay(
            RoundedRectangle(cornerRadius: HabitTheme.Layout.cornerRadiusSmall)
                .stroke(Color(.separator).opacity(0.15), lineWidth: 0.5)
        )
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 12
        let date = calendar.date(from: dateComponents) ?? Date()
        return formatter.string(from: date)
    }

    private var totalDays: Int {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 12
        guard let firstOfMonth = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return 0
        }
        return range.count
    }

    private var completedDays: Int {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 12
        guard let startOfMonth = calendar.date(from: dateComponents) else { return 0 }

        var completedCount = 0
        var currentDate = startOfMonth
        let endDate = calendar.date(from: DateComponents(year: year, month: month + 1, day: 0)) ?? currentDate

        while currentDate <= endDate {
            if getCompletionCount(for: currentDate) > 0 {
                completedCount += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return completedCount
    }

    private var monthDays: [(date: Date, completionCount: Int, isCurrentMonth: Bool)] {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 12

        guard let startOfMonth = calendar.date(from: dateComponents) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: startOfMonth)
        let daysToSubtract = (weekday - 1) % 7
        let gridStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfMonth) ?? startOfMonth

        var dates: [Date] = []
        var currentDate = gridStartDate

        for _ in 0..<42 {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return dates.map { date in
            (date: date,
             completionCount: getCompletionCount(for: date),
             isCurrentMonth: calendar.component(.month, from: date) == month)
        }
    }

    private func getCompletionCount(for date: Date) -> Int {
        let dateKey = viewModel.dateKey(date)
        let completedHabits = viewModel.habitHistory[dateKey] ?? []
        return completedHabits.filter { habitId in
            viewModel.habits.contains { $0.id == habitId }
        }.count
    }
}

// MARK: - Month Contribution Cell

struct MonthContributionCell: View {
    let date: Date
    let completionCount: Int
    let totalHabits: Int
    let isToday: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: HabitTheme.Layout.contributionCellSizeSmall, height: HabitTheme.Layout.contributionCellSizeSmall)
                .overlay(
                    Rectangle()
                        .stroke(isToday && isCurrentMonth ? HabitTheme.Colors.brand : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view details")
    }

    private var backgroundColor: Color {
        if !isCurrentMonth {
            return colorScheme == .dark ? Color(white: 0.12) : Color(.systemGray6)
        }

        let level = HabitTheme.Colors.contributionLevel(completed: completionCount, total: totalHabits)
        return HabitTheme.Colors.contributionColor(level: level, scheme: colorScheme)
    }

    private var accessibilityDescription: String {
        guard isCurrentMonth else { return "Outside current month" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: date)
        if totalHabits == 0 { return "\(dateStr), no habits tracked" }
        let pct = Int(Double(completionCount) / Double(totalHabits) * 100)
        return "\(dateStr), \(pct) percent"
    }
}
