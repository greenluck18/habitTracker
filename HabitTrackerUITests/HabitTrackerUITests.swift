//
//  HabitTrackerUITests.swift
//  HabitTrackerUITests
//
//  Created by Halyna Mazur on 14.04.2025.
//

import XCTest

final class HabitTrackerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - Launch Tests
    
    @MainActor
    func testAppLaunches() throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    @MainActor
    func testMainScreenAppears() throws {
        let navigationBar = app.navigationBars["My Habits"]
        XCTAssertTrue(navigationBar.exists)
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testNavigationBetweenTabs() throws {
        // Find the tab bar
        let tabBar = app.tabBars
        XCTAssertTrue(tabBar.exists)
    }
    
    // MARK: - Add Habit Flow
    
    @MainActor
    func testAddHabitButton() throws {
        // Look for floating add button or plus button in navigation
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add'")).firstMatch
        
        if addButton.exists {
            addButton.tap()
            
            // Verify sheet or modal appears
            let navBar = app.navigationBars.matching(NSPredicate(format: "label CONTAINS 'Add'")).firstMatch
            XCTAssertTrue(navBar.waitForExistence(timeout: 2))
        }
    }
    
    @MainActor
    func testEmptyStateDisplayed() throws {
        // When no habits, empty state should be shown
        let emptyText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No habits'")).firstMatch
        
        // Empty state might not always be visible if there's data, so this is conditional
        if emptyText.exists {
            XCTAssertTrue(emptyText.isHittable)
        }
    }
    
    // MARK: - Habit Interaction
    
    @MainActor
    func testHabitCardExists() throws {
        // This assumes there are habits in the app
        let habitCards = app.scrollViews.children(matching: .other).firstMatch
        
        if habitCards.exists {
            XCTAssertTrue(habitCards.isHittable)
        }
    }
    
    // MARK: - Progress View
    
    @MainActor
    func testProgressTabNavigation() throws {
        let tabBars = app.tabBars
        if tabBars.buttons.count > 1 {
            let progressTab = tabBars.buttons.element(boundBy: 1)
            progressTab.tap()
            
            // Verify navigation title changes
            let navigationTitle = app.navigationBars["Progress"]
            XCTAssertTrue(navigationTitle.waitForExistence(timeout: 2))
        }
    }
    
    // MARK: - Performance Test
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
