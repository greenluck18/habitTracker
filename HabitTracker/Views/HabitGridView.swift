//
//  HabitGridView.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import SwiftUI

// Identifiable wrapper for Date to use with sheet(item:)
struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

struct HabitGridView: View {
    @EnvironmentObject var viewModel: HabitViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate: IdentifiableDate?
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var showingYearSelector = false
    @State private var viewMode: ViewMode = .month
    @State private var currentDate = Date()
    @State private var dayChangeTimer: Timer?

    enum ViewMode: String, CaseIterable {
        case month = "Month"
        case year = "Year"
    }

    private let calendar = Calendar.current

    private var monthYearString: String {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"
        let date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth)) ?? Date()
        return monthFormatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Controls section
                VStack(spacing: HabitTheme.Spacing.md) {
                    // View mode toggle
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, HabitTheme.Spacing.lg)

                    // Date navigation
                    if viewMode == .month {
                        monthNavigation
                    } else {
                        yearNavigation
                    }
                }
                .padding(.vertical, HabitTheme.Spacing.md)

                // Content
                ScrollView {
                    if viewMode == .month {
                        MonthCalendarView(
                            year: selectedYear,
                            month: selectedMonth,
                            onDateTap: { date in
                                selectedDate = IdentifiableDate(date: date)
                                HabitTheme.Haptics.selection()
                            }
                        )
                        .padding(.horizontal, HabitTheme.Spacing.lg)
                    } else {
                        YearContributionGrid(
                            year: selectedYear,
                            onDateTap: { date in
                                selectedDate = IdentifiableDate(date: date)
                                HabitTheme.Haptics.selection()
                            }
                        )
                        .padding(.horizontal, HabitTheme.Spacing.lg)
                    }
                }

                // Legend
                legend
            }
            .background(HabitTheme.Colors.surface.ignoresSafeArea())
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedDate) { identifiableDate in
                DateDetailView(date: identifiableDate.date)
            }
            .sheet(isPresented: $showingYearSelector) {
                YearSelectorView(selectedYear: $selectedYear, isPresented: $showingYearSelector)
            }
            .onAppear { startDayChangeTimer() }
            .onDisappear { stopDayChangeTimer() }
        }
    }

    // MARK: - Month Navigation

    private var monthNavigation: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if selectedMonth > 1 {
                        selectedMonth -= 1
                    } else {
                        selectedMonth = 12
                        selectedYear -= 1
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(HabitTheme.Colors.brand)
                    .frame(width: HabitTheme.Layout.minTouchTarget, height: HabitTheme.Layout.minTouchTarget)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(monthYearString)
                .font(HabitTheme.Typography.title)
                .foregroundColor(.primary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if selectedMonth < 12 {
                        selectedMonth += 1
                    } else {
                        selectedMonth = 1
                        selectedYear += 1
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(HabitTheme.Colors.brand)
                    .frame(width: HabitTheme.Layout.minTouchTarget, height: HabitTheme.Layout.minTouchTarget)
            }
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal, HabitTheme.Spacing.lg)
    }

    // MARK: - Year Navigation

    private var yearNavigation: some View {
        HStack {
            Button {
                showingYearSelector = true
            } label: {
                HStack(spacing: 4) {
                    Text(String(selectedYear))
                        .font(HabitTheme.Typography.title)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(HabitTheme.Colors.brand)
            }
            .accessibilityLabel("Select year, currently \(selectedYear)")

            Spacer()

            HStack(spacing: HabitTheme.Spacing.md) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedYear -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(HabitTheme.Colors.brand)
                        .frame(width: HabitTheme.Layout.minTouchTarget, height: HabitTheme.Layout.minTouchTarget)
                }
                .accessibilityLabel("Previous year")

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedYear += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundColor(HabitTheme.Colors.brand)
                        .frame(width: HabitTheme.Layout.minTouchTarget, height: HabitTheme.Layout.minTouchTarget)
                }
                .accessibilityLabel("Next year")
            }
        }
        .padding(.horizontal, HabitTheme.Spacing.lg)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: HabitTheme.Spacing.sm) {
            Text("Less")
                .font(HabitTheme.Typography.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 3) {
                ForEach(0..<6) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HabitTheme.Colors.contributionColor(level: level, scheme: colorScheme))
                        .frame(width: 14, height: 14)
                }
            }

            Text("More")
                .font(HabitTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, HabitTheme.Spacing.lg)
        .padding(.vertical, HabitTheme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Color legend from less to more completion")
    }

    // MARK: - Day Change Timer

    private func startDayChangeTimer() {
        stopDayChangeTimer()
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        let timeUntilMidnight = nextMidnight.timeIntervalSince(now)

        dayChangeTimer = Timer.scheduledTimer(withTimeInterval: timeUntilMidnight, repeats: false) { _ in
            currentDate = Date()
            startDayChangeTimer()
        }

        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            let now = Date()
            if !calendar.isDate(currentDate, inSameDayAs: now) {
                currentDate = now
            }
        }
    }

    private func stopDayChangeTimer() {
        dayChangeTimer?.invalidate()
        dayChangeTimer = nil
    }
}

