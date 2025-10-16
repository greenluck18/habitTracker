//
//  HabitViewModel.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import Foundation
import SwiftUI

class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var deletedHabits: [Habit] = []
    @Published var habitHistory: [String: [UUID]] = [:] // ["yyyy-MM-dd": [habitId]]

    private let habitsKey = "habits"
    private let deletedHabitsKey = "deletedHabits"
    private let historyKey = "habitHistory"

    init() {
        load()
        // Clean up any orphaned habit history entries
        cleanupOrphanedHabitHistory()
    }
    
    /// Call this method when the day changes to refresh the view
    func refreshForNewDay() {
        // Force a UI update by triggering a published property change
        objectWillChange.send()
    }

    func toggleHabitCompletion(_ habit: Habit, for date: Date = Date()) {
        let key = dateKey(date)
        var completed = habitHistory[key, default: []]
        
        if completed.contains(habit.id) {
            completed.removeAll { $0 == habit.id }
            // Remove from habit's completion history
            if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                habits[index].completionHistory.removeAll { $0 == key }
            }
        } else {
            completed.append(habit.id)
            // Add to habit's completion history
            if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                if !habits[index].completionHistory.contains(key) {
                    habits[index].completionHistory.append(key)
                }
            }
        }
        habitHistory[key] = completed
        save()
    }

    func isCompleted(_ habit: Habit, on date: Date = Date()) -> Bool {
        let key = dateKey(date)
        return habitHistory[key, default: []].contains(habit.id)
    }

    func addHabit(name: String) {
        guard habits.count < 10000 else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newHabit = Habit(id: UUID(), name: trimmedName)
        habits.append(newHabit)
        save()

        // Log the addition for debugging
        print("✅ Added habit: \(trimmedName)")
    }

    func editHabit(habit: Habit, newName: String) {
        // Find the habit in our array by matching its 'id'
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else {
            return
        }
        
        habits[index].name = newName
        
        save()
    }

