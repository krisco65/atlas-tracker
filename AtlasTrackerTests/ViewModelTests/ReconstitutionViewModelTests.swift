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

    // MARK: - Basic Calculation Tests (solves for BAC water)

    func testCalculate_WithValidInputs_ProducesResult() {
        sut.vialSize = "10"
        sut.desiredDose = "2"
        sut.syringeUnits = "20"
        sut.doseUnitIsMcg = false

        sut.calculate()

        XCTAssertNotNil(sut.result, "Should produce a result")
        XCTAssertNil(sut.errorMessage, "Should not have error")
    }

    func testCalculate_SolvesForBacWater() {
        // 10mg vial, 2mg dose, 20 units on syringe
        // bacWater = (20 * 10) / (2 * 100) = 1.0 ml
        sut.vialSize = "10"
        sut.desiredDose = "2"
        sut.syringeUnits = "20"
        sut.doseUnitIsMcg = false

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            XCTAssertEqual(result.bacWaterMl, 1.0, accuracy: 0.01)
        }
    }

    func testCalculate_WithInvalidVialSize_ProducesError() {
        sut.vialSize = ""
        sut.desiredDose = "2"
        sut.syringeUnits = "20"

        sut.calculate()

        XCTAssertNil(sut.result, "Should not produce result")
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
    }

    func testCalculate_DoseExceedsVial_ProducesError() {
        sut.vialSize = "5"
        sut.desiredDose = "10"
        sut.syringeUnits = "20"
        sut.doseUnitIsMcg = false

        sut.calculate()

        XCTAssertNil(sut.result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testCalculate_ConcentrationCalculation() {
        // 10mg vial, 2mg dose, 20 units
        // bacWater = 1.0ml, concentration = 10mg / 1ml = 10mg/ml
        sut.vialSize = "10"
        sut.desiredDose = "2"
        sut.syringeUnits = "20"
        sut.doseUnitIsMcg = false

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            XCTAssertEqual(result.concentration, 10.0, accuracy: 0.01)
        }
    }

    func testCalculate_VolumeToDrawCalculation() {
        // 10mg vial, 2mg dose, 20 units
        // bacWater = 1.0ml, volume = 2mg / 10mg/ml = 0.2ml
        sut.vialSize = "10"
        sut.desiredDose = "2"
        sut.syringeUnits = "20"
        sut.doseUnitIsMcg = false

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            XCTAssertEqual(result.volumeToDrawMl, 0.2, accuracy: 0.001)
        }
    }

    func testCalculate_DosesPerVial() {
        // 10mg vial, 2mg per dose = 5 doses
        sut.vialSize = "10"
        sut.desiredDose = "2"
        sut.syringeUnits = "20"
        sut.doseUnitIsMcg = false

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            XCTAssertEqual(result.dosesPerVial, 5, accuracy: 0.1)
        }
    }

    // MARK: - IU Tests

    func testCalculate_WithIUVialUnit() {
        // 5000 IU vial, 500 IU dose, 20 units
        // bacWater = (20 * 5000) / (500 * 100) = 2.0 ml
        sut.vialSize = "5000"
        sut.vialSizeUnit = .iu
        sut.desiredDose = "500"
        sut.syringeUnits = "20"

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            XCTAssertEqual(result.bacWaterMl, 2.0, accuracy: 0.01)
        }
    }

    // MARK: - Mcg Conversion Tests

    func testCalculate_WithMcgUnit() {
        // 5mg vial, 250mcg (0.25mg) dose, 20 units
        // bacWater = (20 * 5) / (0.25 * 100) = 4.0 ml
        sut.vialSize = "5"
        sut.vialSizeUnit = .mg
        sut.desiredDose = "250"
        sut.doseUnitIsMcg = true
        sut.syringeUnits = "20"

        sut.calculate()

        XCTAssertNotNil(sut.result)
        if let result = sut.result {
            XCTAssertEqual(result.bacWaterMl, 4.0, accuracy: 0.01)
        }
    }

    // MARK: - Preset Tests

    func testApplyPreset_SetsValues() {
        let presets = sut.commonPresets
        XCTAssertFalse(presets.isEmpty, "Should have presets")

        if let firstPreset = presets.first {
            sut.applyPreset(firstPreset)

            XCTAssertFalse(sut.vialSize.isEmpty, "Should set vial size")
            XCTAssertFalse(sut.desiredDose.isEmpty, "Should set desired dose")
            XCTAssertFalse(sut.syringeUnits.isEmpty, "Should set syringe units")
            XCTAssertNotNil(sut.result, "Should auto-calculate")
        }
    }

    // MARK: - Reset Tests

    func testReset_ClearsAllValues() {
        sut.vialSize = "5"
        sut.desiredDose = "2"
        sut.syringeUnits = "20"
        sut.calculate()

        sut.reset()

        XCTAssertTrue(sut.vialSize.isEmpty)
        XCTAssertTrue(sut.desiredDose.isEmpty)
        XCTAssertEqual(sut.syringeUnits, "20") // Default value
        XCTAssertNil(sut.result)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Can Calculate Tests

    func testCanCalculate_WithAllInputs_ReturnsTrue() {
        sut.vialSize = "5"
        sut.desiredDose = "2"
        sut.syringeUnits = "20"

        XCTAssertTrue(sut.canCalculate)
    }

    func testCanCalculate_WithMissingInputs_ReturnsFalse() {
        sut.vialSize = "5"
        sut.desiredDose = ""
        sut.syringeUnits = "20"

        XCTAssertFalse(sut.canCalculate)
    }

    // MARK: - Dose Unit Label Tests

    func testDoseUnitLabel_WhenMcg() {
        sut.vialSizeUnit = .mg
        sut.doseUnitIsMcg = true
        XCTAssertEqual(sut.doseUnitLabel, "mcg")
    }

    func testDoseUnitLabel_WhenMg() {
        sut.vialSizeUnit = .mg
        sut.doseUnitIsMcg = false
        XCTAssertEqual(sut.doseUnitLabel, "mg")
    }

    func testDoseUnitLabel_WhenIU() {
        sut.vialSizeUnit = .iu
        XCTAssertEqual(sut.doseUnitLabel, "IU")
    }

    // MARK: - Warning Tests

    func testResult_SmallBacWater_HasWarning() {
        // Should produce very small BAC water
        sut.vialSize = "5"
        sut.desiredDose = "5"
        sut.syringeUnits = "5"
        sut.doseUnitIsMcg = false

        sut.calculate()

        if let result = sut.result {
            // bacWater = (5 * 5) / (5 * 100) = 0.05ml
            XCTAssertTrue(result.isBacWaterVerySmall, "Should flag very small BAC water")
        }
    }

    func testResult_LargeBacWater_HasWarning() {
        // Should produce large BAC water
        sut.vialSize = "10"
        sut.desiredDose = "100"
        sut.doseUnitIsMcg = true  // 0.1mg
        sut.syringeUnits = "50"

        sut.calculate()

        if let result = sut.result {
            // bacWater = (50 * 10) / (0.1 * 100) = 50ml
            XCTAssertTrue(result.isBacWaterLarge, "Should flag large BAC water")
        }
    }
}