// MARK: - Contribution Cell

struct ContributionCell: View {
    let date: Date
    let completionCount: Int
    let totalHabits: Int
    let isToday: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 4)
                .fill(cellColor)
                .frame(width: HabitTheme.Layout.contributionCellSize, height: HabitTheme.Layout.contributionCellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isToday ? HabitTheme.Colors.brand : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view details")
    }

    private var cellColor: Color {
        let level = HabitTheme.Colors.contributionLevel(completed: completionCount, total: totalHabits)
        return HabitTheme.Colors.contributionColor(level: level, scheme: colorScheme)
    }

    private var accessibilityDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: date)
        if totalHabits == 0 { return "\(dateStr), no habits tracked" }
        let pct = Int(Double(completionCount) / Double(totalHabits) * 100)
        return "\(dateStr), \(completionCount) of \(totalHabits) completed, \(pct) percent"
    }
}

// MARK: - Year Selector View

struct YearSelectorView: View {
    @Binding var selectedYear: Int
    @Binding var isPresented: Bool

    private let currentYear = Calendar.current.component(.year, from: Date())
    private let startYear = 2024

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: HabitTheme.Spacing.md) {
                    ForEach(availableYears(), id: \.self) { year in
                        Button {
                            selectedYear = year
                            HabitTheme.Haptics.selection()
                            isPresented = false
                        } label: {
                            VStack(spacing: HabitTheme.Spacing.xs) {
                                Text(String(year))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedYear == year ? .white : .primary)

                                if year == currentYear {
                                    Text("Current")
                                        .font(HabitTheme.Typography.caption)
                                        .foregroundColor(selectedYear == year ? .white.opacity(0.8) : .secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .background(
                                RoundedRectangle(cornerRadius: HabitTheme.Layout.cornerRadiusSmall)
                                    .fill(selectedYear == year ? HabitTheme.Colors.brand : HabitTheme.Colors.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: HabitTheme.Layout.cornerRadiusSmall)
                                    .stroke(Color(.separator).opacity(0.2), lineWidth: selectedYear == year ? 0 : 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(year)\(year == currentYear ? ", current year" : "")\(year == selectedYear ? ", selected" : "")")
                    }
                }
                .padding(HabitTheme.Spacing.lg)
            }
            .background(HabitTheme.Colors.surface.ignoresSafeArea())
            .navigationTitle("Select Year")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .font(HabitTheme.Typography.bodyMedium)
                }
            }
        }
    }

    private func availableYears() -> [Int] {
        Array(startYear...currentYear + 2)
    }
}

// MARK: - Date Detail View

struct DateDetailView: View {
    let date: Date
    @EnvironmentObject var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d, yyyy"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HabitTheme.Spacing.xl) {
                    let progress = viewModel.getProgressForDate(date)
                    let allHabits = viewModel.getAllHabitsForDate(date)

                    // Progress summary
                    if progress.total > 0 {
                        progressSection(progress: progress)
                    }

