//
//  MonthCalendarView.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import SwiftUI

// MARK: - Month Calendar View

struct MonthCalendarView: View {
    let year: Int
    let month: Int
    @EnvironmentObject var viewModel: HabitViewModel
    let onDateTap: (Date) -> Void

    private let calendar = Calendar.current

    private var weekdayHeaders: [(id: Int, name: String)] {
        [(0, "M"), (1, "T"), (2, "W"), (3, "T"), (4, "F"), (5, "S"), (6, "S")]
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let date = calendar.date(from: DateComponents(year: year, month: month)) ?? Date()
        return formatter.string(from: date)
    }

    private var totalDays: Int {
        guard let range = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()) else {
            return 0
        }
        return range.count
    }

    private var completedDays: Int {
        calendarDays.filter { getCompletionCount(for: $0) > 0 }.count
    }

    private var contributionDays: [(date: Date, completionCount: Int)] {
        calendarDays.map { date in
            (date: date, completionCount: getCompletionCount(for: date))
        }
    }

    private func dayNumber(for date: Date) -> String {
        "\(calendar.component(.day, from: date))"
    }

    private func dayNumberColor(for date: Date) -> Color {
        let isCurrentMonth = calendar.component(.month, from: date) == month
        let isToday = calendar.isDateInToday(date)

        if isToday {
            return .white
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary.opacity(0.4)
        }
    }

    var body: some View {
        VStack(spacing: HabitTheme.Spacing.sm) {
            // Month title and stats
            HStack {
                Text(monthName)
                    .font(HabitTheme.Typography.headline)

                Spacer()

                Text("\(completedDays)/\(totalDays)")
                    .font(HabitTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdayHeaders, id: \.id) { weekday in
                    Text(weekday.name)
                        .font(HabitTheme.Typography.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 1), count: 7), spacing: 1) {
                ForEach(contributionDays, id: \.date) { contributionDay in
                    VStack(spacing: 2) {
                        Text(dayNumber(for: contributionDay.date))
                            .font(HabitTheme.Typography.caption2)
                            .foregroundColor(dayNumberColor(for: contributionDay.date))

                        ContributionCell(
                            date: contributionDay.date,
                            completionCount: contributionDay.completionCount,
                            totalHabits: viewModel.habits.count,
                            isToday: calendar.isDateInToday(contributionDay.date),
                            onTap: {
                                onDateTap(contributionDay.date)
                            }
                        )
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: - Calendar Data

    private var calendarDays: [Date] {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 12
        dateComponents.minute = 0
        dateComponents.second = 0

        guard let firstOfMonth = calendar.date(from: dateComponents) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let mondayOffset = (weekday + 5) % 7
        let gridStartDate = calendar.date(byAdding: .day, value: -mondayOffset, to: firstOfMonth) ?? firstOfMonth

        var dates: [Date] = []
        var currentDate = gridStartDate

        for _ in 0..<42 {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return dates
    }

    private func getCompletionCount(for date: Date) -> Int {
        let dateKey = viewModel.dateKey(date)
        let completedHabits = viewModel.habitHistory[dateKey] ?? []
        return completedHabits.filter { habitId in
            viewModel.habits.contains { $0.id == habitId }
        }.count
    }
}
