import SwiftUI

struct HabitListView: View {
    @StateObject private var viewModel = HabitViewModel();
    @State private var showingDeleteHabit = false
    @State private var showingAddHabit = false
    @State private var showingEditHabit = false
    
    private let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with current date and progress
                VStack(spacing: 8) {
                    Text(dateFormatter.string(from: Date()))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    let todayProgress = viewModel.getTodayProgress()
                    if todayProgress.total > 0 {
                        VStack(spacing: 4) {
                            Text("\(todayProgress.completed)/\(todayProgress.total) habits completed today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: Double(todayProgress.completed), total: Double(todayProgress.total))
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                .frame(height: 6)
                        }
                    } else {
                        Text("Add your first habit to start tracking!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
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
            .navigationTitle("My Habits")
            .toolbar {
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
        }
    }
}
