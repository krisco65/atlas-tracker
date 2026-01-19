import Foundation
import CoreData

// MARK: - Validation Error

enum DoseLogValidationError: LocalizedError {
    case invalidDosage(String)
    case missingCompound

    var errorDescription: String? {
        switch self {
        case .invalidDosage(let message):
            return "Invalid dosage: \(message)"
        case .missingCompound:
            return "Dose log must be associated with a compound"
        }
    }
}

@objc(DoseLog)
public class DoseLog: NSManagedObject {

    // MARK: - Validation

    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateDoseLog()
    }

    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateDoseLog()
    }

    private func validateDoseLog() throws {
        // Validate dosage amount is non-negative (0 is allowed for skipped doses)
        guard dosageAmount >= 0 else {
            throw DoseLogValidationError.invalidDosage("Dosage must be 0 or greater")
        }

        // Validate dosage amount is reasonable (under 10,000)
        guard dosageAmount <= 10000 else {
            throw DoseLogValidationError.invalidDosage("Dosage exceeds maximum of 10,000")
        }

        // Validate compound relationship exists
        guard compound != nil else {
            throw DoseLogValidationError.missingCompound
        }
    }

    // MARK: - Convenience Initializer
    convenience init(context: NSManagedObjectContext,
                     compound: Compound,
                     dosageAmount: Double,
                     dosageUnit: DosageUnit,
                     timestamp: Date = Date(),
                     injectionSite: String? = nil,
                     sideEffects: [SideEffect]? = nil,
                     notes: String? = nil) {

        guard let entity = NSEntityDescription.entity(forEntityName: "DoseLog", in: context) else {
            fatalError("DoseLog entity not found in Core Data model")
        }
        self.init(entity: entity, insertInto: context)

        self.id = UUID()
        self.compound = compound
        self.dosageAmount = dosageAmount
        self.dosageUnitRaw = dosageUnit.rawValue
        self.timestamp = timestamp
        self.injectionSiteRaw = injectionSite
        self.sideEffectsRaw = sideEffects?.rawValues as NSArray?
        self.notes = notes
    }

    // MARK: - Computed Properties
    var dosageUnit: DosageUnit {
        get { DosageUnit(rawValue: dosageUnitRaw ?? "mg") ?? .mg }
        set { dosageUnitRaw = newValue.rawValue }
    }

    // MARK: - Dosage String
    var dosageString: String {
        let amount = dosageAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", dosageAmount)
            : String(format: "%.2f", dosageAmount)
        return "\(amount) \(dosageUnit.displayName)"
    }

    // MARK: - Injection Site
    var injectionSite: InjectionSite {
        guard let rawValue = injectionSiteRaw,
              let category = compound?.category else {
            return .none
        }
        return InjectionSite.from(rawValue: rawValue, category: category)
    }

    var injectionSiteDisplayName: String? {
        guard let rawValue = injectionSiteRaw else { return nil }

        // Try PED sites first
        if let pedSite = PEDInjectionSite(rawValue: rawValue) {
            return pedSite.displayName
        }
        // Try peptide sites
        if let peptideSite = PeptideInjectionSite(rawValue: rawValue) {
            return peptideSite.displayName
        }
        return rawValue
    }

    // MARK: - Date/Time Formatting
    var timestampString: String {
        guard let timestamp = timestamp else { return "" }
        return timestamp.formatted(dateStyle: .medium, timeStyle: .short)
    }

    var timeOnlyString: String {
        guard let timestamp = timestamp else { return "" }
        return timestamp.timeString
    }

    var dateOnlyString: String {
        guard let timestamp = timestamp else { return "" }
        return timestamp.shortDateString
    }

    var relativeDateString: String {
        guard let timestamp = timestamp else { return "" }
        return timestamp.relativeDateString
    }

    // MARK: - Side Effects
    var sideEffects: [SideEffect] {
        get {
            guard let rawArray = sideEffectsRaw as? [String] else { return [] }
            return rawArray.compactMap { SideEffect(rawValue: $0) }
        }
        set {
            sideEffectsRaw = newValue.rawValues as NSArray
        }
    }

    var hasSideEffects: Bool {
        let effects = sideEffects
        return !effects.isEmpty && effects != [SideEffect.none]
    }

    var sideEffectsString: String? {
        let effects = sideEffects
        guard !effects.isEmpty else { return nil }
        if effects == [SideEffect.none] { return nil }
        return effects.filter { $0 != SideEffect.none }.map { $0.displayName }.joined(separator: ", ")
    }

    var isSkippedDose: Bool {
        return dosageAmount == 0 && notes?.lowercased().contains("skip") == true
    }
}
