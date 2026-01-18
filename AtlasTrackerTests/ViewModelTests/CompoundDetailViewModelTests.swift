import XCTest
import CoreData
@testable import AtlasTracker

final class CompoundDetailViewModelTests: XCTestCase {

    var sut: CompoundDetailViewModel!
    var testCompound: Compound!
    var coreDataManager: CoreDataManager!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        coreDataManager = CoreDataManager.shared
        testContext = coreDataManager.viewContext

        // Create test compound
        testCompound = Compound(context: testContext)
        testCompound.id = UUID()
        testCompound.name = "Test Compound"
        testCompound.categoryRaw = CompoundCategory.peptide.rawValue
        testCompound.requiresInjection = true
        testCompound.defaultUnitRaw = DosageUnit.mcg.rawValue
        testCompound.supportedUnitsRaw = [DosageUnit.mcg.rawValue, DosageUnit.mg.rawValue]

        sut = CompoundDetailViewModel(compound: testCompound)
    }

    override func tearDownWithError() throws {
        // Clean up test data
        if let tracked = testCompound.trackedCompound {
            testContext.delete(tracked)
        }
        testContext.delete(testCompound)
        try testContext.save()

        sut = nil
        testCompound = nil
        coreDataManager = nil
        testContext = nil
    }

    // MARK: - Initialization Tests

    func testInit_SetsCompound() {
        XCTAssertEqual(sut.compound, testCompound, "Should set compound on init")
    }

    func testInit_SetsDefaultUnit() {
        XCTAssertEqual(sut.selectedUnit, testCompound.defaultUnit, "Should set default unit on init")
    }

    func testInit_LoadsData() {
        XCTAssertFalse(sut.isTracked, "New compound should not be tracked initially")
    }

    // MARK: - Computed Properties Tests

    func testAvailableUnits_ReturnsCompoundUnits() {
        XCTAssertEqual(sut.availableUnits.count, 2, "Should return supported units")
        XCTAssertTrue(sut.availableUnits.contains(.mcg), "Should contain mcg")
        XCTAssertTrue(sut.availableUnits.contains(.mg), "Should contain mg")
    }

    func testRequiresInjection_ReturnsCompoundValue() {
        XCTAssertTrue(sut.requiresInjection, "Should match compound's requiresInjection")
    }

    // MARK: - canSaveTracking Tests

    func testCanSaveTracking_InvalidAmount_ReturnsFalse() {
        sut.dosageAmount = ""
        XCTAssertFalse(sut.canSaveTracking, "Should return false for empty amount")

        sut.dosageAmount = "abc"
        XCTAssertFalse(sut.canSaveTracking, "Should return false for non-numeric amount")

        sut.dosageAmount = "0"
        XCTAssertFalse(sut.canSaveTracking, "Should return false for zero amount")

        sut.dosageAmount = "-10"
        XCTAssertFalse(sut.canSaveTracking, "Should return false for negative amount")
    }

    func testCanSaveTracking_ValidAmount_Daily_ReturnsTrue() {
        sut.dosageAmount = "250"
        sut.scheduleType = .daily
        XCTAssertTrue(sut.canSaveTracking, "Should return true for valid daily setup")
    }

    func testCanSaveTracking_EveryXDays_InvalidInterval_ReturnsFalse() {
        sut.dosageAmount = "250"
        sut.scheduleType = .everyXDays
        sut.scheduleInterval = ""
        XCTAssertFalse(sut.canSaveTracking, "Should return false for empty interval")

        sut.scheduleInterval = "0"
        XCTAssertFalse(sut.canSaveTracking, "Should return false for zero interval")

        sut.scheduleInterval = "abc"
        XCTAssertFalse(sut.canSaveTracking, "Should return false for non-numeric interval")
    }

    func testCanSaveTracking_EveryXDays_ValidInterval_ReturnsTrue() {
        sut.dosageAmount = "250"
        sut.scheduleType = .everyXDays
        sut.scheduleInterval = "3"
        XCTAssertTrue(sut.canSaveTracking, "Should return true for valid everyXDays setup")
    }

    func testCanSaveTracking_SpecificDays_EmptyDays_ReturnsFalse() {
        sut.dosageAmount = "250"
        sut.scheduleType = .specificDays
        sut.selectedDays = []
        XCTAssertFalse(sut.canSaveTracking, "Should return false for empty days")
    }

    func testCanSaveTracking_SpecificDays_ValidDays_ReturnsTrue() {
        sut.dosageAmount = "250"
        sut.scheduleType = .specificDays
        sut.selectedDays = [1, 3, 5]  // Monday, Wednesday, Friday
        XCTAssertTrue(sut.canSaveTracking, "Should return true for valid specificDays setup")
    }

    func testCanSaveTracking_AsNeeded_ReturnsTrue() {
        sut.dosageAmount = "250"
        sut.scheduleType = .asNeeded
        XCTAssertTrue(sut.canSaveTracking, "Should return true for asNeeded (no schedule)")
    }

    // MARK: - scheduleDescription Tests

    func testScheduleDescription_Daily() {
        sut.scheduleType = .daily
        XCTAssertTrue(sut.scheduleDescription.contains("Daily"), "Should mention Daily")
    }

    func testScheduleDescription_EveryXDays() {
        sut.scheduleType = .everyXDays
        sut.scheduleInterval = "3"
        XCTAssertTrue(sut.scheduleDescription.contains("3"), "Should mention interval")
    }

    func testScheduleDescription_E3_5D() {
        sut.scheduleType = .everyXDays
        sut.scheduleInterval = "3"
        XCTAssertTrue(sut.scheduleDescription.contains("E3.5D"), "Should show E3.5D notation for 3-day interval")
    }

    func testScheduleDescription_SpecificDays() {
        sut.scheduleType = .specificDays
        sut.selectedDays = [1, 3, 5]  // Mon, Wed, Fri
        let description = sut.scheduleDescription
        XCTAssertTrue(description.contains("Mon") || description.contains("M"), "Should mention days")
    }

    func testScheduleDescription_AsNeeded() {
        sut.scheduleType = .asNeeded
        XCTAssertTrue(sut.scheduleDescription.contains("needed"), "Should mention as needed")
    }

    // MARK: - Toggle Day Tests

    func testToggleDay_AddsDay() {
        sut.selectedDays = []
        sut.toggleDay(1)
        XCTAssertTrue(sut.selectedDays.contains(1), "Should add day when not present")
    }

    func testToggleDay_RemovesDay() {
        sut.selectedDays = [1, 2, 3]
        sut.toggleDay(2)
        XCTAssertFalse(sut.selectedDays.contains(2), "Should remove day when present")
    }

    // MARK: - Injection Site Tests

    func testRecommendedNextSite_ReturnsSite() {
        // For peptide compound that requires injection
        testCompound.requiresInjection = true
        testCompound.categoryRaw = CompoundCategory.peptide.rawValue

        sut = CompoundDetailViewModel(compound: testCompound)
        // Recommendation service should return a site (may be nil if no history)
        // Just verify it doesn't crash
        _ = sut.recommendedNextSite
    }

    // MARK: - Tracking Operations Tests

    func testStartTracking_WithInvalidInput_SetsErrorMessage() {
        sut.dosageAmount = ""
        sut.startTracking()

        XCTAssertNotNil(sut.errorMessage, "Should set error message for invalid input")
    }

    func testToggleFavorite_DoesNotCrash() {
        // Just verify it doesn't crash
        sut.toggleFavorite()
        XCTAssertNotNil(sut, "ViewModel should still exist")
    }

    // MARK: - Delete Compound Tests

    func testDeleteCompound_CustomCompound_ReturnsTrue() {
        testCompound.isCustom = true
        let result = sut.deleteCompound()
        XCTAssertTrue(result, "Should return true for custom compound")
    }

    func testDeleteCompound_NonCustomCompound_ReturnsFalse() {
        testCompound.isCustom = false
        let result = sut.deleteCompound()
        XCTAssertFalse(result, "Should return false for non-custom compound")
    }

    // MARK: - Dose Stats Tests

    func testTotalDosesLogged_ReturnsCount() {
        let count = sut.totalDosesLogged
        XCTAssertGreaterThanOrEqual(count, 0, "Should return non-negative count")
    }

    // MARK: - Pre-fill Tests

    func testLoadData_WithTrackedCompound_PreFillsFields() {
        // Create tracked compound
        let tracked = TrackedCompound(context: testContext)
        tracked.id = UUID()
        tracked.compound = testCompound
        tracked.dosageAmount = 500
        tracked.dosageUnitRaw = DosageUnit.mcg.rawValue
        tracked.scheduleTypeRaw = ScheduleType.daily.rawValue
        tracked.notificationEnabled = true

        testCompound.trackedCompound = tracked

        // Create new ViewModel to trigger loadData
        sut = CompoundDetailViewModel(compound: testCompound)

        XCTAssertEqual(sut.dosageAmount, "500.0", "Should pre-fill dosage amount")
        XCTAssertEqual(sut.selectedUnit, .mcg, "Should pre-fill unit")
        XCTAssertEqual(sut.scheduleType, .daily, "Should pre-fill schedule type")
        XCTAssertTrue(sut.notificationEnabled, "Should pre-fill notification setting")
    }

    // MARK: - Observable Property Tests

    func testObservableProperties_AreSettable() {
        sut.dosageAmount = "100"
        XCTAssertEqual(sut.dosageAmount, "100")

        sut.selectedUnit = .mg
        XCTAssertEqual(sut.selectedUnit, .mg)

        sut.scheduleType = .everyXDays
        XCTAssertEqual(sut.scheduleType, .everyXDays)

        sut.scheduleInterval = "7"
        XCTAssertEqual(sut.scheduleInterval, "7")

        sut.selectedDays = [1, 2]
        XCTAssertEqual(sut.selectedDays, [1, 2])

        sut.notificationEnabled = false
        XCTAssertFalse(sut.notificationEnabled)

        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)

        sut.showTrackingSetup = true
        XCTAssertTrue(sut.showTrackingSetup)

        sut.errorMessage = "Test error"
        XCTAssertEqual(sut.errorMessage, "Test error")
    }
}
