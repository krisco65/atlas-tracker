import XCTest
@testable import AtlasTracker

final class ConstantsTests: XCTestCase {

    // MARK: - Weight Unit Tests

    func testWeightUnit_AllCases() {
        let cases = WeightUnit.allCases
        XCTAssertTrue(cases.contains(.kg))
        XCTAssertTrue(cases.contains(.lbs))
    }

    func testWeightUnit_DisplayName() {
        XCTAssertEqual(WeightUnit.kg.displayName, "kg")
        XCTAssertEqual(WeightUnit.lbs.displayName, "lbs")
    }

    func testWeightUnit_ConvertKgToLbs() {
        let kg: Double = 100
        let lbs = WeightUnit.kg.convert(kg, to: .lbs)

        // 1 kg = 2.20462 lbs
        XCTAssertEqual(lbs, 220.462, accuracy: 0.01)
    }

    func testWeightUnit_ConvertLbsToKg() {
        let lbs: Double = 220.462
        let kg = WeightUnit.lbs.convert(lbs, to: .kg)

        // 220.462 lbs = 100 kg
        XCTAssertEqual(kg, 100, accuracy: 0.1)
    }

    func testWeightUnit_ConvertSameUnit() {
        let value: Double = 75.5

        XCTAssertEqual(WeightUnit.kg.convert(value, to: .kg), value)
        XCTAssertEqual(WeightUnit.lbs.convert(value, to: .lbs), value)
    }

    // MARK: - Dosage Unit Tests

    func testDosageUnit_AllCases() {
        let cases = DosageUnit.allCases
        XCTAssertTrue(cases.contains(.mg))
        XCTAssertTrue(cases.contains(.mcg))
        XCTAssertTrue(cases.contains(.ml))
        XCTAssertTrue(cases.contains(.iu))
        XCTAssertTrue(cases.contains(.g))
    }

    func testDosageUnit_DisplayName() {
        XCTAssertEqual(DosageUnit.mg.displayName, "mg")
        XCTAssertEqual(DosageUnit.mcg.displayName, "mcg")
        XCTAssertEqual(DosageUnit.ml.displayName, "ml")
        XCTAssertEqual(DosageUnit.iu.displayName, "IU")
        XCTAssertEqual(DosageUnit.g.displayName, "g")
    }

    func testDosageUnit_RawValue() {
        XCTAssertEqual(DosageUnit.mg.rawValue, "mg")
        XCTAssertEqual(DosageUnit.mcg.rawValue, "mcg")
    }

    // MARK: - Schedule Type Tests

    func testScheduleType_AllCases() {
        let cases = ScheduleType.allCases
        XCTAssertTrue(cases.contains(.daily))
        XCTAssertTrue(cases.contains(.everyXDays))
        XCTAssertTrue(cases.contains(.specificDays))
        XCTAssertTrue(cases.contains(.asNeeded))
    }

    func testScheduleType_DisplayName() {
        XCTAssertFalse(ScheduleType.daily.displayName.isEmpty)
        XCTAssertFalse(ScheduleType.everyXDays.displayName.isEmpty)
        XCTAssertFalse(ScheduleType.specificDays.displayName.isEmpty)
        XCTAssertFalse(ScheduleType.asNeeded.displayName.isEmpty)
    }

    // MARK: - Compound Category Tests

    func testCompoundCategory_AllCases() {
        let cases = CompoundCategory.allCases
        XCTAssertEqual(cases.count, 4)
        XCTAssertTrue(cases.contains(.peptide))
        XCTAssertTrue(cases.contains(.ped))
        XCTAssertTrue(cases.contains(.supplement))
        XCTAssertTrue(cases.contains(.medicine))
    }

    func testCompoundCategory_DisplayName() {
        XCTAssertEqual(CompoundCategory.peptide.displayName, "Peptides")
        XCTAssertEqual(CompoundCategory.ped.displayName, "PEDs")
        XCTAssertEqual(CompoundCategory.supplement.displayName, "Supplements")
        XCTAssertEqual(CompoundCategory.medicine.displayName, "Medicines")
    }

    func testCompoundCategory_Icon() {
        // All categories should have non-empty icons
        for category in CompoundCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) should have an icon")
        }
    }

    func testCompoundCategory_Color() {
        // All categories should have a color defined
        for category in CompoundCategory.allCases {
            // Just access the color - if it crashes, test fails
            _ = category.color
        }
    }

    // MARK: - App Constants Tests

    func testAppConstants_CoreDataModelName() {
        XCTAssertEqual(AppConstants.coreDataModelName, "AtlasTracker")
    }

    func testAppConstants_DefaultNotificationTime() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: AppConstants.defaultNotificationTime)
        XCTAssertEqual(components.hour, 9, "Default notification should be at 9 AM")
        XCTAssertEqual(components.minute, 0)
    }

    func testAppConstants_Inventory_DefaultLowStockThreshold() {
        XCTAssertGreaterThan(AppConstants.Inventory.defaultLowStockThreshold, 0)
    }
}
