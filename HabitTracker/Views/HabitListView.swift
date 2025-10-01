import SwiftUI

struct HabitListView: View {
    @StateObject private var viewModel = HabitViewModel();
    @State private var showingDeleteHabit = false
    @State private var showingAddHabit = false
    @State private var showingEditHabit = false
    @State private var showingHistory = false
    @State private var showingDeveloperMode = false
    @State private var titleTapCount = 0
    @State private var tapResetTimer: Timer?
    
    private let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with current date and progress - only show when there are habits
                if !viewModel.habits.isEmpty {
                    VStack(spacing: 8) {
                        Text(dateFormatter.string(from: Date()))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        let todayProgress = viewModel.getTodayProgress()
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(todayProgress.completed)/\(todayProgress.total) habits completed today")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int((Double(todayProgress.completed) / Double(todayProgress.total)) * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            
                            ProgressView(value: Double(todayProgress.completed), total: Double(todayProgress.total))
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                .frame(height: 8)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center) // Make it slightly thicker
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
                
                // Habits list
                if viewModel.habits.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "target")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No habits yet")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text("Tap the + button to add your first habit")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.habits) { habit in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(habit.name)
                                        .font(.body)
                                        .foregroundColor(viewModel.isCompleted(habit) ? .green : .primary)
                                    
                                    // Show streak count
                                    let streak = viewModel.getStreakCount(for: habit)
                                    if streak > 0 {
                                        Text("🔥 \(streak) day streak")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.toggleHabitCompletion(habit)
                                    }
                                }) {
                                    Image(systemName: viewModel.isCompleted(habit) ? "checkmark.square.fill" : "square")
                                        .font(.title2)
                                        .foregroundColor(viewModel.isCompleted(habit) ? .green : .gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Progress view button
                NavigationLink(destination: HabitGridView().environmentObject(viewModel)) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("View Progress")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        handleTitleTap()
                    }) {
                        Text("My Habits")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingHistory = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                            if !viewModel.deletedHabits.isEmpty {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditHabit = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingEditHabit) {
                EditHabitsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingHistory) {
                DeletedHabitHistoryView(viewModel: viewModel)
            }
            .alert("Developer Mode", isPresented: $showingDeveloperMode) {
                Button("Add Mocks") {
                    viewModel.addMocksForCurrentYear()
                }
                Button("Delete Mocks", role: .destructive) {
                    viewModel.deleteAllMocks()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Do you want to add or delete mock data?")
            }
        }
    }

    private func handleTitleTap() {
        titleTapCount += 1

        // Cancel existing timer
        tapResetTimer?.invalidate()

        // Check if reached 7 taps
        if titleTapCount == 7 {
            showingDeveloperMode = true
            titleTapCount = 0
        } else {
            // Reset counter after 2 seconds of inactivity
            tapResetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                titleTapCount = 0
            }
        }
    }
}
