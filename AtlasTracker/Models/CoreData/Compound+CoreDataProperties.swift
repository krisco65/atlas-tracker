import Foundation
import CoreData

extension Compound {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Compound> {
        return NSFetchRequest<Compound>(entityName: "Compound")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var categoryRaw: String?
    @NSManaged public var supportedUnitsRaw: [String]?
    @NSManaged public var defaultUnitRaw: String?
    @NSManaged public var requiresInjection: Bool
    @NSManaged public var recommendedSitesRaw: [String]?
    @NSManaged public var notes: String?
    @NSManaged public var isFavorited: Bool
    @NSManaged public var useCount: Int64
    @NSManaged public var isCustom: Bool
    @NSManaged public var createdAt: Date?

    // Relationships
    @NSManaged public var trackedCompound: TrackedCompound?
    @NSManaged public var doseLogs: NSSet?
    @NSManaged public var inventory: Inventory?  // 1:1 relationship (one inventory per compound)
}

// MARK: - Generated accessors for doseLogs
extension Compound {

    @objc(addDoseLogsObject:)
    @NSManaged public func addToDoseLogs(_ value: DoseLog)

    @objc(removeDoseLogsObject:)
    @NSManaged public func removeFromDoseLogs(_ value: DoseLog)

    @objc(addDoseLogs:)
    @NSManaged public func addToDoseLogs(_ values: NSSet)

    @objc(removeDoseLogs:)
    @NSManaged public func removeFromDoseLogs(_ values: NSSet)
}

// MARK: - Inventory (1:1 relationship)
// No accessors needed - use compound.inventory directly

extension Compound: Identifiable { }
