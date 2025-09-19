//
//  EditHabitView.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 16.04.2025.
//

import SwiftUI

struct EditHabitView: View {
    var habit: Habit
    @ObservedObject var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newName: String = ""

    var body: some View {
        Form {
            Section(header: Text("Edit Habit Name")) {
                TextField("Habit Name", text: $newName)
            }

            Button("Save") {
                viewModel.editHabit(habit: habit, newName: newName)
                dismiss()
            }
        }
        .onAppear {
            newName = habit.name
        }
        .navigationTitle("Edit Habit")
    }
}
