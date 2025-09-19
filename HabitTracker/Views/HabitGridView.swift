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
            
            // GitHub-style contributions grid
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // Month labels
                    HStack(spacing: 0) {
                        ForEach(monthLabels(), id: \.self) { month in
                            Text(month)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .leading)
                        }
                    }
                    .padding(.leading, 20) // Space for day labels
                    
                    // Grid with day labels
                    HStack(alignment: .top, spacing: 0) {
                        // Day labels (Sun, Mon, Tue, etc.)
                        VStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                Text(dayLabel(for: dayIndex))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        
                        // Contributions grid
                        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 2), count: 7), spacing: 2) {
                            ForEach(generateContributionDates(), id: \.self) { date in
                                ContributionCell(
                                    date: date,
                                    completionCount: viewModel.habitHistory[dateKey(date)]?.count ?? 0,
                                    totalHabits: viewModel.habits.count,
                                    isToday: calendar.isDateInToday(date),
                                    onTap: {
                                        selectedDate = date
                                        showingDateDetail = true
                                    }
                                )
                            }
                        }
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
                    ForEach(0..<5) { level in
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
    }
    
    private func generateContributionDates() -> [Date] {
        let today = Date()
        let startDate = calendar.date(byAdding: .month, value: -11, to: today) ?? today
        
        // Find the Sunday of the week containing startDate
        let weekday = calendar.component(.weekday, from: startDate)
        let daysToSubtract = (weekday - 1) % 7
        let gridStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: startDate) ?? startDate
        
        var dates: [Date] = []
        var currentDate = gridStartDate
        
        while currentDate <= today {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    private func monthLabels() -> [String] {
        let today = Date()
        let startDate = calendar.date(byAdding: .month, value: -11, to: today) ?? today
        
        var labels: [String] = []
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        
        for i in 0..<12 {
            if let monthDate = calendar.date(byAdding: .month, value: i, to: startDate) {
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
        
        let maxLevel = 4
        let normalizedLevel = Double(level) / Double(maxLevel)
        let intensity = 0.1 + (normalizedLevel * 0.9)
        
        return Color.green.opacity(intensity)
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
                .frame(width: 16, height: 16)
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
        
        let intensity = Double(completionCount) / Double(totalHabits)
        return Color.green.opacity(max(0.1, intensity))
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Habit Progress")
                            .font(.headline)
                        
                        ProgressView(value: Double(completedHabits.count), total: Double(totalHabits))
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        
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
