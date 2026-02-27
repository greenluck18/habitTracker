//
//  EditHabitView.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 16.04.2025.
//

import SwiftUI

struct EditHabitView: View {
    let habit: Habit
    @EnvironmentObject var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""
    @FocusState private var isNameFocused: Bool

    private let maxLength = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: HabitTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: HabitTheme.Spacing.sm) {
                    Text("HABIT NAME")
                        .font(HabitTheme.Typography.caption)
                        .foregroundColor(.secondary)

                    TextField("Habit name", text: $newName)
                        .font(HabitTheme.Typography.body)
                        .padding(HabitTheme.Spacing.lg)
                        .background(HabitTheme.Colors.cardBackground)
                        .cornerRadius(HabitTheme.Layout.cornerRadiusSmall)
                        .overlay(
                            RoundedRectangle(cornerRadius: HabitTheme.Layout.cornerRadiusSmall)
                                .stroke(
                                    isNameFocused ? HabitTheme.Colors.brand : Color(.separator).opacity(0.3),
                                    lineWidth: isNameFocused ? 2 : 0.5
                                )
                        )
                        .focused($isNameFocused)
                        .onChange(of: newName) { _, newValue in
                            if newValue.count > maxLength {
                                newName = String(newValue.prefix(maxLength))
                            }
                        }
                        .accessibilityLabel("Habit name")

                    HStack {
                        Spacer()
                        Text("\(newName.count)/\(maxLength)")
                            .font(HabitTheme.Typography.caption)
                            .foregroundColor(newName.count >= maxLength ? .orange : .secondary)
                    }
                }
                .padding(.horizontal, HabitTheme.Spacing.lg)
                .padding(.top, HabitTheme.Spacing.xl)

                Spacer()
            }
            .background(HabitTheme.Colors.surface.ignoresSafeArea())
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.editHabit(habit: habit, newName: newName)
                        dismiss()
                    }
                    .font(HabitTheme.Typography.bodyMedium)
                    .tint(HabitTheme.Colors.brand)
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                newName = habit.name
                isNameFocused = true
            }
        }
    }
}
