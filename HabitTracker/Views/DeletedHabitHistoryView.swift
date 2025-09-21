//
//  DeletedHabitHistoryView.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import SwiftUI

struct DeletedHabitHistoryView: View {
    @ObservedObject var viewModel: HabitViewModel
    @State private var expandedHabits: Set<UUID> = []
    
    private let dateFormatter = DateFormatter()
    
    init(viewModel: HabitViewModel) {
        self.viewModel = viewModel
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.deletedHabits.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "trash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No deleted habits")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text("Deleted habits and their completion history will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.getDeletedHabitsWithHistory()) { habit in
                            VStack(alignment: .leading, spacing: 12) {
                                // Habit header
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(habit.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        if let deletedAt = habit.deletedAt {
                                            Text("Deleted on \(dateFormatter.string(from: deletedAt))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text("\(habit.completionHistory.count) completions")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            if expandedHabits.contains(habit.id) {
                                                expandedHabits.remove(habit.id)
                                            } else {
                                                expandedHabits.insert(habit.id)
                                            }
                                        }
                                    }) {
                                        Image(systemName: expandedHabits.contains(habit.id) ? "chevron.up" : "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                // Completion history (expandable)
                                if expandedHabits.contains(habit.id) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Divider()
                                        
                                        if habit.completionHistory.isEmpty {
                                            Text("No completion history")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .italic()
                                        } else {
                                            Text("Completion History:")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            LazyVStack(alignment: .leading, spacing: 4) {
                                                ForEach(viewModel.getCompletionHistoryForDeletedHabit(habit), id: \.self) { dateString in
                                                    HStack {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.caption)
                                                            .foregroundColor(.green)
                                                        
                                                        Text(viewModel.formatCompletionDate(dateString))
                                                            .font(.caption)
                                                            .foregroundColor(.primary)
                                                        
                                                        Spacer()
                                                    }
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 2)
                                                    .background(Color.green.opacity(0.1))
                                                    .cornerRadius(6)
                                                }
                                            }
                                        }
                                    }
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                            }
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Habit History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    DeletedHabitHistoryView(viewModel: HabitViewModel())
}
