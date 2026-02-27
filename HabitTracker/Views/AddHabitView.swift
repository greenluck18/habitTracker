//
//  AddHabitView.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import SwiftUI

struct AddHabitView: View {
    @EnvironmentObject var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var isNameFocused: Bool

    private let maxLength = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: HabitTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: HabitTheme.Spacing.sm) {
                    Text("HABIT NAME")
                        .font(HabitTheme.Typography.caption)
                        .foregroundColor(.secondary)

                    TextField("e.g. Morning meditation", text: $name)
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
                        .onChange(of: name) { _, newValue in
                            if newValue.count > maxLength {
                                name = String(newValue.prefix(maxLength))
                            }
                        }
                        .accessibilityLabel("Habit name")
                        .accessibilityHint("Enter a name for your new habit, maximum \(maxLength) characters")

                    HStack {
                        if viewModel.habits.count >= 10 {
                            Label("Maximum 10 habits reached", systemImage: "exclamationmark.circle")
                                .font(HabitTheme.Typography.caption)
                                .foregroundColor(.red)
                        }

                        Spacer()

                        Text("\(name.count)/\(maxLength)")
                            .font(HabitTheme.Typography.caption)
                            .foregroundColor(name.count >= maxLength ? .orange : .secondary)
                    }
                }
                .padding(.horizontal, HabitTheme.Spacing.lg)
                .padding(.top, HabitTheme.Spacing.xl)

                Spacer()
            }
            .background(HabitTheme.Colors.surface.ignoresSafeArea())
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addHabit(name: name)
                        HabitTheme.Haptics.success()
                        dismiss()
                    }
                    .font(HabitTheme.Typography.bodyMedium)
                    .tint(HabitTheme.Colors.brand)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.habits.count >= 10)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }
}
