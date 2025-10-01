# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HabitTracker is a native iOS habit tracking app built with SwiftUI following the MVVM architecture pattern. The app allows users to track up to 10 daily habits with persistent local storage and visualizations showing completion history over time.

**Tech Stack:**
- SwiftUI (iOS 18.4+)
- Swift 5.9+
- UserDefaults for persistence
- MVVM architecture

## Build & Run

Open and run the project:
```bash
open HabitTracker.xcodeproj
# Then build and run in Xcode with ⌘+R
```

**Note:** This is a standard Xcode project without external dependencies. No package manager (CocoaPods, SPM, etc.) is required.

## Architecture

### MVVM Pattern
- **Model**: `Habit` struct (HabitTracker/Models/Habit.swift)
  - Contains habit metadata: id, name, deletedAt timestamp, and completionHistory array
- **ViewModel**: `HabitViewModel` class (HabitTracker/ViewModels/HabitViewModel.swift)
  - Central source of truth for all habit data
  - Handles all business logic, persistence, and state management
  - Published properties trigger automatic UI updates
- **Views**: SwiftUI views in HabitTracker/Views/
  - Observe ViewModel and reactively update
  - Entry point: `HabitListView` (set in HabitTrackerApp.swift)

### Key Architectural Decisions

**Data Persistence Strategy:**
The app uses three separate UserDefaults keys for data storage:
1. `habits` - Active habits array (JSON encoded)
2. `deletedHabits` - Deleted habits with completion history preserved (JSON encoded)
3. `habitHistory` - Global completion tracking: `[String: [UUID]]` mapping date strings ("yyyy-MM-dd") to completed habit IDs

When a habit is deleted:
- It's moved from `habits` to `deletedHabits` with a `deletedAt` timestamp
- Its `completionHistory` array is preserved for historical viewing
- It's removed from the daily `habitHistory` dictionary

**Date Handling:**
- All dates use "yyyy-MM-dd" string format as dictionary keys
- DateFormatter is used consistently via `dateKey(_:)` method in HabitViewModel
- Calendar calculations use `Calendar.current` for proper timezone handling

**State Management:**
- Single `@StateObject` ViewModel per view hierarchy
- Passed via `@EnvironmentObject` for nested views (e.g., HabitGridView)
- All data mutations go through ViewModel methods to ensure persistence

## Key Components

### HabitViewModel (ViewModels/HabitViewModel.swift)
Central data manager with key methods:
- `toggleHabitCompletion(_:for:)` - Toggle habit completion for any date
- `addHabit(name:)` - Add new habit (max 10, validates input)
- `deleteHabit(_:)` - Soft delete (moves to deletedHabits)
- `getProgressForDate(_:)` - Calculate completion stats including archived habits
- `getAllHabitsForDate(_:)` - Returns both active and relevant deleted habits for a date
- `addMockData()` / `clearAllData()` - Testing utilities

### Progress Visualization

**Two View Modes:**
1. **Month View** (MonthCalendarView.swift) - Traditional calendar grid showing days of selected month
2. **Year View** (YearContributionGrid.swift) - GitHub-style contribution grid showing entire year

**Color Coding:**
Progress is shown using 6 levels of green shading based on completion percentage:
- Level 0: Gray (0% complete)
- Level 1: Very light green (1-20%)
- Level 2: Light green (21-40%)
- Level 3: Medium green (41-60%)
- Level 4: Dark green (61-80%)
- Level 5: Darkest green (81-100%)

**Historical Data:**
The progress views intelligently handle deleted habits - when viewing a past date, deleted habits that were active on that date are included in the completion calculation and shown as "Archived" in the detail view.

### Text Input Limiting
Custom text field modifier in Extensions/TextFieldLimiter.swift limits habit names to 30 characters.

## Common Development Tasks

### Adding New Habit Properties
1. Add property to `Habit` struct in Models/Habit.swift
2. Update `HabitViewModel` load/save methods if persistence is needed
3. Update relevant views to display/edit the new property

### Modifying Progress Calculations
All progress calculation logic lives in HabitViewModel:
- `getProgressForDate(_:)` - Main progress calculation
- `getTodayProgress()` - Today's progress (filters orphaned habits)
- `getCompletionRate(for:)` - Rate for specific date
- `getStreakCount(for:)` - Consecutive completion days

### Testing with Mock Data
The ViewModel includes `addMockData()` which creates:
- 4 active habits
- 5 deleted habits with realistic completion patterns
- 7 days of completion history for active habits

Access via the toolbar button in HabitListView (visible in debug builds).

## File Structure

```
HabitTracker/
├── HabitTracker/
│   ├── HabitTrackerApp.swift           # App entry point
│   ├── ContentView.swift               # Unused default view
│   ├── Models/
│   │   └── Habit.swift                 # Core data model
│   ├── ViewModels/
│   │   └── HabitViewModel.swift        # Business logic & persistence
│   ├── Views/
│   │   ├── HabitListView.swift         # Main screen (entry point)
│   │   ├── AddHabitView.swift          # Add habit modal
│   │   ├── EditHabitsView.swift        # Edit mode for all habits
│   │   ├── EditHabitView.swift         # Individual habit editor
│   │   ├── HabitGridView.swift         # Progress screen with month/year toggle
│   │   ├── MonthCalendarView.swift     # Monthly calendar grid
│   │   ├── YearContributionGrid.swift  # GitHub-style year grid
│   │   └── DeletedHabitHistoryView.swift # View deleted habits history
│   └── Extensions/
│       └── TextFieldLimiter.swift      # 30-char limit for habit names
├── HabitTrackerTests/
└── HabitTrackerUITests/
```

## Important Constraints

- **Maximum 10 habits** enforced in `addHabit(name:)`
- **30 character limit** on habit names via TextFieldLimiter
- **iOS 18.4+** minimum deployment target
- **No external dependencies** - pure SwiftUI/Foundation

## Debugging

The ViewModel includes extensive print statements prefixed with emoji:
- ✅ Success operations
- ❌ Errors
- ℹ️ Info/warnings
- 📊 Statistics
- 📅 Date operations
- 📱 UI state changes

Check Xcode console for detailed operation logs during development.
