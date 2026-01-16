import Foundation
import CoreData

@objc(WeightEntry)
public class WeightEntry: NSManagedObject {

    // MARK: - Convenience Initializer
    convenience init(context: NSManagedObjectContext,
                     weight: Double,
                     unit: WeightUnit,
                     date: Date = Date(),
                     compound: Compound? = nil,
                     notes: String? = nil) {

        let entity = NSEntityDescription.entity(forEntityName: "WeightEntry", in: context)!
        self.init(entity: entity, insertInto: context)

        self.id = UUID()
        self.weight = weight
        self.unitRaw = unit.rawValue
        self.date = date
        self.compound = compound
        self.notes = notes
    }

    // MARK: - Computed Properties
    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw ?? "lbs") ?? .lbs }
        set { unitRaw = newValue.rawValue }
    }

    // MARK: - Weight Conversion
    func weight(in targetUnit: WeightUnit) -> Double {
        return unit.convert(to: targetUnit, value: weight)
    }

    // MARK: - Display Strings
    var weightString: String {
        let formattedWeight = weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
        return "\(formattedWeight) \(unit.shortName)"
    }

    var dateString: String {
        return date?.shortDateString ?? ""
    }

    var fullDateString: String {
        return date?.fullDateString ?? ""
    }
}
