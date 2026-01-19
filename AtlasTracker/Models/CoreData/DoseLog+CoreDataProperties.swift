import Foundation
import CoreData

extension DoseLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DoseLog> {
        return NSFetchRequest<DoseLog>(entityName: "DoseLog")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var dosageAmount: Double
    @NSManaged public var dosageUnitRaw: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var injectionSiteRaw: String?
    @NSManaged public var sideEffectsRaw: NSArray?
    @NSManaged public var notes: String?

    // Relationships
    @NSManaged public var compound: Compound?
}

extension DoseLog: Identifiable { }
