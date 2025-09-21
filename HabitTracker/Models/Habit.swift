//
//  Habit.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//
import SwiftUI

struct Habit: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var deletedAt: Date?
    var completionHistory: [String] = [] // Array of date strings when habit was completed
    
    init(id: UUID = UUID(), name: String, deletedAt: Date? = nil, completionHistory: [String] = []) {
        self.id = id
        self.name = name
        self.deletedAt = deletedAt
        self.completionHistory = completionHistory
    }
}
