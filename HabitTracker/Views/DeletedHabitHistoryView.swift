//
//  DeletedHabitHistoryView.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import SwiftUI

struct DeletedHabitHistoryView: View {
    @EnvironmentObject var viewModel: HabitViewModel
    @State private var expandedHabits: Set<UUID> = []

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.deletedHabits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .background(HabitTheme.Colors.surface.ignoresSafeArea())
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: HabitTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "archivebox")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.6))

            VStack(spacing: HabitTheme.Spacing.sm) {
                Text("No archived habits")
                    .font(HabitTheme.Typography.title)
                    .foregroundColor(.primary)

                Text("Deleted habits and their completion\nhistory will appear here.")
                    .font(HabitTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(HabitTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No archived habits. Deleted habits will appear here.")
    }

    // MARK: - Habit List

    private var habitList: some View {
        ScrollView {
            LazyVStack(spacing: HabitTheme.Spacing.md) {
                ForEach(viewModel.getDeletedHabitsWithHistory()) { habit in
                    habitCard(habit)
                }
            }
            .padding(HabitTheme.Spacing.lg)
        }
    }

    // MARK: - Habit Card

    private func habitCard(_ habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: HabitTheme.Spacing.md) {
            // Header
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if expandedHabits.contains(habit.id) {
                        expandedHabits.remove(habit.id)
                    } else {
                        expandedHabits.insert(habit.id)
                    }
                }
                HabitTheme.Haptics.selection()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: HabitTheme.Spacing.xs) {
                        Text(habit.name)
                            .font(HabitTheme.Typography.headline)
                            .foregroundColor(.primary)

                        if let deletedAt = habit.deletedAt {
                            Text("Deleted \(dateFormatter.string(from: deletedAt))")
                                .font(HabitTheme.Typography.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: HabitTheme.Spacing.xs) {
                            Image(systemName: "checkmark.circle")
                                .font(.caption2)
                            Text("\(habit.completionHistory.count) completions")
                                .font(HabitTheme.Typography.caption)
                        }
                        .foregroundColor(HabitTheme.Colors.brand)
                    }

                    Spacer()

                    Image(systemName: expandedHabits.contains(habit.id) ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(width: HabitTheme.Layout.minTouchTarget, height: HabitTheme.Layout.minTouchTarget)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(habit.name), \(habit.completionHistory.count) completions")
            .accessibilityHint(expandedHabits.contains(habit.id) ? "Double tap to collapse" : "Double tap to expand history")

            // Expanded completion history
            if expandedHabits.contains(habit.id) {
                VStack(alignment: .leading, spacing: HabitTheme.Spacing.sm) {
                    Divider()
                        .padding(.vertical, HabitTheme.Spacing.xs)

                    if habit.completionHistory.isEmpty {
                        Text("No completion history")
                            .font(HabitTheme.Typography.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Text("Completion History")
                            .font(HabitTheme.Typography.subheadlineMedium)
                            .foregroundColor(.primary)

                        LazyVStack(alignment: .leading, spacing: HabitTheme.Spacing.xs) {
                            ForEach(viewModel.getCompletionHistoryForDeletedHabit(habit), id: \.self) { dateString in
                                HStack(spacing: HabitTheme.Spacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(HabitTheme.Colors.success)

                                    Text(viewModel.formatCompletionDate(dateString))
                                        .font(HabitTheme.Typography.caption)
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                                .padding(.horizontal, HabitTheme.Spacing.sm)
                                .padding(.vertical, HabitTheme.Spacing.xs)
                                .background(HabitTheme.Colors.successSoft)
                                .cornerRadius(HabitTheme.Layout.cornerRadiusTiny)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(HabitTheme.Spacing.lg)
        .cardStyle()
    }
}
