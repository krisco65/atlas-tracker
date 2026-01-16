import Foundation
import CoreData

@objc(DoseLog)
public class DoseLog: NSManagedObject {

    // MARK: - Convenience Initializer
    convenience init(context: NSManagedObjectContext,
                     compound: Compound,
                     dosageAmount: Double,
                     dosageUnit: DosageUnit,
                     timestamp: Date = Date(),
                     injectionSite: String? = nil,
                     notes: String? = nil) {

        let entity = NSEntityDescription.entity(forEntityName: "DoseLog", in: context)!
        self.init(entity: entity, insertInto: context)

        self.id = UUID()
        self.compound = compound
        self.dosageAmount = dosageAmount
        self.dosageUnitRaw = dosageUnit.rawValue
        self.timestamp = timestamp
        self.injectionSiteRaw = injectionSite
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
}
