//EditHabitsView.swift

import SwiftUI

struct EditHabitsView: View {
    @ObservedObject var viewModel: HabitViewModel
    
    @State private var showingAddHabit = false
    @State private var showingEditHabit = false
    @State private var selectedHabit: Habit? = nil

    var body: some View {
        NavigationView {
            List {
                let enumeratedHabits = Array(viewModel.habits.enumerated())
                ForEach(enumeratedHabits, id: \.element.id) { index, habit in

                    HStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 10, height: 10)
                        
                        Text(habit.name)
                            .foregroundColor(viewModel.isCompleted(habit) ? .green : .primary)
                        
                        Spacer()
                        
                        Button {
                            viewModel.toggleHabitCompletion(habit)
                        } label: {
                            Image(systemName: viewModel.isCompleted(habit) ? "checkmark.square.fill" : "square")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(viewModel.isCompleted(habit) ? .green : .gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedHabit = habit
                        showingEditHabit = true
                    }
                }
                .onDelete { indexSet in
                    viewModel.deleteHabits(at: indexSet)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Your Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingEditHabit) {
                if let habit = selectedHabit {
                       EditHabitView(habit: habit, viewModel: viewModel)
                   }
            }
        }
    }
}
