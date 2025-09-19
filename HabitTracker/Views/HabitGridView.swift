//
//  HabitGridView.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import SwiftUI

struct HabitGridView: View {
    @EnvironmentObject var viewModel: HabitViewModel
    @State private var selectedDate: Date?
    @State private var showingDateDetail = false
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showingYearSelector = false
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateFormat = "MMM d, yyyy"
    }

    var body: some View {
        VStack(spacing: 16) {
            // Current date and stats header
            VStack(spacing: 8) {
                Text("Today: \(dateFormatter.string(from: Date()))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                let todayCount = viewModel.habitHistory[dateKey(Date())]?.count ?? 0
                let totalHabits = viewModel.habits.count
                Text("\(todayCount)/\(totalHabits) habits completed today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if totalHabits > 0 {
                    ProgressView(value: Double(todayCount), total: Double(totalHabits))
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(height: 8)
                }
            }
            .padding(.horizontal)
            
            // Year selector
            HStack {
                Button(action: {
                    showingYearSelector = true
                }) {
                    HStack {
                        Text("\(selectedYear)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Year navigation buttons
                HStack(spacing: 12) {
                    Button(action: {
                        selectedYear -= 1
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        selectedYear += 1
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            
            // Monthly blocks grid (3x4 layout)
            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 8), count: 3), spacing: 12) {
                    ForEach(1...12, id: \.self) { month in
                        MonthBlockView(
                            year: selectedYear,
                            month: month,
                            viewModel: viewModel,
                            onDateTap: { date in
                                selectedDate = date
                                showingDateDetail = true
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Legend
            HStack {
                Text("Less")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    ForEach(0..<6) { level in
                        Rectangle()
                            .fill(contributionColor(for: level, totalHabits: viewModel.habits.count))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                    }
                }
                
                Text("More")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Progress")
        .sheet(isPresented: $showingDateDetail) {
            if let selectedDate = selectedDate {
                DateDetailView(
                    date: selectedDate,
                    viewModel: viewModel,
                    isPresented: $showingDateDetail
                )
            }
        }
        .sheet(isPresented: $showingYearSelector) {
            YearSelectorView(selectedYear: $selectedYear, isPresented: $showingYearSelector)
        }
    }
    
    private func generateContributionDatesForYear(_ year: Int) -> [Date] {
        // Create start and end dates for the year
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()
        let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? Date()
        
        // Find the Sunday of the week containing startOfYear
        let weekday = calendar.component(.weekday, from: startOfYear)
        let daysToSubtract = (weekday - 1) % 7
        let gridStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfYear) ?? startOfYear
        
        var dates: [Date] = []
        var currentDate = gridStartDate
        
        // Generate dates for the entire year grid (including partial weeks)
        while currentDate <= endOfYear {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    private func monthLabelsForYear(_ year: Int) -> [String] {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        
        var labels: [String] = []
        for month in 1...12 {
            if let monthDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)) {
                labels.append(monthFormatter.string(from: monthDate))
            }
        }
        
        return labels
    }
    
    private func dayLabel(for dayIndex: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[dayIndex]
    }
    
    private func contributionColor(for level: Int, totalHabits: Int) -> Color {
        if totalHabits == 0 {
            return Color.gray.opacity(0.1)
        }
        
        // GitHub-style color progression
        switch level {
        case 0:
            return Color.gray.opacity(0.1) // No habits completed
        case 1:
            return Color(red: 0.9, green: 0.95, blue: 0.9) // Very light green (1 habit)
        case 2:
            return Color(red: 0.6, green: 0.9, blue: 0.6) // Light green (2 habits)
        case 3:
            return Color(red: 0.3, green: 0.8, blue: 0.3) // Medium green (3 habits)
        case 4:
            return Color(red: 0.1, green: 0.7, blue: 0.1) // Dark green (4+ habits)
        default:
            return Color(red: 0.0, green: 0.6, blue: 0.0) // Super dark green (5+ habits)
        }
    }
    
    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct ContributionCell: View {
    let date: Date
    let completionCount: Int
    let totalHabits: Int
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 3)
                .fill(cellColor)
                .frame(width: 20, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cellColor: Color {
        if totalHabits == 0 {
            return Color.gray.opacity(0.1)
        }
        
        // Calculate completion level based on percentage
        let completionPercentage = Double(completionCount) / Double(totalHabits)
        let level: Int
        
        if completionPercentage == 0 {
            level = 0
        } else if completionPercentage <= 0.2 {
            level = 1 // 1 habit or 20%
        } else if completionPercentage <= 0.4 {
            level = 2 // 2 habits or 40%
        } else if completionPercentage <= 0.6 {
            level = 3 // 3 habits or 60%
        } else if completionPercentage <= 0.8 {
            level = 4 // 4 habits or 80%
        } else {
            level = 5 // 5+ habits or 100%
        }
        
        // GitHub-style color progression
        switch level {
        case 0:
            return Color.gray.opacity(0.1) // No habits completed
        case 1:
            return Color(red: 0.9, green: 0.95, blue: 0.9) // Very light green
        case 2:
            return Color(red: 0.6, green: 0.9, blue: 0.6) // Light green
        case 3:
            return Color(red: 0.3, green: 0.8, blue: 0.3) // Medium green
        case 4:
            return Color(red: 0.1, green: 0.7, blue: 0.1) // Dark green
        default:
            return Color(red: 0.0, green: 0.6, blue: 0.0) // Super dark green
        }
    }
}

struct MonthBlockView: View {
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
        dateFormatter.dateFormat = "MMM"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header
            HStack {
                Text(dateFormatter.string(from: monthDate))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Month completion stats
                let monthStats = getMonthStats()
                if monthStats.totalDays > 0 {
                    Text("\(monthStats.completedDays)/\(monthStats.totalDays)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            // Calendar grid inside the month block
            VStack(spacing: 2) {
                // Day labels row
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        Text(dayLabel(for: dayIndex))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 12)
                    }
                }
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 1), count: 7), spacing: 1) {
                    ForEach(generateMonthDates(), id: \.self) { date in
                        MonthContributionCell(
                            date: date,
                            completionCount: viewModel.habitHistory[dateKey(date)]?.count ?? 0,
                            totalHabits: viewModel.habits.count,
                            isToday: calendar.isDateInToday(date),
                            isCurrentMonth: calendar.component(.month, from: date) == month,
                            onTap: {
                                onDateTap(date)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var monthDate: Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
    }
    
    private func generateMonthDates() -> [Date] {
        guard let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endOfMonth = calendar.date(from: DateComponents(year: year, month: month + 1, day: 0)) else {
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
        
        return dates
    }
    
    private func dayLabel(for dayIndex: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[dayIndex]
    }
    
    private func getMonthStats() -> (completedDays: Int, totalDays: Int) {
        guard let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endOfMonth = calendar.date(from: DateComponents(year: year, month: month + 1, day: 0)) else {
            return (0, 0)
        }
        
        var completedDays = 0
        var currentDate = startOfMonth
        
        while currentDate <= endOfMonth {
            let key = dateKey(currentDate)
            if let completedHabits = viewModel.habitHistory[key], !completedHabits.isEmpty {
                completedDays += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        let totalDays = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 0
        return (completedDays: completedDays, totalDays: totalDays)
    }
    
    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct MonthContributionCell: View {
    let date: Date
    let completionCount: Int
    let totalHabits: Int
    let isToday: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 2)
                .fill(cellColor)
                .frame(width: 14, height: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }
    
    private var cellColor: Color {
        if !isCurrentMonth {
            return Color.gray.opacity(0.1)
        }
        
        if totalHabits == 0 {
            return Color.gray.opacity(0.1)
        }
        
        // Calculate completion level based on percentage
        let completionPercentage = Double(completionCount) / Double(totalHabits)
        let level: Int
        
        if completionPercentage == 0 {
            level = 0
        } else if completionPercentage <= 0.2 {
            level = 1
        } else if completionPercentage <= 0.4 {
            level = 2
        } else if completionPercentage <= 0.6 {
            level = 3
        } else if completionPercentage <= 0.8 {
            level = 4
        } else {
            level = 5
        }
        
        // GitHub-style color progression
        switch level {
        case 0:
            return Color.gray.opacity(0.1)
        case 1:
            return Color(red: 0.9, green: 0.95, blue: 0.9)
        case 2:
            return Color(red: 0.6, green: 0.9, blue: 0.6)
        case 3:
            return Color(red: 0.3, green: 0.8, blue: 0.3)
        case 4:
            return Color(red: 0.1, green: 0.7, blue: 0.1)
        default:
            return Color(red: 0.0, green: 0.6, blue: 0.0)
        }
    }
}

struct YearSelectorView: View {
    @Binding var selectedYear: Int
    @Binding var isPresented: Bool
    
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let startYear = 2024
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Year")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 16) {
                    ForEach(availableYears(), id: \.self) { year in
                        Button(action: {
                            selectedYear = year
                            isPresented = false
                        }) {
                            VStack {
                                Text("\(year)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(selectedYear == year ? .white : .primary)
                                
                                if year == currentYear {
                                    Text("Current")
                                        .font(.caption)
                                        .foregroundColor(selectedYear == year ? .white : .secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedYear == year ? Color.blue : Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Year Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func availableYears() -> [Int] {
        var years: [Int] = []
        for year in startYear...currentYear + 2 { // Show current year + 2 future years
            years.append(year)
        }
        return years
    }
}

struct DateDetailView: View {
    let date: Date
    @ObservedObject var viewModel: HabitViewModel
    @Binding var isPresented: Bool
    
    private let dateFormatter = DateFormatter()
    
    init(date: Date, viewModel: HabitViewModel, isPresented: Binding<Bool>) {
        self.date = date
        self.viewModel = viewModel
        self._isPresented = isPresented
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text(dateFormatter.string(from: date))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                let completedHabits = viewModel.habitHistory[dateKey(date)] ?? []
                let totalHabits = viewModel.habits.count
                
                if totalHabits > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Habit Progress")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(Int((Double(completedHabits.count) / Double(totalHabits)) * 100))%")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        ProgressView(value: Double(completedHabits.count), total: Double(totalHabits))
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(height: 10)
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        Text("\(completedHabits.count) of \(totalHabits) habits completed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !viewModel.habits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Habits")
                            .font(.headline)
                        
                        ForEach(viewModel.habits) { habit in
                            HStack {
                                Image(systemName: completedHabits.contains(habit.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(completedHabits.contains(habit.id) ? .green : .gray)
                                
                                Text(habit.name)
                                    .foregroundColor(completedHabits.contains(habit.id) ? .primary : .secondary)
                                
                                Spacer()
                            }
                        }
                    }
                } else {
                    Text("No habits added yet")
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
