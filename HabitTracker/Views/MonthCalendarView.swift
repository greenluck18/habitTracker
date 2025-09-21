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
    @ObservedObject var viewModel: HabitViewModel
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(year: Int, month: Int, viewModel: HabitViewModel, onDateTap: @escaping (Date) -> Void) {
        self.year = year
        self.month = month
        self.viewModel = viewModel
        self.onDateTap = onDateTap
        dateFormatter.dateFormat = "d"
    }
    
    private var weekdayHeaders: [(id: Int, name: String)] {
        [
            (0, "S"), (1, "M"), (2, "T"), (3, "W"), (4, "T"), (5, "F"), (6, "S")
        ]
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
        let allDays = calendarDays
        return allDays.filter { getCompletionCount(for: $0) > 0 }.count
    }
    
    private var contributionDays: [(date: Date, completionCount: Int)] {
        let allDays = calendarDays
        return allDays.map { date in
            (date: date, completionCount: getCompletionCount(for: date))
        }
    }
    
    private func dayNumber(for date: Date) -> String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
    
    private func dayNumberColor(for date: Date) -> Color {
        let isCurrentMonth = calendar.component(.month, from: date) == month
        let isToday = calendar.isDateInToday(date)
        
        if isToday {
            return .white
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary.opacity(0.5)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Month title and stats
            HStack {
                Text(monthName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(completedDays)/\(totalDays)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdayHeaders, id: \.id) { weekday in
                    Text(weekday.name)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // GitHub-style contribution grid with day numbers
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 1), count: 7), spacing: 1) {
                ForEach(contributionDays, id: \.date) { contributionDay in
                    VStack(spacing: 2) {
                        // Day number
                        Text(dayNumber(for: contributionDay.date))
                            .font(.caption2)
                            .foregroundColor(dayNumberColor(for: contributionDay.date))
                        
                        // Contribution cell
                        ContributionCell(
                            date: contributionDay.date,
                            completionCount: contributionDay.completionCount,
                            totalHabits: viewModel.habits.count,
                            isToday: calendar.isDateInToday(contributionDay.date),
                            onTap: { onDateTap(contributionDay.date) }
                        )
                    }
                }
            }
        }
    }
    
    private var calendarDays: [Date] {
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }
        
        // Get the first day of the week for the first day of the month
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = (firstWeekday - 1) % 7 // Convert to 0-based (Sunday = 0)
        
        // Start from the Sunday of the week containing the first day of the month
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth) else {
            return []
        }
        
        // Generate 42 days (6 weeks) to fill the calendar grid
        var days: [Date] = []
        for i in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func getCompletionCount(for date: Date) -> Int {
        let dateKey = viewModel.dateKey(date)
        let completedHabits = viewModel.habitHistory[dateKey] ?? []
        
        // Filter out habits that no longer exist
        return completedHabits.filter { habitId in
            viewModel.habits.contains { $0.id == habitId }
        }.count
    }
}

// MARK: - Day Cell View

struct DayCellView: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let completionCount: Int
    let totalHabits: Int
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(date: Date, isCurrentMonth: Bool, isToday: Bool, completionCount: Int, totalHabits: Int, onTap: @escaping () -> Void) {
        self.date = date
        self.isCurrentMonth = isCurrentMonth
        self.isToday = isToday
        self.completionCount = completionCount
        self.totalHabits = totalHabits
        self.onTap = onTap
        dateFormatter.dateFormat = "d"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(dateFormatter.string(from: date))
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundColor(textColor)
                
                if totalHabits > 0 {
                    Circle()
                        .fill(cellColor)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(width: 32, height: 32)
            .background(backgroundColor)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else if isToday {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return .blue
        } else if !isCurrentMonth {
            return .clear
        } else {
            return .clear
        }
    }
    
    private var cellColor: Color {
        if totalHabits == 0 {
            return .gray.opacity(0.1)
        }
        
        let completionPercentage = Double(completionCount) / Double(totalHabits)
        
        if completionPercentage == 0 {
            return .gray.opacity(0.1)
        } else if completionPercentage <= 0.2 {
            return Color(red: 0.9, green: 0.95, blue: 0.9)
        } else if completionPercentage <= 0.4 {
            return Color(red: 0.6, green: 0.9, blue: 0.6)
        } else if completionPercentage <= 0.6 {
            return Color(red: 0.3, green: 0.8, blue: 0.3)
        } else if completionPercentage <= 0.8 {
            return Color(red: 0.1, green: 0.7, blue: 0.1)
        } else {
            return Color(red: 0.0, green: 0.6, blue: 0.0)
        }
    }
}

