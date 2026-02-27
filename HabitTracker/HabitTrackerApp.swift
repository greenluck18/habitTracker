//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import SwiftUI

@main
struct HabitTrackerApp: App {
    @StateObject private var viewModel = HabitViewModel()

    var body: some Scene {
        WindowGroup {
            TabView {
                HabitListView()
                    .tabItem {
                        Label("Today", systemImage: "checkmark.circle.fill")
                    }

                HabitGridView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.bar.fill")
                    }

                DeletedHabitHistoryView()
                    .tabItem {
                        Label("Archive", systemImage: "archivebox.fill")
                    }
            }
            .tint(HabitTheme.Colors.brand)
            .environmentObject(viewModel)
        }
    }
}
