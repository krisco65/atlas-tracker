import Foundation
import CoreData

@objc(Compound)
public class Compound: NSManagedObject {

    // MARK: - Convenience Initializer
    convenience init(context: NSManagedObjectContext,
                     name: String,
                     category: CompoundCategory,
                     supportedUnits: [DosageUnit],
                     defaultUnit: DosageUnit,
                     requiresInjection: Bool = false,
                     recommendedSites: [String] = [],
                     isCustom: Bool = false) {

        guard let entity = NSEntityDescription.entity(forEntityName: "Compound", in: context) else {
            fatalError("Compound entity not found in Core Data model")
        }
        self.init(entity: entity, insertInto: context)

        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.supportedUnitsRaw = supportedUnits.map { $0.rawValue }
        self.defaultUnitRaw = defaultUnit.rawValue
        self.requiresInjection = requiresInjection
        self.recommendedSitesRaw = recommendedSites
        self.isFavorited = false
        self.useCount = 0
        self.isCustom = isCustom
        self.createdAt = Date()
    }

    // MARK: - Computed Properties
    var category: CompoundCategory {
        get { CompoundCategory(rawValue: categoryRaw ?? "supplement") ?? .supplement }
        set { categoryRaw = newValue.rawValue }
    }

    var supportedUnits: [DosageUnit] {
        get {
            (supportedUnitsRaw ?? []).compactMap { DosageUnit(rawValue: $0) }
        }
        set {
            supportedUnitsRaw = newValue.map { $0.rawValue }
        }
    }

    var defaultUnit: DosageUnit {
        get { DosageUnit(rawValue: defaultUnitRaw ?? "mg") ?? .mg }
        set { defaultUnitRaw = newValue.rawValue }
    }

    var recommendedSites: [String] {
        get { recommendedSitesRaw ?? [] }
        set { recommendedSitesRaw = newValue }
    }

    // MARK: - Tracking Status
    var isTracked: Bool {
        return trackedCompound != nil && (trackedCompound?.isActive ?? false)
    }

    // MARK: - Dose Logs Array
    var doseLogsArray: [DoseLog] {
        let set = doseLogs as? Set<DoseLog> ?? []
        return set.sorted { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) }
    }

    // MARK: - Inventory (1:1 relationship)
    // For backwards compatibility, returns array with single item or empty
    var inventoryArray: [Inventory] {
        guard let inv = inventory else { return [] }
        return [inv]
    }

    var hasInventory: Bool {
        inventory != nil
    }

    // MARK: - Last Dose Date
    var lastDoseDate: Date? {
        return doseLogsArray.first?.timestamp
    }

    // MARK: - Total Doses Logged
    var totalDosesLogged: Int {
        return doseLogsArray.count
    }

    // MARK: - Increment Use Count
    func incrementUseCount() {
        useCount += 1
    }
}
