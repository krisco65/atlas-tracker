import XCTest
@testable import AtlasTracker

final class ReconstitutionViewModelTests: XCTestCase {

    var sut: ReconstitutionViewModel!

    override func setUpWithError() throws {
        sut = ReconstitutionViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Basic Calculation Tests

    func testCalculate_WithValidInputs_ProducesResult() {
        sut.vialSizeMg = "5"
        sut.bacWaterMl = "2"
        sut.desiredDoseMg = "250"
        sut.doseUnitIsMcg = true  // 250 mcg

        sut.calculate()

        XCTAssertNotNil(sut.result, "Should produce a result")
        XCTAssertNil(sut.errorMessage, "Should not have error")
    }

    func testCalculate_WithInvalidVialSize_ProducesError() {
        sut.vialSizeMg = ""
        sut.bacWaterMl = "2"
        sut.desiredDoseMg = "250"

        sut.calculate()

        XCTAssertNil(sut.result, "Should not produce result")
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
    }

    func testCalculate_WithZeroBacWater_ProducesError() {
        sut.vialSizeMg = "5"
        sut.bacWaterMl = "0"
        sut.desiredDoseMg = "250"

        sut.calculate()

        XCTAssertNil(sut.result, "Should not produce result with zero BAC water")
    }

    func testCalculate_ConcentrationCalculation() {
        // 5mg vial with 2ml BAC water = 2.5mg/ml concentration
        sut.vialSizeMg = "5"
        sut.bacWaterMl = "2"
        sut.desiredDoseMg = "0.5"
        sut.doseUnitIsMcg = false  // mg

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            // 5mg / 2ml = 2.5 mg/ml concentration
            XCTAssertEqual(result.concentrationMgPerMl, 2.5, accuracy: 0.01)
        }
    }

    func testCalculate_VolumeToDrawCalculation() {
        // 5mg vial with 2ml BAC water = 2.5mg/ml
        // Desired dose: 0.5mg = 0.2ml to draw
        sut.vialSizeMg = "5"
        sut.bacWaterMl = "2"
        sut.desiredDoseMg = "0.5"
        sut.doseUnitIsMcg = false

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            // 0.5mg / 2.5mg/ml = 0.2ml
            XCTAssertEqual(result.volumeToDrawMl, 0.2, accuracy: 0.001)
        }
    }

    func testCalculate_SyringeUnitsCalculation() {
        // 0.2ml = 20 insulin units
        sut.vialSizeMg = "5"
        sut.bacWaterMl = "2"
        sut.desiredDoseMg = "0.5"
        sut.doseUnitIsMcg = false

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            // 0.2ml * 100 = 20 units
            XCTAssertEqual(result.syringeUnits, 20, accuracy: 0.1)
        }
    }

    func testCalculate_DosesPerVial() {
        // 5mg vial, 0.5mg per dose = 10 doses
        sut.vialSizeMg = "5"
        sut.bacWaterMl = "2"
        sut.desiredDoseMg = "0.5"
        sut.doseUnitIsMcg = false

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            XCTAssertEqual(result.dosesPerVial, 10, accuracy: 0.1)
        }
    }

    // MARK: - Mcg Conversion Tests

    func testCalculate_WithMcgUnit() {
        // 5mg = 5000mcg vial, 250mcg dose
        sut.vialSizeMg = "5"
        sut.bacWaterMl = "2"
        sut.desiredDoseMg = "250"
        sut.doseUnitIsMcg = true

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            // 250mcg = 0.25mg, concentration = 2.5mg/ml
            // Volume = 0.25 / 2.5 = 0.1ml = 10 units
            XCTAssertEqual(result.syringeUnits, 10, accuracy: 0.5)
        }
    }

    // MARK: - Preset Tests

    func testApplyPreset_SetsValues() {
        let presets = sut.commonPresets
        XCTAssertFalse(presets.isEmpty, "Should have presets")

        if let firstPreset = presets.first {
            sut.applyPreset(firstPreset)

            XCTAssertFalse(sut.vialSizeMg.isEmpty, "Should set vial size")
            XCTAssertFalse(sut.desiredDoseMg.isEmpty, "Should set desired dose")
        }
    }

    // MARK: - BAC Water Suggestion Tests

    func testSuggestBacWater_ReturnsValue() {
        sut.vialSizeMg = "5"

        let suggestion = sut.suggestBacWater()

        // Should suggest a reasonable BAC water amount
        XCTAssertNotNil(suggestion)
    }

    func testSuggestBacWater_NoVialSize_ReturnsNil() {
        sut.vialSizeMg = ""

        let suggestion = sut.suggestBacWater()

        XCTAssertNil(suggestion)
    }

    // MARK: - Auto Calculate Tests

    func testAutoCalculate_SetsValues() {
        sut.vialSizeMg = "5"

        sut.autoCalculate()

        XCTAssertFalse(sut.bacWaterMl.isEmpty, "Should set BAC water")
        XCTAssertNotNil(sut.result, "Should calculate result")
    }

    // MARK: - Reset Tests

    func testReset_ClearsAllValues() {
        sut.vialSizeMg = "5"
        sut.bacWaterMl = "2"
        sut.desiredDoseMg = "250"
        sut.calculate()

        sut.reset()

        XCTAssertTrue(sut.vialSizeMg.isEmpty)
        XCTAssertTrue(sut.bacWaterMl.isEmpty)
        XCTAssertTrue(sut.desiredDoseMg.isEmpty)
        XCTAssertNil(sut.result)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Can Calculate Tests

    func testCanCalculate_WithAllInputs_ReturnsTrue() {
        sut.vialSizeMg = "5"
        sut.bacWaterMl = "2"
        sut.desiredDoseMg = "250"

        XCTAssertTrue(sut.canCalculate)
    }

    func testCanCalculate_WithMissingInputs_ReturnsFalse() {
        sut.vialSizeMg = "5"
        sut.bacWaterMl = ""
        sut.desiredDoseMg = "250"

        XCTAssertFalse(sut.canCalculate)
    }

    // MARK: - Dose Unit Label Tests

    func testDoseUnitLabel_WhenMcg() {
        sut.doseUnitIsMcg = true
        XCTAssertEqual(sut.doseUnitLabel, "mcg")
    }

    func testDoseUnitLabel_WhenMg() {
        sut.doseUnitIsMcg = false
        XCTAssertEqual(sut.doseUnitLabel, "mg")
    }

    // MARK: - Result Warning Tests

    func testResult_VerySmallVolume_HasWarning() {
        // Very small dose that results in tiny volume
        sut.vialSizeMg = "10"
        sut.bacWaterMl = "1"  // High concentration
        sut.desiredDoseMg = "10"
        sut.doseUnitIsMcg = true  // 10 mcg = 0.01mg

        sut.calculate()

        if let result = sut.result {
            // 0.01mg / 10mg/ml = 0.001ml = very small
            XCTAssertTrue(result.isVolumeVerySmall, "Should flag very small volume")
        }
    }

    func testResult_LargeVolume_HasWarning() {
        // Large dose that results in big volume
        sut.vialSizeMg = "5"
        sut.bacWaterMl = "2"
        sut.desiredDoseMg = "4"
        sut.doseUnitIsMcg = false  // 4mg

        sut.calculate()

        if let result = sut.result {
            // 4mg / 2.5mg/ml = 1.6ml = large for SubQ
            XCTAssertTrue(result.isVolumeLarge, "Should flag large volume")
        }
    }
}
