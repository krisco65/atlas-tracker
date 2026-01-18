import XCTest
@testable import AtlasTracker

final class InjectionSiteTests: XCTestCase {

    // MARK: - PED Injection Site Tests

    func testPEDInjectionSite_AllCasesExist() {
        XCTAssertEqual(PEDInjectionSite.allCases.count, 8, "Should have 8 PED sites")
    }

    func testPEDInjectionSite_DisplayName() {
        XCTAssertEqual(PEDInjectionSite.gluteLeft.displayName, "Left Glute")
        XCTAssertEqual(PEDInjectionSite.gluteRight.displayName, "Right Glute")
        XCTAssertEqual(PEDInjectionSite.deltLeft.displayName, "Left Delt")
        XCTAssertEqual(PEDInjectionSite.deltRight.displayName, "Right Delt")
        XCTAssertEqual(PEDInjectionSite.quadLeft.displayName, "Left Quad")
        XCTAssertEqual(PEDInjectionSite.quadRight.displayName, "Right Quad")
        XCTAssertEqual(PEDInjectionSite.vgLeft.displayName, "Left VG")
        XCTAssertEqual(PEDInjectionSite.vgRight.displayName, "Right VG")
    }

    func testPEDInjectionSite_ShortName() {
        XCTAssertEqual(PEDInjectionSite.gluteLeft.shortName, "L Glute")
        XCTAssertEqual(PEDInjectionSite.deltRight.shortName, "R Delt")
    }

    func testPEDInjectionSite_BodyPart() {
        XCTAssertEqual(PEDInjectionSite.gluteLeft.bodyPart, "Glute")
        XCTAssertEqual(PEDInjectionSite.gluteRight.bodyPart, "Glute")
        XCTAssertEqual(PEDInjectionSite.deltLeft.bodyPart, "Delt")
        XCTAssertEqual(PEDInjectionSite.quadLeft.bodyPart, "Quad")
        XCTAssertEqual(PEDInjectionSite.vgLeft.bodyPart, "Ventrogluteal")
    }

    func testPEDInjectionSite_Side() {
        XCTAssertEqual(PEDInjectionSite.gluteLeft.side, "Left")
        XCTAssertEqual(PEDInjectionSite.gluteRight.side, "Right")
        XCTAssertTrue(PEDInjectionSite.gluteLeft.isLeftSide)
        XCTAssertFalse(PEDInjectionSite.gluteRight.isLeftSide)
    }

    func testPEDInjectionSite_OppositeSite() {
        XCTAssertEqual(PEDInjectionSite.gluteLeft.oppositeSite, .gluteRight)
        XCTAssertEqual(PEDInjectionSite.gluteRight.oppositeSite, .gluteLeft)
        XCTAssertEqual(PEDInjectionSite.deltLeft.oppositeSite, .deltRight)
        XCTAssertEqual(PEDInjectionSite.deltRight.oppositeSite, .deltLeft)
        XCTAssertEqual(PEDInjectionSite.quadLeft.oppositeSite, .quadRight)
        XCTAssertEqual(PEDInjectionSite.quadRight.oppositeSite, .quadLeft)
        XCTAssertEqual(PEDInjectionSite.vgLeft.oppositeSite, .vgRight)
        XCTAssertEqual(PEDInjectionSite.vgRight.oppositeSite, .vgLeft)
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
        XCTAssertEqual(PeptideInjectionSite.allCases.count, 16, "Should have 16 peptide sites")
    }

    func testPeptideInjectionSite_DisplayName() {
        XCTAssertEqual(PeptideInjectionSite.leftBellyUpper.displayName, "Left of Navel - Upper")
        XCTAssertEqual(PeptideInjectionSite.rightBellyLower.displayName, "Right of Navel - Lower")
        XCTAssertEqual(PeptideInjectionSite.thighLeft.displayName, "Left Thigh")
        XCTAssertEqual(PeptideInjectionSite.thighRight.displayName, "Right Thigh")
    }

    func testPeptideInjectionSite_BodyPart() {
        XCTAssertEqual(PeptideInjectionSite.leftBellyUpper.bodyPart, "Belly")
        XCTAssertEqual(PeptideInjectionSite.leftLoveHandleUpper.bodyPart, "Love Handles")
        XCTAssertEqual(PeptideInjectionSite.gluteLeftUpper.bodyPart, "Glutes")
        XCTAssertEqual(PeptideInjectionSite.thighLeft.bodyPart, "Thighs")
    }

    func testPeptideInjectionSite_IsLeftSide() {
        XCTAssertTrue(PeptideInjectionSite.leftBellyUpper.isLeftSide)
        XCTAssertTrue(PeptideInjectionSite.leftLoveHandleUpper.isLeftSide)
        XCTAssertTrue(PeptideInjectionSite.gluteLeftUpper.isLeftSide)
        XCTAssertTrue(PeptideInjectionSite.thighLeft.isLeftSide)

        XCTAssertFalse(PeptideInjectionSite.rightBellyUpper.isLeftSide)
        XCTAssertFalse(PeptideInjectionSite.rightLoveHandleUpper.isLeftSide)
        XCTAssertFalse(PeptideInjectionSite.gluteRightUpper.isLeftSide)
        XCTAssertFalse(PeptideInjectionSite.thighRight.isLeftSide)
    }

    func testPeptideInjectionSite_Grouped() {
        let grouped = PeptideInjectionSite.grouped
        XCTAssertEqual(grouped.count, 6, "Should have 6 groups")
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
        let site = InjectionSite.from(rawValue: "glute_left", category: .ped)
        if case .ped(let pedSite) = site {
            XCTAssertEqual(pedSite, .gluteLeft)
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
        let pedSite = InjectionSite.ped(.gluteLeft)
        XCTAssertEqual(pedSite.displayName, "Left Glute")

        let peptideSite = InjectionSite.peptide(.leftBellyUpper)
        XCTAssertEqual(peptideSite.displayName, "Left of Navel - Upper")

        let none = InjectionSite.none
        XCTAssertEqual(none.displayName, "Not Applicable")
    }

    func testInjectionSite_RawValue() {
        let pedSite = InjectionSite.ped(.gluteLeft)
        XCTAssertEqual(pedSite.rawValue, "glute_left")

        let peptideSite = InjectionSite.peptide(.leftBellyUpper)
        XCTAssertEqual(peptideSite.rawValue, "left_belly_upper")

        let none = InjectionSite.none
        XCTAssertEqual(none.rawValue, "none")
    }

    func testInjectionSite_InjectionType() {
        let pedSite = InjectionSite.ped(.gluteLeft)
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
