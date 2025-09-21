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
        guard habits.count < 10 else { return }
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
    
    // MARK: - Mock Data for Testing
    
    func addMockData() {
        // Clear existing data first
        habits.removeAll()
        deletedHabits.removeAll()
        habitHistory.removeAll()
        
        // Add some active habits
        let activeHabits = [
            "Drink 8 glasses of water",
            "Read for 30 minutes",
            "Exercise for 20 minutes",
            "Meditate for 10 minutes"
        ]
        
        for habitName in activeHabits {
            addHabit(name: habitName)
        }
        
        // Add some deleted habits with completion history
        let deletedHabitData = [
            ("Eat 1 apple", 15), // 15 days ago
            ("Take vitamins", 8), // 8 days ago
            ("Walk 10,000 steps", 22), // 22 days ago
            ("Practice guitar", 5), // 5 days ago
            ("Write in journal", 12) // 12 days ago
        ]
        
        for (habitName, daysAgo) in deletedHabitData {
            var deletedHabit = Habit(name: habitName)
            deletedHabit.deletedAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            
            // Add realistic completion history (more completions closer to deletion)
            let completionDates = generateRealisticCompletionDates(daysAgo: daysAgo)
            deletedHabit.completionHistory = completionDates
            
            deletedHabits.append(deletedHabit)
        }
        
        // Add some completion history for active habits (last 7 days)
        let calendar = Calendar.current
        let today = Date()
        
        for (index, habit) in habits.enumerated() {
            // Different completion patterns for each habit
            let completionRate = 0.3 + (Double(index) * 0.2) // 30%, 50%, 70%, 90%
            
            for daysBack in 0..<7 {
                if Double.random(in: 0...1) < completionRate {
                    let date = calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today
                    let dateKey = self.dateKey(date)
                    
                    // Add to habit's completion history
                    if let habitIndex = habits.firstIndex(where: { $0.id == habit.id }) {
                        if !habits[habitIndex].completionHistory.contains(dateKey) {
                            habits[habitIndex].completionHistory.append(dateKey)
                        }
                    }
                    
                    // Add to daily habit history
                    var completed = habitHistory[dateKey, default: []]
                    if !completed.contains(habit.id) {
                        completed.append(habit.id)
                        habitHistory[dateKey] = completed
                    }
                }
            }
        }
        
        save()
        print("✅ Mock data added successfully!")
        print("📊 Active habits: \(habits.count)")
        print("🗑️ Deleted habits: \(deletedHabits.count)")
        print("📅 Days with history: \(habitHistory.count)")
    }
    
    private func generateRandomCompletionDates(daysBack: Int) -> [String] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [String] = []
        
        for i in 0..<daysBack {
            if Bool.random() { // Random chance of completion
                let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
                dates.append(dateKey(date))
            }
        }
        
        return dates
    }
    
    private func generateRealisticCompletionDates(daysAgo: Int) -> [String] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [String] = []
        
        // Generate completions for the period before deletion
        // More likely to complete habits closer to deletion date
        for i in 0..<daysAgo {
            let daysFromDeletion = daysAgo - i
            let completionChance: Double
            
            if daysFromDeletion <= 3 {
                completionChance = 0.8 // 80% chance in last 3 days
            } else if daysFromDeletion <= 7 {
                completionChance = 0.6 // 60% chance in last week
            } else if daysFromDeletion <= 14 {
                completionChance = 0.4 // 40% chance in last 2 weeks
            } else {
                completionChance = 0.2 // 20% chance earlier
            }
            
            if Double.random(in: 0...1) < completionChance {
                let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
                dates.append(dateKey(date))
            }
        }
        
        return dates
    }
    
    func clearAllData() {
        habits.removeAll()
        deletedHabits.removeAll()
        habitHistory.removeAll()
        save()
        print("✅ All data cleared!")
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
}
