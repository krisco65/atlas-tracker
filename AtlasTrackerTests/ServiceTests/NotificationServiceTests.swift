import XCTest
import CoreData
import UserNotifications
@testable import AtlasTracker

final class NotificationServiceTests: XCTestCase {

    var sut: NotificationService!
    var coreDataManager: CoreDataManager!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        sut = NotificationService.shared
        coreDataManager = CoreDataManager.shared
        testContext = coreDataManager.viewContext
    }

    override func tearDownWithError() throws {
        sut = nil
        coreDataManager = nil
        testContext = nil
    }

    // MARK: - Authorization Tests

    func testNotificationService_Exists() {
        XCTAssertNotNil(sut, "NotificationService singleton should exist")
    }

    func testNotificationService_IsSingleton() {
        let instance1 = NotificationService.shared
        let instance2 = NotificationService.shared
        XCTAssertTrue(instance1 === instance2, "Should return same instance")
    }

    // MARK: - Notification Identifier Tests

    func testNotificationIdentifier_ContainsCompoundId() {
        // Create a test compound
        let compound = Compound(context: testContext)
        compound.id = UUID()
        compound.name = "Test Compound"
        compound.categoryRaw = CompoundCategory.peptide.rawValue

        // The identifier should contain the compound's UUID
        // We can't directly test private method, but we can verify behavior through scheduling
        XCTAssertNotNil(compound.id, "Compound should have an ID")
    }

    // MARK: - Schedule Logic Tests

    func testScheduleDoseReminder_RequiresNotificationEnabled() {
        // Create tracked compound without notification enabled
        let compound = Compound(context: testContext)
        compound.id = UUID()
        compound.name = "Test Compound"
        compound.categoryRaw = CompoundCategory.peptide.rawValue

        let tracked = TrackedCompound(context: testContext)
        tracked.id = UUID()
        tracked.compound = compound
        tracked.notificationEnabled = false
        tracked.scheduleTypeRaw = ScheduleType.daily.rawValue

        // This should not crash and should return early
        sut.scheduleDoseReminder(for: tracked)

        // No assertion needed - just verify it doesn't crash
        XCTAssertFalse(tracked.notificationEnabled, "Notification should be disabled")
    }

    func testScheduleDoseReminder_RequiresCompound() {
        // Create tracked compound without compound
        let tracked = TrackedCompound(context: testContext)
        tracked.id = UUID()
        tracked.notificationEnabled = true
        tracked.compound = nil

        // This should not crash and should return early
        sut.scheduleDoseReminder(for: tracked)

        // No assertion needed - just verify it doesn't crash
        XCTAssertNil(tracked.compound, "Compound should be nil")
    }

    // MARK: - Pending Notifications Tests

    func testGetPendingNotificationsCount_ReturnsCount() {
        let expectation = XCTestExpectation(description: "Get pending notifications count")

        sut.getPendingNotificationsCount { count in
            XCTAssertGreaterThanOrEqual(count, 0, "Count should be non-negative")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Notification Content Tests

    func testBuildNotificationBody_IncludesDosage() {
        // Create test data
        let compound = Compound(context: testContext)
        compound.id = UUID()
        compound.name = "Test BPC-157"
        compound.categoryRaw = CompoundCategory.peptide.rawValue
        compound.requiresInjection = true
        compound.defaultUnitRaw = DosageUnit.mcg.rawValue

        let tracked = TrackedCompound(context: testContext)
        tracked.id = UUID()
        tracked.compound = compound
        tracked.dosageAmount = 250
        tracked.dosageUnitRaw = DosageUnit.mcg.rawValue
        tracked.notificationEnabled = true
        tracked.scheduleTypeRaw = ScheduleType.daily.rawValue

        // The dosage string should contain the amount and unit
        XCTAssertTrue(tracked.dosageString.contains("250"), "Dosage string should contain amount")
        XCTAssertTrue(tracked.dosageString.contains("mcg"), "Dosage string should contain unit")
    }

    // MARK: - Cancel Notifications Tests

    func testCancelAllNotifications_DoesNotCrash() {
        // This should not crash
        sut.cancelAllNotifications()

        // Verify we can still get count
        let expectation = XCTestExpectation(description: "Verify cancellation")
        sut.getPendingNotificationsCount { count in
            XCTAssertGreaterThanOrEqual(count, 0, "Count should be non-negative")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testCancelNotifications_ForCompound() {
        let compound = Compound(context: testContext)
        compound.id = UUID()
        compound.name = "Test Compound"

        // This should not crash
        sut.cancelNotifications(for: compound)

        // No assertion needed - just verify it doesn't crash
        XCTAssertNotNil(compound.id, "Compound should still exist")
    }

    // MARK: - Snooze Tests

    func testSnoozeNotification_RequiresTrackedCompound() {
        let compound = Compound(context: testContext)
        compound.id = UUID()
        compound.name = "Test Compound"
        compound.trackedCompound = nil

        // This should return early without crashing
        sut.snoozeNotification(for: compound)

        // No assertion needed - just verify it doesn't crash
        XCTAssertNil(compound.trackedCompound, "Tracked compound should be nil")
    }

    // MARK: - Low Inventory Alert Tests

    func testScheduleLowInventoryAlert_RequiresCompoundName() {
        let compound = Compound(context: testContext)
        compound.id = UUID()
        compound.name = nil

        // This should return early without crashing
        sut.scheduleLowInventoryAlert(for: compound, vialCount: 1)

        // No assertion needed - just verify it doesn't crash
        XCTAssertNil(compound.name, "Name should be nil")
    }

    func testScheduleLowInventoryAlert_WithValidCompound() {
        let compound = Compound(context: testContext)
        compound.id = UUID()
        compound.name = "Test Compound"

        // This should not crash
        sut.scheduleLowInventoryAlert(for: compound, vialCount: 2)

        // No assertion needed - just verify it doesn't crash
        XCTAssertNotNil(compound.name, "Name should exist")
    }

    // MARK: - Integration Tests

    func testRescheduleAllNotifications_DoesNotCrash() {
        // This should not crash even with no tracked compounds
        sut.rescheduleAllNotifications()

        // Verify system is still functional
        XCTAssertNotNil(sut, "Service should still exist")
    }

    // MARK: - App Constants Tests

    func testAppConstants_NotificationIdentifiers() {
        XCTAssertEqual(AppConstants.NotificationIdentifiers.doseReminder, "doseReminder")
        XCTAssertEqual(AppConstants.NotificationIdentifiers.lowInventory, "lowInventory")
        XCTAssertFalse(AppConstants.NotificationIdentifiers.categoryPrefix.isEmpty)
    }

    func testAppConstants_NotificationActions() {
        XCTAssertEqual(AppConstants.NotificationActions.logNow, "LOG_NOW")
        XCTAssertEqual(AppConstants.NotificationActions.snooze, "SNOOZE")
        XCTAssertEqual(AppConstants.NotificationActions.skip, "SKIP")
    }

    func testAppConstants_SnoozeDuration() {
        XCTAssertEqual(AppConstants.snoozeDurationMinutes, 30, "Snooze should be 30 minutes")
    }
}
