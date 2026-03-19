//
//  HabitTrackerTests.swift
//  HabitTrackerTests
//
//  Created by Halyna Mazur on 14.04.2025.
//

import Testing
import Foundation
@testable import HabitTracker

struct HabitModelTests {
    
    @Test func habitInitialization() {
        let habit = Habit(name: "Exercise")
        
        #expect(!habit.id.uuidString.isEmpty)
        #expect(habit.name == "Exercise")
        #expect(habit.deletedAt == nil)
        #expect(habit.completionHistory.isEmpty)
    }
    
    @Test func habitInitializationWithHistory() {
        let history = ["2025-01-01", "2025-01-02"]
        let habit = Habit(name: "Reading", completionHistory: history)
        
        #expect(habit.name == "Reading")
        #expect(habit.completionHistory == history)
    }
}

struct HabitViewModelTests {
    
    var viewModel: HabitViewModel
    
    init() {
        viewModel = HabitViewModel()
        viewModel.habits = []
        viewModel.deletedHabits = []
        viewModel.habitHistory = [:]
    }
    
    // MARK: - Adding Habits Tests
    
    @Test func addHabitSuccessfully() {
        viewModel.addHabit(name: "Morning Run")
        
        #expect(viewModel.habits.count == 1)
        #expect(viewModel.habits.first?.name == "Morning Run")
    }
    
    @Test func addHabitWithWhitespace() {
        viewModel.addHabit(name: "  Meditation  ")
        
        #expect(viewModel.habits.count == 1)
        #expect(viewModel.habits.first?.name == "Meditation")
    }
    
    @Test func addHabitEmptyStringIgnored() {
        viewModel.addHabit(name: "")
        viewModel.addHabit(name: "   ")
        
        #expect(viewModel.habits.isEmpty)
    }
    
    @Test func addMultipleHabits() {
        viewModel.addHabit(name: "Exercise")
        viewModel.addHabit(name: "Drink Water")
        viewModel.addHabit(name: "Read")
        
        #expect(viewModel.habits.count == 3)
    }
    
    // MARK: - Editing Habits Tests
    
    @Test func editHabitName() {
        viewModel.addHabit(name: "Original Name")
        let habit = viewModel.habits[0]
        
        viewModel.editHabit(habit: habit, newName: "New Name")
        
        #expect(viewModel.habits[0].name == "New Name")
    }
    
    @Test func editNonexistentHabit() {
        let fakeHabit = Habit(name: "Fake")
        viewModel.addHabit(name: "Real")
        
        let initialCount = viewModel.habits.count
        viewModel.editHabit(habit: fakeHabit, newName: "Changed")
        
        #expect(viewModel.habits.count == initialCount)
    }
    
    // MARK: - Toggling Completion Tests
    
    @Test func toggleHabitCompletion() {
        viewModel.addHabit(name: "Exercise")
        let habit = viewModel.habits[0]
        let today = Date()
        let todayKey = viewModel.dateKey(today)
        
        #expect(!viewModel.isCompleted(habit, on: today))
        
        viewModel.toggleHabitCompletion(habit, for: today)
        
        #expect(viewModel.isCompleted(habit, on: today))
    }
    
    @Test func toggleHabitCompletionTwice() {
        viewModel.addHabit(name: "Walk")
        let habit = viewModel.habits[0]
        let today = Date()
        
        viewModel.toggleHabitCompletion(habit, for: today)
        #expect(viewModel.isCompleted(habit, on: today))
        
        viewModel.toggleHabitCompletion(habit, for: today)
        #expect(!viewModel.isCompleted(habit, on: today))
    }
    
    @Test func completionHistoryUpdated() {
        viewModel.addHabit(name: "Study")
        let habit = viewModel.habits[0]
        let today = Date()
        let todayKey = viewModel.dateKey(today)
        
        viewModel.toggleHabitCompletion(habit, for: today)
        
        #expect(habit.completionHistory.contains(todayKey))
    }
    
    // MARK: - Deleting Habits Tests
    
    @Test func deleteHabitPreservesHistory() {
        viewModel.addHabit(name: "Deleted Habit")
        let habit = viewModel.habits[0]
        let today = Date()
        
        viewModel.toggleHabitCompletion(habit, for: today)
        viewModel.deleteHabit(habit)
        
        #expect(viewModel.habits.isEmpty)
        #expect(viewModel.deletedHabits.count == 1)
        #expect(viewModel.deletedHabits[0].name == "Deleted Habit")
        #expect(viewModel.deletedHabits[0].completionHistory.contains(viewModel.dateKey(today)))
    }
    
    @Test func deleteMultipleHabitsAtOffsets() {
        viewModel.addHabit(name: "Habit 1")
        viewModel.addHabit(name: "Habit 2")
        viewModel.addHabit(name: "Habit 3")
        
        viewModel.deleteHabits(at: IndexSet([0, 2]))
        
        #expect(viewModel.habits.count == 1)
        #expect(viewModel.habits.first?.name == "Habit 2")
        #expect(viewModel.deletedHabits.count == 2)
    }
    
    // MARK: - Progress Tests
    
    @Test func getTodayProgressEmptyHabits() {
        let progress = viewModel.getTodayProgress()
        
        #expect(progress.completed == 0)
        #expect(progress.total == 0)
    }
    
