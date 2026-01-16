import Foundation
import Combine

// MARK: - Sort Option
enum CompoundSortOption: String, CaseIterable {
    case alphabetical = "A-Z"
    case favorites = "Favorites"
    case frequentlyUsed = "Frequently Used"

    var icon: String {
        switch self {
        case .alphabetical: return "textformat.abc"
        case .favorites: return "star.fill"
        case .frequentlyUsed: return "flame.fill"
        }
    }
}

// MARK: - Library View Model
final class LibraryViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var compounds: [Compound] = []
    @Published var filteredCompounds: [Compound] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: CompoundCategory? = nil
    @Published var sortOption: CompoundSortOption = .alphabetical
    @Published var isLoading = false

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let coreDataManager = CoreDataManager.shared

    // MARK: - Initialization
    init() {
        setupBindings()
    }

    // MARK: - Setup Bindings
    private func setupBindings() {
        // React to search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)

        // React to category changes
        $selectedCategory
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)

        // React to sort option changes
        $sortOption
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    // MARK: - Load Data
    func loadCompounds() {
        isLoading = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.compounds = self.coreDataManager.fetchAllCompounds()
            self.applyFilters()
            self.isLoading = false
        }
    }

    // MARK: - Apply Filters
    private func applyFilters() {
        var result = compounds

        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { compound in
                compound.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        // Apply sorting
        switch sortOption {
        case .alphabetical:
            result.sort { ($0.name ?? "") < ($1.name ?? "") }

        case .favorites:
            result.sort { compound1, compound2 in
                if compound1.isFavorited == compound2.isFavorited {
                    return (compound1.name ?? "") < (compound2.name ?? "")
                }
                return compound1.isFavorited && !compound2.isFavorited
            }

        case .frequentlyUsed:
            result.sort { compound1, compound2 in
                if compound1.useCount == compound2.useCount {
                    return (compound1.name ?? "") < (compound2.name ?? "")
                }
                return compound1.useCount > compound2.useCount
            }
        }

        filteredCompounds = result
    }

    // MARK: - Toggle Favorite
    func toggleFavorite(_ compound: Compound) {
        coreDataManager.toggleFavorite(compound: compound)
        loadCompounds()
    }

    // MARK: - Delete Compound
    func deleteCompound(_ compound: Compound) {
        guard compound.isCustom else { return } // Only allow deleting custom compounds
        coreDataManager.deleteCompound(compound)
        loadCompounds()
    }

    // MARK: - Add Custom Compound
    func addCustomCompound(
        name: String,
        category: CompoundCategory,
        supportedUnits: [DosageUnit],
        defaultUnit: DosageUnit,
        requiresInjection: Bool
    ) {
        var recommendedSites: [String] = []

        if requiresInjection {
            switch category {
            case .ped:
                recommendedSites = PEDInjectionSite.allCases.map { $0.rawValue }
            case .peptide:
                recommendedSites = PeptideInjectionSite.allCases.map { $0.rawValue }
            default:
                break
            }
        }

        coreDataManager.createCompound(
            name: name,
            category: category,
            supportedUnits: supportedUnits,
            defaultUnit: defaultUnit,
            requiresInjection: requiresInjection,
            recommendedSites: recommendedSites,
            isCustom: true
        )

        loadCompounds()
    }

    // MARK: - Category Counts
    func compoundCount(for category: CompoundCategory?) -> Int {
        if let category = category {
            return compounds.filter { $0.category == category }.count
        }
        return compounds.count
    }

    // MARK: - Tracked Status
    func isTracked(_ compound: Compound) -> Bool {
        return compound.isTracked
    }
}
