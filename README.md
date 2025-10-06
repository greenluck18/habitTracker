# HabitTracker

A simple and elegant iOS app built with SwiftUI to help you track and build positive habits. Track your daily progress with an intuitive interface and visualize your consistency over time.

## Features

### 🎯 Core Functionality
- **Habit Management**: Add, edit, and delete up to 10 habits
- **Daily Tracking**: Mark habits as completed with a simple tap
- **Progress Visualization**: View your habit completion history in a beautiful grid format
- **Data Persistence**: All your habits and progress are automatically saved locally

### 📱 User Interface
- **Clean List View**: See all your habits at a glance with completion status
- **Intuitive Controls**: Tap to toggle habit completion, swipe to delete
- **Progress Grid**: Visual representation of your consistency over the past 12 months
- **Color-coded Progress**: Different shades of green indicate your completion levels

### 🔧 Technical Features
- **SwiftUI Framework**: Modern, declarative UI development
- **MVVM Architecture**: Clean separation of concerns with ViewModels
- **Local Storage**: Uses UserDefaults for data persistence
- **Date-based Tracking**: Tracks habits by specific dates for accurate history

## Requirements

- **iOS**: 18.4 or later
- **Xcode**: 16.0 or later (for development)
- **Swift**: 5.9 or later

## Installation

### For Users
1. Download the project
2. Open `HabitTracker.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run the project (⌘+R)

### For Developers
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd HabitTracker
   ```
2. Open `HabitTracker.xcodeproj` in Xcode
3. Build and run the project

## Usage

### Adding Habits
1. Tap the "+" button in the top-right corner
2. Enter a habit name (up to 30 characters)
3. Tap "Add" to create the habit

### Tracking Progress
1. View your habits in the main list
2. Tap the checkbox next to any habit to mark it as completed
3. Completed habits appear in green with a checkmark

### Viewing Progress
1. Tap "Progress View" at the bottom of the main screen
2. See a grid showing your completion history over the past 12 months
3. Colors indicate completion levels:
   - Gray: No habits completed
   - Light Green: 1-2 habits completed
   - Medium Green: 3-4 habits completed
   - Dark Green: 5+ habits completed

### Managing Habits
1. Tap the pencil icon to enter edit mode
2. Edit habit names or delete habits
3. Changes are automatically saved

## Project Structure

```
HabitTracker/
├── HabitTracker/
│   ├── Models/
│   │   └── Habit.swift              # Data model for habits
│   ├── ViewModels/
│   │   └── HabitViewModel.swift     # Business logic and data management
│   ├── Views/
│   │   ├── HabitListView.swift      # Main habit list interface
│   │   ├── AddHabitView.swift       # Add new habit form
│   │   ├── EditHabitsView.swift     # Edit/delete habits interface
│   │   ├── EditHabitView.swift      # Individual habit editing
│   │   └── HabitGridView.swift      # Progress visualization
│   ├── Extensions/
│   │   └── TextFieldLimiter.swift   # Text input validation
│   └── HabitTrackerApp.swift        # App entry point
├── HabitTrackerTests/               # Unit tests
└── HabitTrackerUITests/             # UI tests
```

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** pattern:

- **Model**: `Habit` struct representing individual habits
- **View**: SwiftUI views for the user interface
- **ViewModel**: `HabitViewModel` class managing data and business logic

### Data Flow
1. User interactions trigger ViewModel methods
2. ViewModel updates the data model
3. Changes are automatically persisted to UserDefaults
4. Views reactively update based on ViewModel state

## Data Storage

The app uses `UserDefaults` for local data persistence:
- **Habits**: Stored as JSON-encoded array
- **History**: Stored as JSON-encoded dictionary mapping dates to completed habit IDs
- **Automatic Sync**: Data is saved immediately when changes are made

## Customization

### Adding New Features
The modular architecture makes it easy to extend:
- Add new habit properties in `Habit.swift`
- Implement new tracking logic in `HabitViewModel.swift`
- Create new views in the `Views/` directory

### Styling
The app uses SwiftUI's built-in styling with:
- System colors for consistency
- SF Symbols for icons
- Adaptive layouts for different screen sizes

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is available under the MIT License.

## Author

Created by Halyna Mazur in April 2025.

## Acknowledgments

- Built with SwiftUI and iOS 18.4
- Uses SF Symbols for consistent iconography
- Inspired by the need for simple, effective habit tracking

---

**Happy habit building! 🎯**
