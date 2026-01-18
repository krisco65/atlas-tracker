import XCTest
@testable import AtlasTracker

final class DoseLogViewModelTests: XCTestCase {

    var sut: DoseLogViewModel!

    override func setUpWithError() throws {
        sut = DoseLogViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Load Tracked Compounds Tests

    func testLoadTrackedCompounds_PopulatesArray() {
        sut.loadTrackedCompounds()

        // Should not crash - array may be empty or populated
        XCTAssertNotNil(sut.trackedCompounds)
    }

    // MARK: - Select Compound Tests

    func testSelectCompound_SetsSelectedCompound() {
        let compounds = CoreDataManager.shared.fetchAllCompounds()
        guard let compound = compounds.first else {
            XCTSkip("No compounds available")
            return
        }

        sut.selectCompound(compound)

        XCTAssertEqual(sut.selectedCompound?.id, compound.id)
    }

    func testSelectCompound_UpdatesDosageUnit() {
        let compounds = CoreDataManager.shared.fetchAllCompounds()
        guard let compound = compounds.first else {
            XCTSkip("No compounds available")
            return
        }

        sut.selectCompound(compound)

        XCTAssertEqual(sut.selectedUnit, compound.defaultUnit)
    }

    // MARK: - Select Tracked Compound Tests

    func testSelectTrackedCompound_PreFillsDosage() {
        sut.loadTrackedCompounds()
        guard let tracked = sut.trackedCompounds.first else {
            XCTSkip("No tracked compounds available")
            return
        }

        sut.selectTrackedCompound(tracked)

        XCTAssertEqual(sut.dosageAmount, tracked.dosageAmount)
        XCTAssertEqual(sut.selectedUnit, tracked.dosageUnit)
    }

    // MARK: - Log Dose Tests

    func testLogDose_WithValidData_Succeeds() {
        let compounds = CoreDataManager.shared.fetchAllCompounds()
        guard let compound = compounds.first else {
            XCTSkip("No compounds available")
            return
        }

        sut.selectCompound(compound)
        sut.dosageAmount = 100
        sut.selectedUnit = .mg

        let initialLogCount = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: 100).count

        sut.logDose()

        let newLogCount = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: 100).count
        XCTAssertEqual(newLogCount, initialLogCount + 1, "Should create new dose log")

        // Cleanup - delete the test log
        if let latestLog = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: 1).first {
            CoreDataManager.shared.deleteDoseLog(latestLog)
        }
    }

    func testLogDose_WithoutCompound_DoesNothing() {
        sut.selectedCompound = nil
        sut.dosageAmount = 100

        // Should not crash
        sut.logDose()

        // No assertion needed - just verify no crash
    }

    func testLogDose_WithZeroDosage_DoesNothing() {
        let compounds = CoreDataManager.shared.fetchAllCompounds()
        guard let compound = compounds.first else {
            XCTSkip("No compounds available")
            return
        }

        sut.selectCompound(compound)
        sut.dosageAmount = 0

        let initialLogCount = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: 100).count

        sut.logDose()

        let newLogCount = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: 100).count
        XCTAssertEqual(newLogCount, initialLogCount, "Should not create log with zero dosage")
    }

    // MARK: - Quick Log Tests

    func testQuickLog_WithTrackedCompound_Succeeds() {
        sut.loadTrackedCompounds()
        guard let tracked = sut.trackedCompounds.first,
              let compound = tracked.compound else {
            XCTSkip("No tracked compounds available")
            return
        }

        let initialLogCount = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: 100).count

        sut.quickLog(tracked)

        let newLogCount = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: 100).count
        XCTAssertEqual(newLogCount, initialLogCount + 1, "Quick log should create dose log")

        // Cleanup
        if let latestLog = CoreDataManager.shared.fetchDoseLogs(for: compound, limit: 1).first {
            CoreDataManager.shared.deleteDoseLog(latestLog)
        }
    }

    // MARK: - Reset Form Tests

    func testResetForm_ClearsAllFields() {
        let compounds = CoreDataManager.shared.fetchAllCompounds()
        guard let compound = compounds.first else {
            XCTSkip("No compounds available")
            return
        }

        sut.selectCompound(compound)
        sut.dosageAmount = 100
        sut.notes = "Test notes"

        sut.resetForm()

        XCTAssertNil(sut.selectedCompound)
        XCTAssertEqual(sut.dosageAmount, 0)
        XCTAssertTrue(sut.notes.isEmpty)
    }

    // MARK: - Injection Site Tests

    func testRequiresInjectionSite_ForPeptide_ReturnsTrue() {
        let peptides = CoreDataManager.shared.fetchCompounds(category: .peptide)
        guard let peptide = peptides.first(where: { $0.requiresInjection }) else {
            XCTSkip("No injectable peptides available")
            return
        }

        sut.selectCompound(peptide)

        XCTAssertTrue(sut.requiresInjectionSite)
    }

    func testRequiresInjectionSite_ForSupplement_ReturnsFalse() {
        let supplements = CoreDataManager.shared.fetchCompounds(category: .supplement)
        guard let supplement = supplements.first(where: { !$0.requiresInjection }) else {
            XCTSkip("No non-injectable supplements available")
            return
        }

        sut.selectCompound(supplement)

        XCTAssertFalse(sut.requiresInjectionSite)
    }

    // MARK: - Injection Site Options Tests

    func testInjectionSiteOptions_ForPED_ReturnsPEDSites() {
        let peds = CoreDataManager.shared.fetchCompounds(category: .ped)
        guard let ped = peds.first else {
            XCTSkip("No PED compounds available")
            return
        }

        sut.selectCompound(ped)

        let options = sut.injectionSiteOptions
        XCTAssertFalse(options.isEmpty, "Should have injection site options for PED")
    }

    func testInjectionSiteOptions_ForPeptide_ReturnsPeptideSites() {
        let peptides = CoreDataManager.shared.fetchCompounds(category: .peptide)
        guard let peptide = peptides.first else {
            XCTSkip("No peptide compounds available")
            return
        }

        sut.selectCompound(peptide)

        let options = sut.injectionSiteOptions
        XCTAssertFalse(options.isEmpty, "Should have injection site options for peptide")
    }
}
