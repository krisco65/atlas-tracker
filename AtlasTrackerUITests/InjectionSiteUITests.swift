import XCTest

/// UI Tests for Injection Site Selection
/// Tests the body diagram and belly drill-down sheet
final class InjectionSiteUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// Navigate to dose logging screen where injection site picker appears
    private func navigateToLogDose() -> Bool {
        // Try multiple paths to reach log dose screen
        let tabBar = app.tabBars.firstMatch

        // First ensure we're on dashboard
        if tabBar.buttons["Dashboard"].exists {
            tabBar.buttons["Dashboard"].tap()
        }

        // Look for "Log Dose" button or "+" button
        if app.buttons["Log Dose"].waitForExistence(timeout: 3) {
            app.buttons["Log Dose"].tap()
            return true
        }

        // Try tapping a dose card if available
        let doseCards = app.buttons.matching(identifier: "dose_card")
        if doseCards.count > 0 {
            doseCards.firstMatch.tap()
            return true
        }

        return false
    }

    // MARK: - Belly Region Tests

    /// Test: Tapping belly region opens drill-down sheet with 4 zone buttons
    func testBellyRegionShowsFourZoneGrid() throws {
        // This test verifies the bug fix for blank belly sheet

        // Navigate to injection site selection
        guard navigateToLogDose() else {
            throw XCTSkip("Could not navigate to log dose screen - no active compounds")
        }

        // Wait for body diagram to appear
        let bellyButton = app.buttons["region_button_belly"]
        guard bellyButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Belly region button not found - may be PED injection type")
        }

        // Tap belly region
        bellyButton.tap()

        // Sheet should appear with 4 zone buttons
        let upperLeftButton = app.buttons["sub_option_upper_left"]
        let upperRightButton = app.buttons["sub_option_upper_right"]
        let lowerLeftButton = app.buttons["sub_option_lower_left"]
        let lowerRightButton = app.buttons["sub_option_lower_right"]

        // Wait for sheet to appear
        XCTAssertTrue(upperLeftButton.waitForExistence(timeout: 3),
                      "Upper Left button should be visible in belly sheet")
        XCTAssertTrue(upperRightButton.exists,
                      "Upper Right button should be visible in belly sheet")
        XCTAssertTrue(lowerLeftButton.exists,
                      "Lower Left button should be visible in belly sheet")
        XCTAssertTrue(lowerRightButton.exists,
                      "Lower Right button should be visible in belly sheet")

        // Close button should exist
        let closeButton = app.buttons["sub_option_sheet_close"]
        XCTAssertTrue(closeButton.exists, "Close button should be visible")
    }

    /// Test: Selecting a belly zone updates selection
    func testBellyZoneSelection() throws {
        guard navigateToLogDose() else {
            throw XCTSkip("Could not navigate to log dose screen")
        }

        let bellyButton = app.buttons["region_button_belly"]
        guard bellyButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Belly region button not found")
        }

        bellyButton.tap()

        let upperLeftButton = app.buttons["sub_option_upper_left"]
        guard upperLeftButton.waitForExistence(timeout: 3) else {
            XCTFail("Belly zone buttons did not appear - BLANK SHEET BUG")
            return
        }

        // Tap upper left zone
        upperLeftButton.tap()

        // Sheet should dismiss (button should disappear)
        XCTAssertTrue(upperLeftButton.waitForNonExistence(timeout: 2),
                      "Sheet should dismiss after selection")
    }

    /// Test: Close button dismisses sheet without selection
    func testBellySheetCloseButton() throws {
        guard navigateToLogDose() else {
            throw XCTSkip("Could not navigate to log dose screen")
        }

        let bellyButton = app.buttons["region_button_belly"]
        guard bellyButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Belly region button not found")
        }

        bellyButton.tap()

        let closeButton = app.buttons["sub_option_sheet_close"]
        guard closeButton.waitForExistence(timeout: 3) else {
            XCTFail("Close button not found - BLANK SHEET BUG")
            return
        }

        closeButton.tap()

        // Sheet should dismiss
        XCTAssertTrue(closeButton.waitForNonExistence(timeout: 2),
                      "Sheet should dismiss when close button tapped")
    }

    // MARK: - Other Region Tests

    /// Test: Love handle regions show 2-zone options
    func testLoveHandleRegionShowsTwoZones() throws {
        guard navigateToLogDose() else {
            throw XCTSkip("Could not navigate to log dose screen")
        }

        let loveHandleButton = app.buttons["region_button_love_handle_left"]
        guard loveHandleButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Love handle button not found")
        }

        loveHandleButton.tap()

        let upperButton = app.buttons["sub_option_upper"]
        let lowerButton = app.buttons["sub_option_lower"]

        XCTAssertTrue(upperButton.waitForExistence(timeout: 3),
                      "Upper button should appear for love handle")
        XCTAssertTrue(lowerButton.exists,
                      "Lower button should appear for love handle")
    }

    /// Test: Thigh regions select directly (no sub-options)
    func testThighRegionSelectsDirectly() throws {
        guard navigateToLogDose() else {
            throw XCTSkip("Could not navigate to log dose screen")
        }

        let thighButton = app.buttons["region_button_thigh_left"]
        guard thighButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Thigh button not found")
        }

        thighButton.tap()

        // No sheet should appear - should select directly
        // Verify no sub-option buttons appear
        let subOptionButton = app.buttons["sub_option_upper"]
        XCTAssertFalse(subOptionButton.waitForExistence(timeout: 1),
                       "Thigh should not show sub-option sheet")
    }

    // MARK: - PED Injection Site Tests

    /// Test: PED sites show direct selection buttons
    func testPEDSiteButtonsExist() throws {
        guard navigateToLogDose() else {
            throw XCTSkip("Could not navigate to log dose screen")
        }

        // PED sites use different buttons
        let pedSiteButtons = [
            "ped_site_button_glute_left",
            "ped_site_button_glute_right",
            "ped_site_button_delt_left",
            "ped_site_button_delt_right"
        ]

        // Check if any PED button exists (indicates PED injection type)
        var foundPEDButton = false
        for buttonId in pedSiteButtons {
            if app.buttons[buttonId].waitForExistence(timeout: 2) {
                foundPEDButton = true
                break
            }
        }

        if foundPEDButton {
            // Test that PED buttons are tappable
            for buttonId in pedSiteButtons {
                let button = app.buttons[buttonId]
                if button.exists {
                    XCTAssertTrue(button.isHittable, "\(buttonId) should be tappable")
                }
            }
        } else {
            throw XCTSkip("PED injection sites not shown - likely peptide compound")
        }
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {
    /// Wait for element to not exist (disappear)
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
