import SwiftUI

struct HabitListView: View {
    @EnvironmentObject var viewModel: HabitViewModel
    @State private var showingAddHabit = false
    @State private var showingEditHabits = false
    @State private var showingDeveloperMode = false
    @State private var titleTapCount = 0
    @State private var tapResetTimer: Timer?
    @State private var currentDate = Date()
    @State private var dayChangeTimer: Timer?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HabitTheme.Spacing.xl) {
                    if viewModel.habits.isEmpty {
                        emptyState
                    } else {
                        progressHeader
                        habitCards
                    }
                }
                .padding(.horizontal, HabitTheme.Spacing.lg)
                .padding(.vertical, HabitTheme.Spacing.lg)
            }
            .background(HabitTheme.Colors.surface.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: handleTitleTap) {
                        Text("My Habits")
                            .font(HabitTheme.Typography.headline)
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: HabitTheme.Spacing.sm) {
                        if !viewModel.habits.isEmpty {
                            Button { showingEditHabits = true } label: {
                                Image(systemName: "pencil")
                                    .font(.body)
                            }
                        }
                        Button { showingAddHabit = true } label: {
                            Image(systemName: "plus")
                                .font(.body.weight(.semibold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(isPresented: $showingEditHabits) {
                EditHabitsView()
            }
            .alert("Developer Mode", isPresented: $showingDeveloperMode) {
                Button("Add Mocks") { viewModel.addMocksForCurrentYear() }
                Button("Delete Mocks", role: .destructive) { viewModel.deleteAllMocks() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Do you want to add or delete mock data?")
            }
        }
        .onAppear { startDayChangeTimer() }
        .onDisappear { stopDayChangeTimer() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: HabitTheme.Spacing.xl) {
            Spacer(minLength: 60)

            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundStyle(HabitTheme.Colors.brand.opacity(0.6))
                .padding(.bottom, HabitTheme.Spacing.sm)

            VStack(spacing: HabitTheme.Spacing.sm) {
                Text("Build Better Habits")
                    .font(HabitTheme.Typography.title)
                    .foregroundColor(.primary)

                Text("Track your daily routines and\nwatch your progress grow.")
                    .font(HabitTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddHabit = true
            } label: {
                Label("Add Your First Habit", systemImage: "plus")
                    .font(HabitTheme.Typography.bodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: 240)
                    .padding(.vertical, HabitTheme.Spacing.md)
                    .background(HabitTheme.Colors.brand)
                    .cornerRadius(HabitTheme.Layout.cornerRadius)
            }
            .padding(.top, HabitTheme.Spacing.sm)

            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No habits yet. Tap Add Your First Habit to get started.")
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        let todayProgress = viewModel.getTodayProgress()
        let progress = todayProgress.total > 0
            ? Double(todayProgress.completed) / Double(todayProgress.total)
            : 0

        return VStack(spacing: HabitTheme.Spacing.lg) {
            VStack(spacing: HabitTheme.Spacing.xs) {
                Text(HabitTheme.greeting)
                    .font(HabitTheme.Typography.title)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(dateFormatter.string(from: currentDate))
                    .font(HabitTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: HabitTheme.Spacing.xxl) {
                ProgressRing(progress: progress, size: 96, lineWidth: 10)

                VStack(alignment: .leading, spacing: HabitTheme.Spacing.sm) {
                    Text("\(todayProgress.completed) of \(todayProgress.total)")
                        .font(HabitTheme.Typography.title3)
                        .foregroundColor(.primary)

                    Text("habits completed")
                        .font(HabitTheme.Typography.subheadline)
                        .foregroundColor(.secondary)

                    Text(HabitTheme.motivationalText(
                        completed: todayProgress.completed,
                        total: todayProgress.total
                    ))
                    .font(HabitTheme.Typography.caption)
                    .foregroundColor(HabitTheme.Colors.brand)
                    .padding(.top, HabitTheme.Spacing.xs)
                }

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(todayProgress.completed) of \(todayProgress.total) habits completed today, \(Int(progress * 100)) percent")
        }
        .padding(HabitTheme.Spacing.xl)
        .cardStyle()
    }

    // MARK: - Habit Cards

    private var habitCards: some View {
        VStack(spacing: HabitTheme.Spacing.md) {
            ForEach(viewModel.habits) { habit in
                let isCompleted = viewModel.isCompleted(habit)
                let streak = viewModel.getStreakCount(for: habit)

                Button {
                    let wasCompleted = isCompleted
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        viewModel.toggleHabitCompletion(habit)
                    }
                    if !wasCompleted {
                        HabitTheme.Haptics.toggle()
                        let updated = viewModel.getTodayProgress()
                        if updated.completed == updated.total {
                            HabitTheme.Haptics.success()
                        }
                    } else {
                        HabitTheme.Haptics.selection()
                    }
                } label: {
                    HStack(spacing: HabitTheme.Spacing.md) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isCompleted ? HabitTheme.Colors.success : Color(.tertiaryLabel))
                            .frame(width: HabitTheme.Layout.minTouchTarget, height: HabitTheme.Layout.minTouchTarget)
                            .contentTransition(.symbolEffect(.replace))

                        Text(habit.name)
                            .font(HabitTheme.Typography.bodyMedium)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if streak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                    .foregroundColor(HabitTheme.Colors.streak)
                                Text("\(streak)")
                                    .font(HabitTheme.Typography.captionMedium)
                                    .foregroundColor(HabitTheme.Colors.streak)
                            }
                            .padding(.horizontal, HabitTheme.Spacing.sm)
                            .padding(.vertical, HabitTheme.Spacing.xs)
                            .background(HabitTheme.Colors.streakSoft)
                            .cornerRadius(HabitTheme.Layout.cornerRadiusTiny)
                        }
                    }
                    .padding(HabitTheme.Spacing.lg)
                    .cardStyle(isHighlighted: isCompleted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(habit.name), \(isCompleted ? "completed" : "not completed")\(streak > 0 ? ", \(streak) day streak" : "")")
                .accessibilityHint(isCompleted ? "Double tap to mark as not completed" : "Double tap to mark as completed")
            }
        }
    }

    // MARK: - Timer & Dev Mode

    private func handleTitleTap() {
        titleTapCount += 1
        tapResetTimer?.invalidate()
        if titleTapCount == 7 {
            showingDeveloperMode = true
            titleTapCount = 0
        } else {
            tapResetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                titleTapCount = 0
            }
        }
    }

    private func startDayChangeTimer() {
        stopDayChangeTimer()
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        let timeUntilMidnight = nextMidnight.timeIntervalSince(now)

        dayChangeTimer = Timer.scheduledTimer(withTimeInterval: timeUntilMidnight, repeats: false) { _ in
            currentDate = Date()
            viewModel.refreshForNewDay()
            startDayChangeTimer()
        }

        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            let now = Date()
            if !calendar.isDate(currentDate, inSameDayAs: now) {
                currentDate = now
                viewModel.refreshForNewDay()
            }
        }
    }

    private func stopDayChangeTimer() {
        dayChangeTimer?.invalidate()
        dayChangeTimer = nil
    }
}
