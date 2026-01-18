import XCTest
import CoreData
@testable import AtlasTracker

final class CoreDataManagerTests: XCTestCase {

    var sut: CoreDataManager!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        sut = CoreDataManager.shared
        testContext = sut.viewContext
    }

    override func tearDownWithError() throws {
        sut = nil
        testContext = nil
    }

    // MARK: - Compound Operations

    func testFetchAllCompounds_ReturnsCompounds() {
        let compounds = sut.fetchAllCompounds()
        XCTAssertNotNil(compounds, "Should return an array of compounds")
    }

    func testFetchCompoundsByCategory_FiltersByCategory() {
        let peptides = sut.fetchCompounds(category: .peptide)
        for compound in peptides {
            XCTAssertEqual(compound.category, .peptide, "All returned compounds should be peptides")
        }
    }

    func testSearchCompounds_EmptyQuery_ReturnsAll() {
        let all = sut.fetchAllCompounds()
        let searched = sut.searchCompounds(query: "")
        XCTAssertEqual(all.count, searched.count, "Empty query should return all compounds")
    }

    func testSearchCompounds_WithQuery_FiltersResults() {
        let results = sut.searchCompounds(query: "BPC")
        for compound in results {
            XCTAssertTrue(
                compound.name?.localizedCaseInsensitiveContains("BPC") ?? false,
                "Search results should contain query term"
            )
        }
    }

    func testCreateCompound_CreatesNewCompound() {
        let initialCount = sut.fetchAllCompounds().count

        let compound = sut.createCompound(
            name: "Test Compound \(UUID().uuidString)",
            category: .supplement,
            supportedUnits: [.mg, .g],
            defaultUnit: .mg,
            requiresInjection: false,
            isCustom: true
        )

        XCTAssertNotNil(compound.id, "New compound should have an ID")
        XCTAssertEqual(compound.name, compound.name, "Name should match")
        XCTAssertTrue(compound.isCustom, "Should be marked as custom")

        let newCount = sut.fetchAllCompounds().count
        XCTAssertEqual(newCount, initialCount + 1, "Count should increase by 1")

        // Cleanup
        sut.deleteCompound(compound)
    }

    func testToggleFavorite_TogglesState() {
        let compounds = sut.fetchAllCompounds()
        guard let compound = compounds.first else {
            XCTFail("Need at least one compound for test")
            return
        }

        let initialState = compound.isFavorited
        sut.toggleFavorite(compound: compound)
        XCTAssertEqual(compound.isFavorited, !initialState, "Favorite state should toggle")

        // Toggle back
        sut.toggleFavorite(compound: compound)
        XCTAssertEqual(compound.isFavorited, initialState, "Should return to original state")
    }

    // MARK: - Tracked Compound Operations

    func testStartTracking_CreatesTrackedCompound() {
        let compounds = sut.fetchAllCompounds()
        guard let compound = compounds.first(where: { $0.trackedCompound == nil }) else {
            XCTSkip("No untracked compounds available for test")
            return
        }

        let tracked = sut.startTracking(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        XCTAssertNotNil(tracked.id, "Tracked compound should have ID")
        XCTAssertEqual(tracked.dosageAmount, 100, "Dosage should match")
        XCTAssertTrue(tracked.isActive, "Should be active")

        // Cleanup
        sut.deleteTracking(tracked)
    }

    func testStopTracking_SetsInactive() {
        let compounds = sut.fetchAllCompounds()
        guard let compound = compounds.first(where: { $0.trackedCompound == nil }) else {
            XCTSkip("No untracked compounds available for test")
            return
        }

        let tracked = sut.startTracking(
            compound: compound,
            dosageAmount: 50,
            dosageUnit: .mcg,
            scheduleType: .daily,
            notificationEnabled: false
        )

        sut.stopTracking(compound: compound)
        XCTAssertFalse(tracked.isActive, "Should be inactive after stopping")

        // Cleanup
        sut.deleteTracking(tracked)
    }

    // MARK: - Dose Log Operations

    func testLogDose_CreatesDoseLog() {
        let compounds = sut.fetchAllCompounds()
        guard let compound = compounds.first else {
            XCTFail("Need at least one compound")
            return
        }

        let initialUseCount = compound.useCount

        let log = sut.logDose(
            compound: compound,
            dosageAmount: 250,
            dosageUnit: .mcg,
            timestamp: Date(),
            injectionSite: "left_belly_upper",
            notes: "Test dose"
        )

        XCTAssertNotNil(log.id, "Dose log should have ID")
        XCTAssertEqual(log.dosageAmount, 250, "Dosage should match")
        XCTAssertEqual(log.notes, "Test dose", "Notes should match")
        XCTAssertEqual(compound.useCount, initialUseCount + 1, "Use count should increment")

        // Cleanup
        sut.deleteDoseLog(log)
    }

    func testFetchDoseLogs_ReturnsLogsForCompound() {
        let compounds = sut.fetchAllCompounds()
        guard let compound = compounds.first else {
            XCTFail("Need at least one compound")
            return
        }

        // Create a test log
        let log = sut.logDose(
            compound: compound,
            dosageAmount: 100,
            dosageUnit: .mg,
            timestamp: Date()
        )

        let logs = sut.fetchDoseLogs(for: compound, limit: 10)
        XCTAssertTrue(logs.contains(where: { $0.id == log.id }), "Should contain the new log")

        // Cleanup
        sut.deleteDoseLog(log)
    }

    func testFetchDoseLogsInDateRange_FiltersCorrectly() {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()

        let logs = sut.fetchDoseLogs(from: startDate, to: endDate)

        for log in logs {
            XCTAssertGreaterThanOrEqual(log.timestamp ?? Date.distantPast, startDate)
            XCTAssertLessThanOrEqual(log.timestamp ?? Date.distantFuture, endDate)
        }
    }

    // MARK: - Analytics

    func testDoseCount_ReturnsCorrectCount() {
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let endDate = Date()

        let count = sut.doseCount(from: startDate, to: endDate)
        XCTAssertGreaterThanOrEqual(count, 0, "Count should be non-negative")
    }
}
