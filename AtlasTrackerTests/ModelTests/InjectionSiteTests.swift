import XCTest
@testable import AtlasTracker

final class InjectionSiteTests: XCTestCase {

    // MARK: - PED Injection Site Tests

    func testPEDInjectionSite_AllCasesExist() {
        XCTAssertEqual(PEDInjectionSite.allCases.count, 12, "Should have 12 PED sites")
    }

    func testPEDInjectionSite_DisplayName() {
        XCTAssertEqual(PEDInjectionSite.gluteLeftUpper.displayName, "Left Glute - Upper")
        XCTAssertEqual(PEDInjectionSite.gluteRightLower.displayName, "Right Glute - Lower")
        XCTAssertEqual(PEDInjectionSite.deltLeft.displayName, "Left Delt")
        XCTAssertEqual(PEDInjectionSite.deltRight.displayName, "Right Delt")
        XCTAssertEqual(PEDInjectionSite.quadLeft.displayName, "Left Quad")
        XCTAssertEqual(PEDInjectionSite.quadRight.displayName, "Right Quad")
        XCTAssertEqual(PEDInjectionSite.vgLeftUpper.displayName, "Left VG - Upper")
        XCTAssertEqual(PEDInjectionSite.vgRightLower.displayName, "Right VG - Lower")
    }

    func testPEDInjectionSite_ShortName() {
        XCTAssertEqual(PEDInjectionSite.gluteLeftUpper.shortName, "L Glute U")
        XCTAssertEqual(PEDInjectionSite.deltRight.shortName, "R Delt")
    }

    func testPEDInjectionSite_BodyPart() {
        XCTAssertEqual(PEDInjectionSite.gluteLeftUpper.bodyPart, "Glute")
        XCTAssertEqual(PEDInjectionSite.gluteRightLower.bodyPart, "Glute")
        XCTAssertEqual(PEDInjectionSite.deltLeft.bodyPart, "Delt")
        XCTAssertEqual(PEDInjectionSite.quadLeft.bodyPart, "Quad")
        XCTAssertEqual(PEDInjectionSite.vgLeftUpper.bodyPart, "Ventrogluteal")
    }

    func testPEDInjectionSite_Side() {
        XCTAssertEqual(PEDInjectionSite.gluteLeftUpper.side, "Left")
        XCTAssertEqual(PEDInjectionSite.gluteRightUpper.side, "Right")
        XCTAssertTrue(PEDInjectionSite.gluteLeftUpper.isLeftSide)
        XCTAssertFalse(PEDInjectionSite.gluteRightUpper.isLeftSide)
    }

    func testPEDInjectionSite_Grouped() {
        let grouped = PEDInjectionSite.grouped
        XCTAssertEqual(grouped.count, 4, "Should have 4 body part groups")

        let groupNames = grouped.map { $0.name }
        XCTAssertTrue(groupNames.contains("Glutes"))
        XCTAssertTrue(groupNames.contains("Delts"))
        XCTAssertTrue(groupNames.contains("Quads"))
        XCTAssertTrue(groupNames.contains("Ventrogluteal"))
    }

    func testPEDInjectionSite_BodyMapPosition() {
        for site in PEDInjectionSite.allCases {
            let position = site.bodyMapPosition
            XCTAssertGreaterThanOrEqual(position.x, 0, "X should be >= 0")
            XCTAssertLessThanOrEqual(position.x, 1, "X should be <= 1")
            XCTAssertGreaterThanOrEqual(position.y, 0, "Y should be >= 0")
            XCTAssertLessThanOrEqual(position.y, 1, "Y should be <= 1")
        }
    }

    // MARK: - Peptide Injection Site Tests

    func testPeptideInjectionSite_AllCasesExist() {
        XCTAssertEqual(PeptideInjectionSite.allCases.count, 18, "Should have 18 peptide sites")
    }

    func testPeptideInjectionSite_DisplayName() {
        XCTAssertEqual(PeptideInjectionSite.leftBellyUpper.displayName, "Belly - Upper Left")
        XCTAssertEqual(PeptideInjectionSite.rightBellyLower.displayName, "Belly - Lower Right")
        XCTAssertEqual(PeptideInjectionSite.thighLeftUpper.displayName, "Left Thigh - Upper")
        XCTAssertEqual(PeptideInjectionSite.thighRightMiddle.displayName, "Right Thigh - Middle")
    }

