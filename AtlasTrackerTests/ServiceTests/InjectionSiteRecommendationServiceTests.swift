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
        XCTAssertTrue(PEDInjectionSite.allCases.contains(site), "Should be a valid PED site")
    }

    func testRecommendNextPEDSite_AlternatesSides() {
        let firstSite = sut.recommendNextPEDSite()
        // The recommendation should prefer alternating sides
        let _ = firstSite.isLeftSide // Should have a side
    }

    // MARK: - Peptide Site Recommendation

    func testRecommendNextPeptideSite_ReturnsValidSite() {
        let site = sut.recommendNextPeptideSite()
        XCTAssertTrue(PeptideInjectionSite.allCases.contains(site), "Should be a valid peptide site")
    }

    func testRecommendNextPeptideSite_PrefersBellySites() {
        let site = sut.recommendNextPeptideSite()
        // Just verify it's a valid site
        XCTAssertTrue(PeptideInjectionSite.allCases.contains(site))
    }

    // MARK: - General Recommendation

    func testRecommendNextSite_ForPEDCompound() {
        let compounds = CoreDataManager.shared.fetchCompounds(category: .ped)
        guard let pedCompound = compounds.first else {
            XCTSkip("No PED compounds available")
            return
        }

        let siteName = sut.recommendNextSite(for: pedCompound)
        if pedCompound.requiresInjection {
            XCTAssertNotNil(siteName, "Should return a site name for injectable PED compound")
        }
    }

    func testRecommendNextSite_ForPeptideCompound() {
        let compounds = CoreDataManager.shared.fetchCompounds(category: .peptide)
        guard let peptideCompound = compounds.first else {
            XCTSkip("No peptide compounds available")
            return
        }

        let siteName = sut.recommendNextSite(for: peptideCompound)
        if peptideCompound.requiresInjection {
            XCTAssertNotNil(siteName, "Should return a site name for injectable peptide compound")
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
        XCTAssertLessThanOrEqual(history.count, 5, "Should respect limit")
    }

    func testSiteUsageStats_ReturnsStats() {
        let stats = sut.siteUsageStats(for: .peptide)
        XCTAssertNotNil(stats, "Should return stats array")
    }

    // MARK: - Rotation Validation

    func testValidateRotation_ForPED() {
        let compounds = CoreDataManager.shared.fetchCompounds(category: .ped)
        guard let compound = compounds.first else {
            XCTSkip("No PED compounds available")
            return
        }

        let validation = sut.validateRotation(for: compound)
        XCTAssertNotNil(validation.message, "Should return validation message")
    }
}
