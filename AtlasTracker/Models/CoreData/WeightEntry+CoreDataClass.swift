import Foundation
import CoreData

// MARK: - Validation Error

enum WeightEntryValidationError: LocalizedError {
    case invalidWeight(String)

    var errorDescription: String? {
        switch self {
        case .invalidWeight(let message):
            return "Invalid weight: \(message)"
        }
    }
}

@objc(WeightEntry)
public class WeightEntry: NSManagedObject {

    // MARK: - Validation

    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateWeightEntry()
    }

    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateWeightEntry()
    }

    private func validateWeightEntry() throws {
        // Validate weight is positive
        guard weight > 0 else {
            throw WeightEntryValidationError.invalidWeight("Weight must be greater than 0")
        }

        // Validate weight is reasonable (under 1000 lbs/kg)
        guard weight <= 1000 else {
            throw WeightEntryValidationError.invalidWeight("Weight exceeds maximum of 1000")
        }
    }

    // MARK: - Convenience Initializer
    convenience init(context: NSManagedObjectContext,
                     weight: Double,
                     unit: WeightUnit,
                     date: Date = Date(),
                     compound: Compound? = nil,
                     notes: String? = nil) {

        guard let entity = NSEntityDescription.entity(forEntityName: "WeightEntry", in: context) else {
            fatalError("WeightEntry entity not found in Core Data model")
        }
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
