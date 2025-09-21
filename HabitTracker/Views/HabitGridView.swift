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
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var showingYearSelector = false
    @State private var viewMode: ViewMode = .month // Default to month view
    
    enum ViewMode {
        case month
        case year
    }
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateFormat = "MMM d, yyyy"
    }
    
    private var monthYearString: String {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"
        let date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth)) ?? Date()
        return monthFormatter.string(from: date)
    }
    
    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let date = calendar.date(from: DateComponents(year: selectedYear, month: month)) ?? Date()
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Current date and stats header
            VStack(spacing: 8) {
                Text("Today: \(dateFormatter.string(from: Date()))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                let todayCompletedHabits = viewModel.habitHistory[dateKey(Date())] ?? []
                let totalHabits = viewModel.habits.count
                
                // Filter out habits that no longer exist in the active habits list
                let validTodayCompleted = todayCompletedHabits.filter { habitId in
                    viewModel.habits.contains { $0.id == habitId }
                }
                
                Text("\(validTodayCompleted.count)/\(totalHabits) habits completed today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if totalHabits > 0 {
                    ProgressView(value: Double(validTodayCompleted.count), total: Double(totalHabits))
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(height: 8)
                }
            }
            .padding(.horizontal)
            
            // View mode toggle and date selector
            VStack(spacing: 12) {
                // View mode toggle
                HStack {
                    Spacer()
                    
                    Picker("View Mode", selection: $viewMode) {
                        Text("Month").tag(ViewMode.month)
                        Text("Year").tag(ViewMode.year)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                    
                    Spacer()
                }
                
                // Date selector based on view mode
                if viewMode == .month {
                    // Month view controls
                    HStack {
                        Button(action: {
                            if selectedMonth > 1 {
                                selectedMonth -= 1
                            } else {
                                selectedMonth = 12
                                selectedYear -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text(monthYearString)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            if selectedMonth < 12 {
                                selectedMonth += 1
                            } else {
                                selectedMonth = 1
                                selectedYear += 1
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    // Year view controls
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
                }
            }
            .padding(.horizontal)
            
            // Content based on view mode
            ScrollView {
                if viewMode == .month {
                    // Month view - daily calendar grid
                    MonthCalendarView(
                        year: selectedYear,
                        month: selectedMonth,
                        viewModel: viewModel,
                        onDateTap: { date in
                            selectedDate = date
                            showingDateDetail = true
                        }
                    )
                    .padding()
                } else {
                    // Year view - unified contribution grid
                    VStack(spacing: 8) {
                        // Month labels
                        HStack(spacing: 0) {
                            ForEach(1...12, id: \.self) { month in
                                Text(monthName(for: month))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Unified contribution grid
                        YearContributionGrid(
                            year: selectedYear,
                            viewModel: viewModel,
                            onDateTap: { date in
                                selectedDate = date
                                showingDateDetail = true
                            }
                        )
                    }
                    .padding()
                }
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
                
                let progress = viewModel.getProgressForDate(date)
                let allHabits = viewModel.getAllHabitsForDate(date)
                
                if progress.total > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Habit Progress")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(Int((Double(progress.completed) / Double(progress.total)) * 100))%")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        ProgressView(value: Double(progress.completed), total: Double(progress.total))
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(height: 10)
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        Text("\(progress.completed) of \(progress.total) habits completed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !allHabits.active.isEmpty || !allHabits.archived.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        // Active Habits Section
                        if !allHabits.active.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Habits")
                                    .font(.headline)
                                
                                ForEach(allHabits.active) { habit in
                                    HStack {
                                        Image(systemName: viewModel.isHabitCompletedOnDate(habit, date: date) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(viewModel.isHabitCompletedOnDate(habit, date: date) ? .green : .gray)
                                        
                                        Text(habit.name)
                                            .foregroundColor(viewModel.isHabitCompletedOnDate(habit, date: date) ? .primary : .secondary)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        // Archived Habits Section
                        if !allHabits.archived.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Archived Habits")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                ForEach(allHabits.archived) { habit in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        
                                        Text(habit.name)
                                            .foregroundColor(.secondary)
                                            .strikethrough()
                                        
                                        Spacer()
                                        
                                        Text("Archived")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
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