                    // Active habits
                    if !allHabits.active.isEmpty {
                        habitsSection(habits: allHabits.active, title: "Habits")
                    }

                    // Archived habits
                    if !allHabits.archived.isEmpty {
                        archivedSection(habits: allHabits.archived)
                    }

                    if allHabits.active.isEmpty && allHabits.archived.isEmpty {
                        VStack(spacing: HabitTheme.Spacing.md) {
                            Image(systemName: "calendar.badge.minus")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No habits tracked on this date")
                                .font(HabitTheme.Typography.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HabitTheme.Spacing.xxxl)
                    }
                }
                .padding(HabitTheme.Spacing.lg)
            }
            .background(HabitTheme.Colors.surface.ignoresSafeArea())
            .navigationTitle(dateFormatter.string(from: date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(HabitTheme.Typography.bodyMedium)
                }
            }
        }
    }

    // MARK: - Progress Section

    private func progressSection(progress: (completed: Int, total: Int)) -> some View {
        let pct = Double(progress.completed) / Double(progress.total)

        return HStack(spacing: HabitTheme.Spacing.xl) {
            ProgressRing(progress: pct, size: 72, lineWidth: 8)

            VStack(alignment: .leading, spacing: HabitTheme.Spacing.xs) {
                Text("\(progress.completed) of \(progress.total)")
                    .font(HabitTheme.Typography.title3)
                    .foregroundColor(.primary)

                Text("habits completed")
                    .font(HabitTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(HabitTheme.Spacing.lg)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.completed) of \(progress.total) habits completed, \(Int(pct * 100)) percent")
    }

    // MARK: - Habits Section

    private func habitsSection(habits: [Habit], title: String) -> some View {
        VStack(alignment: .leading, spacing: HabitTheme.Spacing.md) {
            Text(title)
                .font(HabitTheme.Typography.headline)
                .foregroundColor(.primary)

            VStack(spacing: HabitTheme.Spacing.sm) {
                ForEach(habits) { habit in
                    let isCompleted = viewModel.isHabitCompletedOnDate(habit, date: date)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            viewModel.toggleHabitCompletion(habit, for: date)
                        }
                        HabitTheme.Haptics.toggle()
                    } label: {
                        HStack(spacing: HabitTheme.Spacing.md) {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(isCompleted ? HabitTheme.Colors.success : Color(.tertiaryLabel))
                                .frame(width: HabitTheme.Layout.minTouchTarget, height: HabitTheme.Layout.minTouchTarget)
                                .contentTransition(.symbolEffect(.replace))

                            Text(habit.name)
                                .font(HabitTheme.Typography.bodyMedium)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(.horizontal, HabitTheme.Spacing.lg)
                        .padding(.vertical, HabitTheme.Spacing.xs)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(habit.name), \(isCompleted ? "completed" : "not completed")")
                    .accessibilityHint("Double tap to toggle completion")
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Archived Section

    private func archivedSection(habits: [Habit]) -> some View {
        VStack(alignment: .leading, spacing: HabitTheme.Spacing.md) {
            Text("Archived")
                .font(HabitTheme.Typography.headline)
                .foregroundColor(.secondary)

            VStack(spacing: HabitTheme.Spacing.sm) {
                ForEach(habits) { habit in
                    HStack(spacing: HabitTheme.Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(HabitTheme.Colors.success.opacity(0.6))
                            .frame(width: HabitTheme.Layout.minTouchTarget, height: HabitTheme.Layout.minTouchTarget)

                        Text(habit.name)
                            .font(HabitTheme.Typography.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("Archived")
                            .font(HabitTheme.Typography.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, HabitTheme.Spacing.sm)
                            .padding(.vertical, HabitTheme.Spacing.xs)
                            .background(Color(.systemGray5))
                            .cornerRadius(HabitTheme.Layout.cornerRadiusTiny)
                    }
                    .padding(.horizontal, HabitTheme.Spacing.lg)
                    .padding(.vertical, HabitTheme.Spacing.xs)
                    .accessibilityLabel("\(habit.name), archived, completed")
                }
            }
            .cardStyle()
        }
    }
}
