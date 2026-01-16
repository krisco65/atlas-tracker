import Foundation
import CoreData

// MARK: - Seed Data Models for JSON Decoding
struct SeedDataFile: Codable {
    let version: Int
    let compounds: [SeedCompound]
}

struct SeedCompound: Codable {
    let name: String
    let category: String
    let supportedUnits: [String]
    let defaultUnit: String
    let requiresInjection: Bool
    let recommendedSites: [String]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        supportedUnits = try container.decode([String].self, forKey: .supportedUnits)
        defaultUnit = try container.decode(String.self, forKey: .defaultUnit)
        requiresInjection = try container.decodeIfPresent(Bool.self, forKey: .requiresInjection) ?? false
        recommendedSites = try container.decodeIfPresent([String].self, forKey: .recommendedSites)
    }
}

// MARK: - Seed Data Service
final class SeedDataService {

    // MARK: - Singleton
    static let shared = SeedDataService()

    private init() {}

    // MARK: - Seed Database
    func seedDatabaseIfNeeded(context: NSManagedObjectContext) {
        let lastVersion = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.lastSeedDataVersion)

        if lastVersion == 0 {
            // First time - do full seed
            seedDatabase(context: context)
            UserDefaults.standard.set(AppConstants.seedDataVersion, forKey: AppConstants.UserDefaultsKeys.lastSeedDataVersion)
        } else if lastVersion < AppConstants.seedDataVersion {
            // Version update - add missing compounds without deleting
            addMissingCompounds(context: context)
            UserDefaults.standard.set(AppConstants.seedDataVersion, forKey: AppConstants.UserDefaultsKeys.lastSeedDataVersion)
        }
    }

    func seedDatabase(context: NSManagedObjectContext) {
        // First, check if we already have compounds
        let request: NSFetchRequest<Compound> = Compound.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == NO")

        do {
            let existingCount = try context.count(for: request)
            if existingCount > 0 {
                print("Database already seeded with \(existingCount) compounds")
                return
            }
        } catch {
            print("Error checking existing compounds: \(error)")
        }

        // Load seed data from JSON
        guard let seedData = loadSeedData() else {
            print("Failed to load seed data, using fallback")
            seedWithFallbackData(context: context)
            return
        }

        // Create compounds from seed data
        for seedCompound in seedData.compounds {
            createCompound(from: seedCompound, context: context)
        }

        // Save context
        do {
            try context.save()
            print("Successfully seeded database with \(seedData.compounds.count) compounds")
        } catch {
            print("Error saving seeded data: \(error)")
        }
    }

    // MARK: - Load JSON Data
    private func loadSeedData() -> SeedDataFile? {
        // Try to load from bundle
        guard let url = Bundle.main.url(forResource: "SeedData", withExtension: "json") else {
            print("SeedData.json not found in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(SeedDataFile.self, from: data)
        } catch {
            print("Error decoding seed data: \(error)")
            return nil
        }
    }

    // MARK: - Create Compound from Seed
    private func createCompound(from seed: SeedCompound, context: NSManagedObjectContext) {
        guard let category = CompoundCategory(rawValue: seed.category) else {
            print("Invalid category: \(seed.category)")
            return
        }

        let supportedUnits = seed.supportedUnits.compactMap { DosageUnit(rawValue: $0) }
        guard let defaultUnit = DosageUnit(rawValue: seed.defaultUnit) else {
            print("Invalid default unit: \(seed.defaultUnit)")
            return
        }

        let _ = Compound(
            context: context,
            name: seed.name,
            category: category,
            supportedUnits: supportedUnits,
            defaultUnit: defaultUnit,
            requiresInjection: seed.requiresInjection,
            recommendedSites: seed.recommendedSites ?? [],
            isCustom: false
        )
    }

    // MARK: - Fallback Data (in case JSON fails to load)
    private func seedWithFallbackData(context: NSManagedObjectContext) {
        // Supplements
        let supplements: [(String, [DosageUnit], DosageUnit)] = [
            ("Vitamin C", [.mg, .g], .mg),
            ("Vitamin D3", [.iu, .mcg], .iu),
            ("Vitamin B12", [.mcg, .mg], .mcg),
            ("Omega-3 Fish Oil", [.mg, .g, .capsules], .mg),
            ("Magnesium Glycinate", [.mg, .capsules], .mg),
            ("Zinc", [.mg, .capsules], .mg),
            ("Creatine Monohydrate", [.g, .mg], .g),
            ("Ashwagandha", [.mg, .capsules], .mg),
            ("L-Theanine", [.mg, .capsules], .mg),
            ("Melatonin", [.mg, .mcg], .mg)
        ]

        for (name, units, defaultUnit) in supplements {
            let _ = Compound(
                context: context,
                name: name,
                category: .supplement,
                supportedUnits: units,
                defaultUnit: defaultUnit,
                requiresInjection: false,
                isCustom: false
            )
        }

        // PEDs (Injectable)
        let injectablePEDs = [
            "Testosterone Cypionate",
            "Testosterone Enanthate",
            "Nandrolone Decanoate (Deca)",
            "Trenbolone Acetate",
            "Masteron (Drostanolone)"
        ]

        let pedSites = PEDInjectionSite.allCases.map { $0.rawValue }

        for name in injectablePEDs {
            let _ = Compound(
                context: context,
                name: name,
                category: .ped,
                supportedUnits: [.mg, .ml],
                defaultUnit: .mg,
                requiresInjection: true,
                recommendedSites: pedSites,
                isCustom: false
            )
        }

        // PEDs (Oral)
        let oralPEDs = ["Anavar (Oxandrolone)", "Dianabol (Methandrostenolone)", "Winstrol (Stanozolol)"]

        for name in oralPEDs {
            let _ = Compound(
                context: context,
                name: name,
                category: .ped,
                supportedUnits: [.mg, .tablets],
                defaultUnit: .mg,
                requiresInjection: false,
                isCustom: false
            )
        }

        // Peptides
        let peptides = [
            "HGH (Somatropin)",
            "Tirzepatide",
            "Semaglutide",
            "BPC-157",
            "TB-500",
            "Ipamorelin"
        ]

        let peptideSites = PeptideInjectionSite.allCases.map { $0.rawValue }

        for name in peptides {
            let defaultUnit: DosageUnit = name.contains("HGH") ? .iu : .mg
            let _ = Compound(
                context: context,
                name: name,
                category: .peptide,
                supportedUnits: [.mg, .mcg, .iu, .ml],
                defaultUnit: defaultUnit,
                requiresInjection: true,
                recommendedSites: peptideSites,
                isCustom: false
            )
        }

        // Medicines
        let medicines = [
            "Anastrozole (Arimidex)",
            "Tamoxifen (Nolvadex)",
            "Metformin",
            "Trazodone",
            "Finasteride"
        ]

        for name in medicines {
            let _ = Compound(
                context: context,
                name: name,
                category: .medicine,
                supportedUnits: [.mg, .tablets],
                defaultUnit: .mg,
                requiresInjection: false,
                isCustom: false
            )
        }

        // Save
        do {
            try context.save()
            print("Successfully seeded database with fallback data")
        } catch {
            print("Error saving fallback seed data: \(error)")
        }
    }

    // MARK: - Force Re-seed (for testing/updates)
    func forceSeed(context: NSManagedObjectContext) {
        addMissingCompounds(context: context)
    }

    // MARK: - Force Re-seed from Scratch (delete all default compounds and re-import)
    func forceReseedFromScratch(context: NSManagedObjectContext) {
        // Delete all non-custom compounds
        let request: NSFetchRequest<Compound> = Compound.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == NO")

        do {
            let defaultCompounds = try context.fetch(request)
            print("Deleting \(defaultCompounds.count) default compounds...")

            for compound in defaultCompounds {
                context.delete(compound)
            }

            try context.save()
            print("Deleted all default compounds")
        } catch {
            print("Error deleting default compounds: \(error)")
        }

        // Reset the seed data version to force fresh import
        UserDefaults.standard.set(0, forKey: AppConstants.UserDefaultsKeys.lastSeedDataVersion)

        // Re-seed the database
        seedDatabase(context: context)

        // Update version
        UserDefaults.standard.set(AppConstants.seedDataVersion, forKey: AppConstants.UserDefaultsKeys.lastSeedDataVersion)

        print("Force reseed complete - database refreshed with latest compounds")
    }

    // MARK: - Add Missing Compounds (non-destructive update)
    func addMissingCompounds(context: NSManagedObjectContext) {
        guard let seedData = loadSeedData() else {
            print("Failed to load seed data")
            return
        }

        // Get existing compound names
        let request: NSFetchRequest<Compound> = Compound.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == NO")

        var existingNames = Set<String>()
        do {
            let existing = try context.fetch(request)
            existingNames = Set(existing.compactMap { $0.name })
        } catch {
            print("Error fetching existing compounds: \(error)")
        }

        // Add missing compounds
        var addedCount = 0
        for seedCompound in seedData.compounds {
            if !existingNames.contains(seedCompound.name) {
                createCompound(from: seedCompound, context: context)
                addedCount += 1
                print("Added missing compound: \(seedCompound.name)")
            }
        }

        // Save context
        if addedCount > 0 {
            do {
                try context.save()
                print("Successfully added \(addedCount) missing compounds")
            } catch {
                print("Error saving new compounds: \(error)")
            }
        } else {
            print("No missing compounds to add")
        }
    }
}
