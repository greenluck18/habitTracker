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
    @Published var habitHistory: [String: [UUID]] = [:] // ["yyyy-MM-dd": [habitId]]

    private let habitsKey = "habits"
    private let historyKey = "habitHistory"

    init() {
        load()
    }

    func toggleHabitCompletion(_ habit: Habit, for date: Date = Date()) {
        let key = dateKey(date)
        var completed = habitHistory[key, default: []]
        if completed.contains(habit.id) {
            completed.removeAll { $0 == habit.id }
        } else {
            completed.append(habit.id)
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
        habits.remove(atOffsets: offsets)
        save()
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
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

    private func dateKey(_ date: Date) -> String {
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
        let completed = habitHistory[todayKey]?.count ?? 0
        return (completed: completed, total: habits.count)
    }
}