    func testPeptideInjectionSite_BodyPart() {
        XCTAssertEqual(PeptideInjectionSite.leftBellyUpper.bodyPart, "Belly")
        XCTAssertEqual(PeptideInjectionSite.gluteLeftUpper.bodyPart, "Glutes")
        XCTAssertEqual(PeptideInjectionSite.thighLeftUpper.bodyPart, "Thighs")
        XCTAssertEqual(PeptideInjectionSite.deltLeft.bodyPart, "Deltoids")
    }

    func testPeptideInjectionSite_IsLeftSide() {
        XCTAssertTrue(PeptideInjectionSite.leftBellyUpper.isLeftSide)
        XCTAssertTrue(PeptideInjectionSite.gluteLeftUpper.isLeftSide)
        XCTAssertTrue(PeptideInjectionSite.thighLeftUpper.isLeftSide)
        XCTAssertTrue(PeptideInjectionSite.deltLeft.isLeftSide)

        XCTAssertFalse(PeptideInjectionSite.rightBellyUpper.isLeftSide)
        XCTAssertFalse(PeptideInjectionSite.gluteRightUpper.isLeftSide)
        XCTAssertFalse(PeptideInjectionSite.thighRightUpper.isLeftSide)
        XCTAssertFalse(PeptideInjectionSite.deltRight.isLeftSide)
    }

    func testPeptideInjectionSite_Grouped() {
        let grouped = PeptideInjectionSite.grouped
        XCTAssertEqual(grouped.count, 5, "Should have 5 groups")
    }

    func testPeptideInjectionSite_BodyMapPosition() {
        for site in PeptideInjectionSite.allCases {
            let position = site.bodyMapPosition
            XCTAssertGreaterThanOrEqual(position.x, 0, "X should be >= 0")
            XCTAssertLessThanOrEqual(position.x, 1, "X should be <= 1")
            XCTAssertGreaterThanOrEqual(position.y, 0, "Y should be >= 0")
            XCTAssertLessThanOrEqual(position.y, 1, "Y should be <= 1")
        }
    }

    // MARK: - Unified Injection Site Tests

    func testInjectionSite_FromRawValue_PED() {
        let site = InjectionSite.from(rawValue: "glute_left_upper", category: .ped)
        if case .ped(let pedSite) = site {
            XCTAssertEqual(pedSite, .gluteLeftUpper)
        } else {
            XCTFail("Should parse as PED site")
        }
    }

    func testInjectionSite_FromRawValue_Peptide() {
        let site = InjectionSite.from(rawValue: "left_belly_upper", category: .peptide)
        if case .peptide(let peptideSite) = site {
            XCTAssertEqual(peptideSite, .leftBellyUpper)
        } else {
            XCTFail("Should parse as peptide site")
        }
    }

    func testInjectionSite_FromRawValue_Invalid() {
        let site = InjectionSite.from(rawValue: "invalid_site", category: .peptide)
        if case .none = site {
            // Expected
        } else {
            XCTFail("Invalid raw value should return .none")
        }
    }

    func testInjectionSite_DisplayName() {
        let pedSite = InjectionSite.ped(.gluteLeftUpper)
        XCTAssertEqual(pedSite.displayName, "Left Glute - Upper")

        let peptideSite = InjectionSite.peptide(.leftBellyUpper)
        XCTAssertEqual(peptideSite.displayName, "Belly - Upper Left")

        let none = InjectionSite.none
        XCTAssertEqual(none.displayName, "Not Applicable")
    }

    func testInjectionSite_RawValue() {
        let pedSite = InjectionSite.ped(.gluteLeftUpper)
        XCTAssertEqual(pedSite.rawValue, "glute_left_upper")

        let peptideSite = InjectionSite.peptide(.leftBellyUpper)
        XCTAssertEqual(peptideSite.rawValue, "left_belly_upper")

        let none = InjectionSite.none
        XCTAssertEqual(none.rawValue, "none")
    }

    func testInjectionSite_InjectionType() {
        let pedSite = InjectionSite.ped(.gluteLeftUpper)
        XCTAssertEqual(pedSite.injectionType, .intramuscular)

        let peptideSite = InjectionSite.peptide(.leftBellyUpper)
        XCTAssertEqual(peptideSite.injectionType, .subcutaneous)

        let none = InjectionSite.none
        XCTAssertNil(none.injectionType)
    }

    // MARK: - Injection Type Tests

    func testInjectionType_RawValues() {
        XCTAssertEqual(InjectionType.intramuscular.rawValue, "im")
        XCTAssertEqual(InjectionType.subcutaneous.rawValue, "subq")
    }
}
