import Foundation
import CoreData

extension TrackedCompound {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackedCompound> {
        return NSFetchRequest<TrackedCompound>(entityName: "TrackedCompound")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var dosageAmount: Double
    @NSManaged public var dosageUnitRaw: String?
    @NSManaged public var scheduleTypeRaw: String?
    @NSManaged public var scheduleInterval: Int16
    @NSManaged public var scheduleDaysRaw: [Int16]?
    @NSManaged public var notificationEnabled: Bool
    @NSManaged public var notificationTime: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var startDate: Date?
    @NSManaged public var lastDoseDate: Date?
    @NSManaged public var reconstitutionBAC: Double
    @NSManaged public var reconstitutionConcentration: Double

    // Relationships
    @NSManaged public var compound: Compound?
}

extension TrackedCompound: Identifiable { }
