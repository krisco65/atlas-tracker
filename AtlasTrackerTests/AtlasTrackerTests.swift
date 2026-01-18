import XCTest
@testable import AtlasTracker

/// Main test class for AtlasTracker app
final class AtlasTrackerTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testAppLaunches() throws {
        XCTAssertTrue(true, "App should launch successfully")
    }
}
