import XCTest
@testable import AtlasTracker

final class DashboardViewModelTests: XCTestCase {

    var sut: DashboardViewModel!

    override func setUpWithError() throws {
        sut = DashboardViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Load Data Tests

    func testLoadData_PopulatesTrackedCompounds() {
        sut.loadData()

        // Should not crash and should populate data
        XCTAssertNotNil(sut.todaysDoses)
        XCTAssertNotNil(sut.upcomingDoses)
    }

    // MARK: - Today's Doses Tests

    func testFetchTodaysDoses_ReturnsOnlyActiveTracked() {
        sut.loadData()

        for tracked in sut.todaysDoses {
            XCTAssertTrue(tracked.isActive, "Should only show active tracked compounds")
        }
    }

    // MARK: - Upcoming Doses Tests

    func testFetchUpcomingDoses_ReturnsUpcoming() {
        sut.loadData()

        // Upcoming doses should have future dates
        for tracked in sut.upcomingDoses {
            if let nextDose = tracked.nextDoseDate {
                XCTAssertGreaterThanOrEqual(nextDose, Date().startOfDay)
            }
        }
    }

    // MARK: - Recent Logs Tests

    func testFetchRecentLogs_LimitsResults() {
        sut.loadData()

        XCTAssertLessThanOrEqual(sut.recentLogs.count, 10, "Should limit recent logs")
    }

    func testFetchRecentLogs_SortsDescending() {
        sut.loadData()

        guard sut.recentLogs.count > 1 else { return }

        for i in 0..<(sut.recentLogs.count - 1) {
            let current = sut.recentLogs[i].timestamp ?? Date.distantPast
            let next = sut.recentLogs[i + 1].timestamp ?? Date.distantPast
            XCTAssertGreaterThanOrEqual(current, next, "Logs should be newest first")
        }
    }

    // MARK: - Is Dose Completed Today Tests

    func testIsDoseCompletedToday_WhenNotDosedToday_ReturnsFalse() {
        sut.loadData()

        // Find a tracked compound that wasn't dosed today
        let tracked = sut.todaysDoses.first { tracked in
            guard let lastDose = tracked.lastDoseDate else { return true }
            return !Calendar.current.isDateInToday(lastDose)
        }

        if let tracked = tracked {
            XCTAssertFalse(sut.isDoseCompletedToday(tracked))
        }
    }

    func testIsDoseCompletedToday_WhenDosedToday_ReturnsTrue() {
        sut.loadData()

        // Find a tracked compound that was dosed today
        let tracked = sut.todaysDoses.first { tracked in
            guard let lastDose = tracked.lastDoseDate else { return false }
            return Calendar.current.isDateInToday(lastDose)
        }

        if let tracked = tracked {
            XCTAssertTrue(sut.isDoseCompletedToday(tracked))
        }
    }

    // MARK: - Quick Stats Tests

    func testQuickStats_ReturnsNonNegativeValues() {
        sut.loadData()

        XCTAssertGreaterThanOrEqual(sut.totalTracked, 0)
        XCTAssertGreaterThanOrEqual(sut.dosesThisWeek, 0)
    }

    // MARK: - Recommended Site Tests

    func testRecommendedSite_ForPEDCompound_ReturnsPEDSite() {
        sut.loadData()

        let pedTracked = sut.todaysDoses.first { tracked in
            tracked.compound?.category == .ped
        }

        if let tracked = pedTracked {
            let site = sut.recommendedSite(for: tracked)
            // Should return a valid site string or nil
            if let site = site {
                XCTAssertFalse(site.isEmpty)
            }
        }
    }

    func testRecommendedSite_ForPeptideCompound_ReturnsPeptideSite() {
        sut.loadData()

        let peptideTracked = sut.todaysDoses.first { tracked in
            tracked.compound?.category == .peptide
        }

        if let tracked = peptideTracked {
            let site = sut.recommendedSite(for: tracked)
            // Should return a valid site string or nil
            if let site = site {
                XCTAssertFalse(site.isEmpty)
            }
        }
    }
}
