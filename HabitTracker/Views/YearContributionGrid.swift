//
//  YearContributionGrid.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import SwiftUI

struct YearContributionGrid: View {
    let year: Int
    @ObservedObject var viewModel: HabitViewModel
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(1...12, id: \.self) { month in
                MonthBlockView(
                    year: year,
                    month: month,
                    viewModel: viewModel,
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
    @ObservedObject var viewModel: HabitViewModel
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Month header
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
            HStack(spacing: 1) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Month grid
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 1), count: 7), spacing: 1) {
                ForEach(monthDays, id: \.date) { day in
                    MonthContributionCell(
                        date: day.date,
                        completionCount: day.completionCount,
                        totalHabits: viewModel.habits.count,
                        isToday: calendar.isDateInToday(day.date),
                        onTap: { 
                            onDateTap(day.date) 
                        }
                    )
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        // Create date components for the first day of the month in local timezone
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 12 // Set to noon to avoid timezone issues
        dateComponents.minute = 0
        dateComponents.second = 0
        
        let date = calendar.date(from: dateComponents) ?? Date()
        return formatter.string(from: date)
    }
    
    private var totalDays: Int {
        // Create date components for the first day of the month in local timezone
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 12 // Set to noon to avoid timezone issues
        dateComponents.minute = 0
        dateComponents.second = 0
        
        guard let firstOfMonth = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return 0
        }
        return range.count
    }
    
    private var completedDays: Int {
        // Create date components for the first day of the month in local timezone
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 12 // Set to noon to avoid timezone issues
        dateComponents.minute = 0
        dateComponents.second = 0
        
        guard let startOfMonth = calendar.date(from: dateComponents),
              let _ = calendar.date(from: DateComponents(year: year, month: month + 1, day: 0)) else {
            return 0
        }
        
        var completedCount = 0
        var currentDate = startOfMonth
        
        while currentDate <= calendar.date(from: DateComponents(year: year, month: month + 1, day: 0)) ?? currentDate {
            let completionCount = getCompletionCount(for: currentDate)
            if completionCount > 0 {
                completedCount += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return completedCount
    }
    
    private var monthDays: [(date: Date, completionCount: Int)] {
        // Create date components for the first day of the month in local timezone
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 12 // Set to noon to avoid timezone issues
        dateComponents.minute = 0
        dateComponents.second = 0
        
        guard let startOfMonth = calendar.date(from: dateComponents),
              let _ = calendar.date(from: DateComponents(year: year, month: month + 1, day: 0)) else {
            return []
        }
        
        // Find the Sunday of the week containing startOfMonth
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let daysToSubtract = (weekday - 1) % 7
        let gridStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfMonth) ?? startOfMonth
        
        var dates: [Date] = []
        var currentDate = gridStartDate
        
        // Generate 6 weeks worth of dates (42 days) to fill the calendar grid
        for _ in 0..<42 {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates.map { date in
            let completionCount = getCompletionCount(for: date)
            return (date: date, completionCount: completionCount)
        }
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

// MARK: - Month Contribution Cell

struct MonthContributionCell: View {
    let date: Date
    let completionCount: Int
    let totalHabits: Int
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Rectangle()
                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if completionCount == 0 {
            return Color(.systemGray5)
        } else if completionCount == 1 {
            return Color.green.opacity(0.3)
        } else if completionCount == 2 {
            return Color.green.opacity(0.6)
        } else if completionCount == 3 {
            return Color.green.opacity(0.8)
        } else {
            return Color.green
        }
    }
}