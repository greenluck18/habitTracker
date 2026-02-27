//
//  EditHabitsView.swift
//  HabitTracker
//

import SwiftUI

struct EditHabitsView: View {
    @EnvironmentObject var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHabit: Habit? = nil

    var body: some View {
        NavigationStack {
            content
                .background(HabitTheme.Colors.surface.ignoresSafeArea())
                .navigationTitle("Edit Habits")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if !viewModel.habits.isEmpty {
                            EditButton()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                            .font(HabitTheme.Typography.bodyMedium)
                    }
                }
                .sheet(item: $selectedHabit) { habit in
                    EditHabitView(habit: habit)
                }
        }
        .tint(HabitTheme.Colors.brand)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.habits.isEmpty {
            emptyState
        } else {
            habitsList
        }
    }

    private var emptyState: some View {
        VStack(spacing: HabitTheme.Spacing.lg) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No habits to edit")
                .font(HabitTheme.Typography.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var habitsList: some View {
        List {
            ForEach(viewModel.habits) { habit in
                habitRow(habit)
            }
            .onDelete { offsets in
                viewModel.deleteHabits(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func habitRow(_ habit: Habit) -> some View {
        let isCompleted = viewModel.isCompleted(habit)
        return HStack(spacing: HabitTheme.Spacing.md) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isCompleted ? HabitTheme.Colors.success : Color(.tertiaryLabel))
                .frame(width: HabitTheme.Layout.minTouchTarget, height: HabitTheme.Layout.minTouchTarget)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        viewModel.toggleHabitCompletion(habit)
                    }
                    HabitTheme.Haptics.toggle()
                }

            Text(habit.name)
                .font(HabitTheme.Typography.bodyMedium)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedHabit = habit
        }
        .padding(.vertical, HabitTheme.Spacing.xs)
        .accessibilityLabel("\(habit.name), \(isCompleted ? "completed" : "not completed")")
        .accessibilityHint("Tap to edit, swipe to delete")
    }
}
