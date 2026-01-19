import XCTest

/// Main UI Test class for AtlasTracker
/// Tests critical user flows to catch UI bugs before deployment
final class AtlasTrackerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    func testAppLaunches() throws {
        // Verify app launches without crashing
        XCTAssertTrue(app.state == .runningForeground, "App should be running")
    }

    func testDashboardLoads() throws {
        // Dashboard should be visible after launch
        let dashboardExists = app.navigationBars["Dashboard"].waitForExistence(timeout: 5) ||
                              app.staticTexts["Today's Doses"].waitForExistence(timeout: 5)
        XCTAssertTrue(dashboardExists, "Dashboard should load on app launch")
    }

    // MARK: - Navigation Tests

    func testTabBarNavigation() throws {
        // Test all main tabs are accessible
        let tabBar = app.tabBars.firstMatch

        // Navigate to Library
        if tabBar.buttons["Library"].exists {
            tabBar.buttons["Library"].tap()
            XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 3) ||
                         app.staticTexts["Library"].waitForExistence(timeout: 3))
        }

        // Navigate to Analytics
        if tabBar.buttons["Analytics"].exists {
            tabBar.buttons["Analytics"].tap()
            XCTAssertTrue(app.navigationBars["Analytics"].waitForExistence(timeout: 3) ||
                         app.staticTexts["Analytics"].waitForExistence(timeout: 3))
        }

        // Navigate back to Dashboard
        if tabBar.buttons["Dashboard"].exists {
            tabBar.buttons["Dashboard"].tap()
        }
    }
}
