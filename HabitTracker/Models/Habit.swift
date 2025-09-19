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
}
