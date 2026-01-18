import XCTest
@testable import AtlasTracker

final class LibraryViewModelTests: XCTestCase {

    var sut: LibraryViewModel!

    override func setUpWithError() throws {
        sut = LibraryViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Load Compounds Tests

    func testLoadCompounds_PopulatesCompounds() {
        sut.loadCompounds()

        XCTAssertFalse(sut.compounds.isEmpty, "Should load compounds from database")
    }

    func testLoadCompounds_SortsAlphabetically() {
        sut.loadCompounds()

        guard sut.compounds.count > 1 else { return }

        for i in 0..<(sut.compounds.count - 1) {
            let current = sut.compounds[i].name ?? ""
            let next = sut.compounds[i + 1].name ?? ""
            XCTAssertLessThanOrEqual(current.lowercased(), next.lowercased(),
                "Compounds should be sorted alphabetically")
        }
    }

    // MARK: - Filter Tests

    func testApplyFilters_ByCategory_FiltersCorrectly() {
        sut.loadCompounds()
        sut.selectedCategory = .peptide
        sut.applyFilters()

        for compound in sut.filteredCompounds {
            XCTAssertEqual(compound.category, .peptide,
                "All filtered compounds should match selected category")
        }
    }

    func testApplyFilters_AllCategories_ShowsAll() {
        sut.loadCompounds()
        sut.selectedCategory = nil  // All categories
        sut.applyFilters()

        XCTAssertEqual(sut.filteredCompounds.count, sut.compounds.count,
            "Should show all compounds when no category filter")
    }

    func testApplyFilters_FavoritesOnly() {
        sut.loadCompounds()
        sut.showFavoritesOnly = true
        sut.applyFilters()

        for compound in sut.filteredCompounds {
            XCTAssertTrue(compound.isFavorited,
                "All filtered compounds should be favorites")
        }
    }

    // MARK: - Search Tests

    func testSearch_WithQuery_FiltersResults() {
        sut.loadCompounds()
        sut.searchQuery = "BPC"
        sut.applyFilters()

        for compound in sut.filteredCompounds {
            XCTAssertTrue(compound.name?.localizedCaseInsensitiveContains("BPC") ?? false,
                "Search results should match query")
        }
    }

    func testSearch_EmptyQuery_ShowsAll() {
        sut.loadCompounds()
        sut.searchQuery = ""
        sut.applyFilters()

        XCTAssertEqual(sut.filteredCompounds.count, sut.compounds.count)
    }

    func testSearch_CaseInsensitive() {
        sut.loadCompounds()

        sut.searchQuery = "bpc"
        sut.applyFilters()
        let lowercaseCount = sut.filteredCompounds.count

        sut.searchQuery = "BPC"
        sut.applyFilters()
        let uppercaseCount = sut.filteredCompounds.count

        XCTAssertEqual(lowercaseCount, uppercaseCount,
            "Search should be case-insensitive")
    }

    // MARK: - Toggle Favorite Tests

    func testToggleFavorite_ChangesFavoriteStatus() {
        sut.loadCompounds()
        guard let compound = sut.compounds.first else {
            XCTFail("Need at least one compound")
            return
        }

        let initialState = compound.isFavorited
        sut.toggleFavorite(compound)

        XCTAssertEqual(compound.isFavorited, !initialState)

        // Toggle back
        sut.toggleFavorite(compound)
        XCTAssertEqual(compound.isFavorited, initialState)
    }

    // MARK: - Compound Count Tests

    func testCompoundCount_ReturnsCorrectCount() {
        sut.loadCompounds()

        let count = sut.compoundCount(for: .peptide)
        let manualCount = sut.compounds.filter { $0.category == .peptide }.count

        XCTAssertEqual(count, manualCount)
    }

    // MARK: - Is Tracked Tests

    func testIsTracked_WithTrackedCompound_ReturnsTrue() {
        sut.loadCompounds()

        let trackedCompounds = sut.compounds.filter { $0.trackedCompound != nil && $0.trackedCompound?.isActive == true }

        for compound in trackedCompounds {
            XCTAssertTrue(sut.isTracked(compound))
        }
    }

    func testIsTracked_WithUntrackedCompound_ReturnsFalse() {
        sut.loadCompounds()

        let untrackedCompounds = sut.compounds.filter { $0.trackedCompound == nil }

        for compound in untrackedCompounds {
            XCTAssertFalse(sut.isTracked(compound))
        }
    }

    // MARK: - Category Sections Tests

    func testCategorySections_ReturnsAllCategories() {
        let sections = CompoundCategory.allCases

        XCTAssertTrue(sections.contains(.peptide))
        XCTAssertTrue(sections.contains(.ped))
        XCTAssertTrue(sections.contains(.supplement))
        XCTAssertTrue(sections.contains(.medicine))
    }
}