    @Test func getTodayProgress() {
        viewModel.addHabit(name: "Habit 1")
        viewModel.addHabit(name: "Habit 2")
        viewModel.addHabit(name: "Habit 3")
        
        let habits = viewModel.habits
        viewModel.toggleHabitCompletion(habits[0], for: Date())
        viewModel.toggleHabitCompletion(habits[1], for: Date())
        
        let progress = viewModel.getTodayProgress()
        
        #expect(progress.completed == 2)
        #expect(progress.total == 3)
    }
    
    @Test func getCompletionRateForDate() {
        viewModel.addHabit(name: "A")
        viewModel.addHabit(name: "B")
        
        let today = Date()
        viewModel.toggleHabitCompletion(viewModel.habits[0], for: today)
        
        let rate = viewModel.getCompletionRate(for: today)
        
        #expect(rate == 0.5)
    }
    
    @Test func getAverageCompletionRate() {
        viewModel.addHabit(name: "Habit 1")
        viewModel.addHabit(name: "Habit 2")
        
        let today = Date()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Complete 1/2 habits today (50%)
        viewModel.toggleHabitCompletion(viewModel.habits[0], for: today)
        
        // Complete 2/2 habits yesterday (100%)
        viewModel.toggleHabitCompletion(viewModel.habits[0], for: yesterday)
        viewModel.toggleHabitCompletion(viewModel.habits[1], for: yesterday)
        
        let avgRate = viewModel.getAverageCompletionRate()
        
        #expect(avgRate == 0.75) // (50% + 100%) / 2 = 75%
    }
    
    // MARK: - Streak Tests
    
    @Test func getStreakCountConsecutiveDays() {
        viewModel.addHabit(name: "Daily Reading")
        let habit = viewModel.habits[0]
        
        let today = Date()
        let calendar = Calendar.current
        
        // Mark last 3 days as completed
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            viewModel.toggleHabitCompletion(habit, for: date)
        }
        
        let streak = viewModel.getStreakCount(for: habit)
        
        #expect(streak == 3)
    }
    
    @Test func getStreakCountBrokenByMissedDay() {
        viewModel.addHabit(name: "Exercise")
        let habit = viewModel.habits[0]
        
        let today = Date()
        let calendar = Calendar.current
        
        // Complete today
        viewModel.toggleHabitCompletion(habit, for: today)
        
        // Complete 2 days ago (miss yesterday)
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        viewModel.toggleHabitCompletion(habit, for: twoDaysAgo)
        
        let streak = viewModel.getStreakCount(for: habit)
        
        #expect(streak == 1) // Only today counts
    }
    
    // MARK: - Total Completed Days Test
    
    @Test func getTotalCompletedDays() {
        viewModel.addHabit(name: "Any")
        let today = Date()
        let calendar = Calendar.current
        
        // Complete on 3 different days
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            viewModel.toggleHabitCompletion(viewModel.habits[0], for: date)
        }
        
        let totalDays = viewModel.getTotalCompletedDays()
        
        #expect(totalDays == 3)
    }
    
    // MARK: - Date Key Tests
    
    @Test func dateKeyFormatCorrect() {
        let date = Date(timeIntervalSince1970: 1735689600) // 2025-01-01
        let key = viewModel.dateKey(date)
        
        #expect(key == "2025-01-01")
    }
    
    // MARK: - Deleted Habits Tests
    
    @Test func getDeletedHabitsWithHistory() {
        viewModel.addHabit(name: "Old Habit")
        let habit = viewModel.habits[0]
        viewModel.deleteHabit(habit)
        
        let deleted = viewModel.getDeletedHabitsWithHistory()
        
        #expect(deleted.count == 1)
        #expect(deleted.first?.name == "Old Habit")
    }
    
    @Test func getDeletedHabitsOrderedByDeletionDate() {
        viewModel.addHabit(name: "First")
        viewModel.addHabit(name: "Second")
        
        let first = viewModel.habits[0]
        let second = viewModel.habits[1]
        
        viewModel.deleteHabit(first)
        viewModel.deleteHabit(second)
        
        let deleted = viewModel.getDeletedHabitsWithHistory()
        
        #expect(deleted[0].name == "Second") // Most recently deleted first
        #expect(deleted[1].name == "First")
    }
    
    // MARK: - Habit History Tests
    
    @Test func getProgressForDate() {
        viewModel.addHabit(name: "A")
        viewModel.addHabit(name: "B")
        
        let today = Date()
        viewModel.toggleHabitCompletion(viewModel.habits[0], for: today)
        
        let progress = viewModel.getProgressForDate(today)
        
        #expect(progress.completed == 1)
        #expect(progress.total == 2)
    }
    
    @Test func cleanupOrphanedHabitHistory() {
        viewModel.addHabit(name: "Habit 1")
        let habit1 = viewModel.habits[0]
        
        let today = Date()
        viewModel.toggleHabitCompletion(habit1, for: today)
        
        // Manually add completion for non-existent habit
        let fakeID = UUID()
        viewModel.habitHistory[viewModel.dateKey(today), default: []].append(fakeID)
        
        viewModel.cleanupOrphanedHabitHistory()
        
        let completedHabits = viewModel.habitHistory[viewModel.dateKey(today)]!
        #expect(!completedHabits.contains(fakeID))
        #expect(completedHabits.contains(habit1.id))
    }
}
