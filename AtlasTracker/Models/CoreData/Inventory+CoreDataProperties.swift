import Foundation
import CoreData

extension Inventory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Inventory> {
        return NSFetchRequest<Inventory>(entityName: "Inventory")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var vialCount: Int16
    @NSManaged public var vialSizeMg: Double
    @NSManaged public var remainingInCurrentVial: Double
    @NSManaged public var lowStockThreshold: Int16
    @NSManaged public var autoDecrement: Bool
    @NSManaged public var lastUpdated: Date?

    // Relationships
    @NSManaged public var compound: Compound?
}

extension Inventory: Identifiable { }
