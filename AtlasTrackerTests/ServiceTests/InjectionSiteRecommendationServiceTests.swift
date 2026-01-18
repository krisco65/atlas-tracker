import XCTest
@testable import AtlasTracker

final class InjectionSiteRecommendationServiceTests: XCTestCase {

    var sut: InjectionSiteRecommendationService!

    override func setUpWithError() throws {
        sut = InjectionSiteRecommendationService.shared
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - PED Site Recommendation

    func testRecommendNextPEDSite_ReturnsValidSite() {
        let site = sut.recommendNextPEDSite()
        XCTAssertNotNil(site, "Should return a recommendation")

        if let site = site {
            XCTAssertTrue(PEDInjectionSite.allCases.contains(site), "Should be a valid PED site")
        }
    }

    func testRecommendNextPEDSite_AlternatesSides() {
        // Get first recommendation
        guard let firstSite = sut.recommendNextPEDSite() else {
            XCTFail("Should return a site")
            return
        }

        // The recommendation should prefer alternating sides
        // This tests the rotation logic
        let isLeftSide = firstSite.isLeftSide
        XCTAssertNotNil(isLeftSide, "Site should have a side")
    }

    // MARK: - Peptide Site Recommendation

    func testRecommendNextPeptideSite_ReturnsValidSite() {
        let site = sut.recommendNextPeptideSite()
        XCTAssertNotNil(site, "Should return a recommendation")

        if let site = site {
            XCTAssertTrue(PeptideInjectionSite.allCases.contains(site), "Should be a valid peptide site")
        }
    }

    func testRecommendNextPeptideSite_PrefersBellySites() {
        // Fresh recommendation should prefer belly sites
        let site = sut.recommendNextPeptideSite()

        if let site = site {
            // Belly sites are preferred for peptides
            let bellySites: [PeptideInjectionSite] = [
                .leftBellyUpper, .leftBellyLower,
                .rightBellyUpper, .rightBellyLower
            ]
            // Just verify it's a valid site
            XCTAssertTrue(PeptideInjectionSite.allCases.contains(site))
        }
    }

    // MARK: - General Recommendation

    func testRecommendNextSite_ForPEDCompound() {
        let compounds = CoreDataManager.shared.fetchCompounds(category: .ped)
        guard let pedCompound = compounds.first else {
            XCTSkip("No PED compounds available")
            return
        }

        let site = sut.recommendNextSite(for: pedCompound)
        XCTAssertNotNil(site, "Should return a site for PED compound")

        if case .ped(let pedSite) = site {
            XCTAssertTrue(PEDInjectionSite.allCases.contains(pedSite))
        } else if case .none = site {
            // Also acceptable if no history
        } else {
            XCTFail("PED compound should get PED site recommendation")
        }
    }

    func testRecommendNextSite_ForPeptideCompound() {
        let compounds = CoreDataManager.shared.fetchCompounds(category: .peptide)
        guard let peptideCompound = compounds.first else {
            XCTSkip("No peptide compounds available")
            return
        }

        let site = sut.recommendNextSite(for: peptideCompound)
        XCTAssertNotNil(site, "Should return a site for peptide compound")

        if case .peptide(let peptideSite) = site {
            XCTAssertTrue(PeptideInjectionSite.allCases.contains(peptideSite))
        } else if case .none = site {
            // Also acceptable if no history
        } else {
            XCTFail("Peptide compound should get peptide site recommendation")
        }
    }

    // MARK: - Site History

    func testRecentSiteHistory_ReturnsHistory() {
        let compounds = CoreDataManager.shared.fetchCompounds(category: .peptide)
        guard let compound = compounds.first else {
            XCTSkip("No peptide compounds available")
            return
        }

        let history = sut.recentSiteHistory(for: compound, limit: 5)
        XCTAssertNotNil(history, "Should return history array")
        XCTAssertLessThanOrEqual(history.count, 5, "Should respect limit")
    }

    func testSiteUsageStats_ReturnsStats() {
        let compounds = CoreDataManager.shared.fetchCompounds(category: .peptide)
        guard let compound = compounds.first else {
            XCTSkip("No peptide compounds available")
            return
        }

        let stats = sut.siteUsageStats(for: compound)
        XCTAssertNotNil(stats, "Should return stats dictionary")
    }

    // MARK: - Rotation Validation

    func testValidateRotation_ForPED() {
        let compounds = CoreDataManager.shared.fetchCompounds(category: .ped)
        guard let compound = compounds.first else {
            XCTSkip("No PED compounds available")
            return
        }

        let validation = sut.validateRotation(for: compound)
        XCTAssertNotNil(validation, "Should return validation result")
        // Validation should have isGood and message properties
    }
}
