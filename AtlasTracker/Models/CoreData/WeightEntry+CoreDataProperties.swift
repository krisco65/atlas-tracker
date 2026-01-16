import Foundation
import CoreData

extension WeightEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WeightEntry> {
        return NSFetchRequest<WeightEntry>(entityName: "WeightEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var weight: Double
    @NSManaged public var unitRaw: String?
    @NSManaged public var date: Date?
    @NSManaged public var notes: String?

    // Optional relationship to track weight for specific compound
    @NSManaged public var compound: Compound?
}

extension WeightEntry: Identifiable { }
