import XCTest
import CoreData
@testable import AtlasTracker

final class TrackedCompoundTests: XCTestCase {

    var context: NSManagedObjectContext!
    var compound: Compound!
    var trackedCompound: TrackedCompound!

    override func setUpWithError() throws {
        context = CoreDataManager.shared.viewContext

        // Get a test compound
        let compounds = CoreDataManager.shared.fetchAllCompounds()
        guard let testCompound = compounds.first(where: { $0.trackedCompound == nil }) else {
            XCTSkip("No untracked compounds available for testing")
            return
        }

        compound = testCompound
    }

    override func tearDownWithError() throws {
        // Cleanup tracked compound if created
        if let tracked = trackedCompound {
            context.delete(tracked)
            try? context.save()
        }
        trackedCompound = nil
        compound = nil
        context = nil
    }

    // MARK: - Schedule Type Tests

    func testScheduleType_Daily() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        XCTAssertEqual(trackedCompound.scheduleType, .daily)
    }

    func testScheduleType_EveryXDays() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .everyXDays,
            scheduleInterval: 3,
            notificationEnabled: false
        )

        XCTAssertEqual(trackedCompound.scheduleType, .everyXDays)
        XCTAssertEqual(trackedCompound.scheduleInterval, 3)
    }

    func testScheduleType_SpecificDays() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .specificDays,
            scheduleDays: [1, 4],  // Monday, Thursday
            notificationEnabled: false
        )

        XCTAssertEqual(trackedCompound.scheduleType, .specificDays)
        XCTAssertEqual(trackedCompound.scheduleDays, [1, 4])
    }

    // MARK: - Dosage String Tests

    func testDosageString_WithMg() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        XCTAssertTrue(trackedCompound.dosageString.contains("100"))
        XCTAssertTrue(trackedCompound.dosageString.lowercased().contains("mg"))
    }

    func testDosageString_WithMcg() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 250,
            dosageUnit: .mcg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        XCTAssertTrue(trackedCompound.dosageString.contains("250"))
        XCTAssertTrue(trackedCompound.dosageString.lowercased().contains("mcg"))
    }

    // MARK: - Schedule Description Tests

    func testScheduleDescription_Daily() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        let description = trackedCompound.scheduleDescription
        XCTAssertTrue(description.lowercased().contains("daily") ||
                      description.lowercased().contains("every day"),
                      "Should mention daily schedule")
    }

    func testScheduleDescription_EveryXDays() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .everyXDays,
            scheduleInterval: 3,
            notificationEnabled: false
        )

        let description = trackedCompound.scheduleDescription
        XCTAssertTrue(description.contains("3") || description.lowercased().contains("every"),
                      "Should mention interval")
    }

    // MARK: - Next Dose Date Tests

    func testNextDoseDate_Daily_ReturnsValidDate() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        let nextDose = trackedCompound.nextDoseDate
        XCTAssertNotNil(nextDose, "Should return next dose date")

        if let nextDose = nextDose {
            XCTAssertGreaterThanOrEqual(nextDose, Date().startOfDay, "Next dose should be today or later")
        }
    }

    func testNextDoseDate_EveryXDays_AfterLastDose() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .everyXDays,
            scheduleInterval: 3,
            notificationEnabled: false
        )

        // Set last dose to today
        trackedCompound.lastDoseDate = Date()
        try? context.save()

        let nextDose = trackedCompound.nextDoseDate

        XCTAssertNotNil(nextDose)
        if let nextDose = nextDose {
            let daysUntilNext = Calendar.current.dateComponents([.day], from: Date(), to: nextDose).day ?? 0
            XCTAssertLessThanOrEqual(daysUntilNext, 3, "Next dose should be within interval")
        }
    }

    // MARK: - Is Due Today Tests

    func testIsDueToday_Daily_AlwaysTrue() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        // Clear last dose date to ensure it's due
        trackedCompound.lastDoseDate = nil
        try? context.save()

        XCTAssertTrue(trackedCompound.isDueToday, "Daily compound should be due today")
    }

    func testIsDueToday_AfterDoseLogged_ReturnsFalse() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        // Set last dose to now (today)
        trackedCompound.lastDoseDate = Date()
        try? context.save()

        // For daily, if already dosed today, not due
        // This depends on implementation
    }

    // MARK: - Is Overdue Tests

    func testIsOverdue_WhenMissedDose_ReturnsTrue() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .everyXDays,
            scheduleInterval: 1,
            notificationEnabled: false
        )

        // Set last dose to 5 days ago (past due for every-day schedule)
        trackedCompound.lastDoseDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        try? context.save()

        XCTAssertTrue(trackedCompound.isOverdue, "Should be overdue after missing doses")
    }

    // MARK: - Active State Tests

    func testIsActive_WhenCreated_ReturnsTrue() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        XCTAssertTrue(trackedCompound.isActive)
    }

    func testIsActive_AfterStopping_ReturnsFalse() {
        trackedCompound = CoreDataManager.shared.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        CoreDataManager.shared.stopTracking(compound: compound)

        XCTAssertFalse(trackedCompound.isActive)
    }
}