//    func deleteHabit(habit: Habit) {
//        habits.removeAll(where: { $0.id == habit.id })
//        save()
//    }

    func deleteHabits(at offsets: IndexSet) {
        // Preserve history for habits being deleted
        for index in offsets {
            if index < habits.count {
                var deletedHabit = habits[index]
                deletedHabit.deletedAt = Date()
                deletedHabits.append(deletedHabit)
            }
        }
        
        habits.remove(atOffsets: offsets)
        save()
    }

    func deleteHabit(_ habit: Habit) {
        // Find the habit to preserve its completion history
        if let habitToDelete = habits.first(where: { $0.id == habit.id }) {
            // Create a copy with deletion timestamp and completion history
            var deletedHabit = habitToDelete
            deletedHabit.deletedAt = Date()
            
            // Add to deleted habits array
            deletedHabits.append(deletedHabit)
        }
        
        // Remove from active habits
        habits.removeAll { $0.id == habit.id }
        
        // Remove from daily habit history
        habitHistory.forEach { date, habitIDs in
            habitHistory[date] = habitIDs.filter { $0 != habit.id }
        }
        save()
    }

    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            save()
        }
    }
    

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // Save habits
        do {
            let data = try encoder.encode(habits)
            UserDefaults.standard.set(data, forKey: habitsKey)
            print("✅ Saved \(habits.count) habits to UserDefaults")
        } catch {
            print("❌ Failed to save habits: \(error)")
        }
        
        // Save deleted habits
        do {
            let deletedData = try encoder.encode(deletedHabits)
            UserDefaults.standard.set(deletedData, forKey: deletedHabitsKey)
            print("✅ Saved \(deletedHabits.count) deleted habits to UserDefaults")
        } catch {
            print("❌ Failed to save deleted habits: \(error)")
        }
        
        // Save habit history
        do {
            let historyData = try encoder.encode(habitHistory)
            UserDefaults.standard.set(historyData, forKey: historyKey)
            print("✅ Saved habit history with \(habitHistory.count) days")
        } catch {
            print("❌ Failed to save habit history: \(error)")
        }
        
        // Force synchronization to ensure data is written to disk
        UserDefaults.standard.synchronize()
    }

    private func load() {
        let decoder = JSONDecoder()
        
        // Load habits
        if let data = UserDefaults.standard.data(forKey: habitsKey) {
            do {
                let loadedHabits = try decoder.decode([Habit].self, from: data)
                habits = loadedHabits
                print("✅ Loaded \(habits.count) habits from UserDefaults")
            } catch {
                print("❌ Failed to decode habits: \(error)")
                habits = [] // Reset to empty array on error
            }
        } else {
            print("ℹ️ No habits data found in UserDefaults")
        }

        // Load deleted habits
        if let deletedData = UserDefaults.standard.data(forKey: deletedHabitsKey) {
            do {
                let loadedDeletedHabits = try decoder.decode([Habit].self, from: deletedData)
                deletedHabits = loadedDeletedHabits
                print("✅ Loaded \(deletedHabits.count) deleted habits from UserDefaults")
            } catch {
                print("❌ Failed to decode deleted habits: \(error)")
                deletedHabits = [] // Reset to empty array on error
            }
        } else {
            print("ℹ️ No deleted habits data found in UserDefaults")
        }

        // Load habit history
        if let historyData = UserDefaults.standard.data(forKey: historyKey) {
            do {
                let loadedHistory = try decoder.decode([String: [UUID]].self, from: historyData)
                habitHistory = loadedHistory
                print("✅ Loaded habit history with \(habitHistory.count) days")
            } catch {
                print("❌ Failed to decode history: \(error)")
                habitHistory = [:] // Reset to empty dictionary on error
            }
        } else {
            print("ℹ️ No habit history data found in UserDefaults")
        }
    }

    func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Statistics and Analytics
    
    func getCompletionRate(for date: Date) -> Double {
        let completedCount = habitHistory[dateKey(date)]?.count ?? 0
        let totalCount = habits.count
        return totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
    }
    
    func getStreakCount(for habit: Habit) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            if isCompleted(habit, on: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    func getTotalCompletedDays() -> Int {
        return habitHistory.keys.count
    }
    
    func getAverageCompletionRate() -> Double {
        guard !habitHistory.isEmpty else { return 0.0 }
        
        let totalRate = habitHistory.values.reduce(0.0) { sum, completedHabits in
            let rate = habits.count > 0 ? Double(completedHabits.count) / Double(habits.count) : 0.0
            return sum + rate
        }
        
        return totalRate / Double(habitHistory.count)
    }
    
    func getTodayProgress() -> (completed: Int, total: Int) {
        let todayKey = dateKey(Date())
        let completedHabits = habitHistory[todayKey] ?? []
        
        // Filter out habits that no longer exist in the active habits list
        let validCompletedHabits = completedHabits.filter { habitId in
            habits.contains { $0.id == habitId }
        }
        
        return (completed: validCompletedHabits.count, total: habits.count)
    }
    
    // MARK: - Deleted Habits History
    
    func getDeletedHabitsWithHistory() -> [Habit] {
        return deletedHabits.sorted { habit1, habit2 in
            guard let date1 = habit1.deletedAt, let date2 = habit2.deletedAt else {
                return false
            }
            return date1 > date2 // Most recently deleted first
        }
    }
    
    func getCompletionHistoryForDeletedHabit(_ habit: Habit) -> [String] {
        return habit.completionHistory.sorted { $0 > $1 } // Most recent first
    }
    
    func formatCompletionDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        
        return displayFormatter.string(from: date)
    }
    
    // MARK: - Data Cleanup
    
    func cleanupOrphanedHabitHistory() {
        let activeHabitIds = Set(habits.map { $0.id })
        var cleanedHistory: [String: [UUID]] = [:]
        
        for (date, completedHabits) in habitHistory {
            let validHabits = completedHabits.filter { activeHabitIds.contains($0) }
            if !validHabits.isEmpty {
                cleanedHistory[date] = validHabits
            }
        }
        
        habitHistory = cleanedHistory
        save()
    }
    
    // MARK: - Progress View Helpers
    
    /// Returns all habits (active and relevant deleted ones) for a specific date.
    /// A deleted habit is relevant if it was deleted *after* the given date.
    func getAllHabitsForDate(_ date: Date) -> (active: [Habit], archived: [Habit]) {
        var activeHabits = habits
        var archivedHabits: [Habit] = []
        
        // Add deleted habits that were active on or before the given date
        for deletedHabit in deletedHabits {
            if let deletedAt = deletedHabit.deletedAt {
                // If the habit was deleted *after* the selected date, it was active on selected date
                if deletedAt > date {
                    // Check if this habit was completed on the selected date
                    if isHabitCompletedOnDate(deletedHabit, date: date) {
                        archivedHabits.append(deletedHabit)
                    }
                }
            }
        }
        
        // Sort to ensure consistent order
        activeHabits.sort { $0.name < $1.name }
        archivedHabits.sort { $0.name < $1.name }
        
        return (active: activeHabits, archived: archivedHabits)
    }
    
    /// Checks if a specific habit was completed on a given date.
    func isHabitCompletedOnDate(_ habit: Habit, date: Date) -> Bool {
        let dateKey = self.dateKey(date)
        return habit.completionHistory.contains(dateKey)
    }
    
    /// Calculates the completion progress for a specific date, including relevant deleted habits.
    func getProgressForDate(_ date: Date) -> (completed: Int, total: Int) {
        let allHabits = getAllHabitsForDate(date)
        let allRelevantHabits = allHabits.active + allHabits.archived

        let completedCount = allRelevantHabits.filter { isHabitCompletedOnDate($0, date: date) }.count
        return (completed: completedCount, total: allRelevantHabits.count)
    }

    // MARK: - Developer Mode

    /// Adds mock completion data for all active habits from start of year to current date
    func addMocksForCurrentYear() {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)

        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)) else {
            print("❌ Failed to create year boundaries")
            return
        }

        var currentDate = startOfYear
        var addedDaysCount = 0

        // Iterate from start of year to today (no future dates)
        while currentDate <= today {
            let key = dateKey(currentDate)

            // Randomly decide if this day has high or low completion (50% chance for each)
            let isLowCompletionDay = Double.random(in: 0...1) < 0.5
            let completionRate = isLowCompletionDay ? 0.3 : 0.7 // Low days: 30%, High days: 70%

            // For each habit, randomly decide if it's completed based on the day's completion rate
            for habit in habits {
                let isCompleted = Double.random(in: 0...1) < completionRate

                if isCompleted {
                    // Add to daily history
                    var completed = habitHistory[key, default: []]
                    if !completed.contains(habit.id) {
                        completed.append(habit.id)
                        habitHistory[key] = completed
                    }

                    // Add to habit's completion history
                    if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                        if !habits[index].completionHistory.contains(key) {
                            habits[index].completionHistory.append(key)
                        }
                    }
                }
            }

            addedDaysCount += 1
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        save()
        print("✅ Added mock data for \(addedDaysCount) days from start of year to today")
    }

    /// Deletes all mock data (clears all completion history)
    func deleteAllMocks() {
        habitHistory.removeAll()

        // Clear completion history from all habits
        for index in habits.indices {
            habits[index].completionHistory.removeAll()
        }

        // Clear completion history from deleted habits
        for index in deletedHabits.indices {
            deletedHabits[index].completionHistory.removeAll()
        }

        save()
        print("✅ Deleted all mock data")
    }
}
