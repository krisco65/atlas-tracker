import Foundation
import Observation

// MARK: - Dose Log View Model
@Observable
final class DoseLogViewModel {

    // MARK: - Observable Properties
    var selectedCompound: Compound?
    var dosageAmount: String = ""
    var selectedUnit: DosageUnit = .mg
    var selectedInjectionSite: String?
    var timestamp: Date = Date()
    var notes: String = ""
    var isLoading = false
    var showSuccess = false
    var errorMessage: String?

    // MARK: - Tracked Compounds List
    var trackedCompounds: [TrackedCompound] = []

    // MARK: - Computed Properties
    var availableUnits: [DosageUnit] {
        return selectedCompound?.supportedUnits ?? DosageUnit.allCases
    }

    var requiresInjectionSite: Bool {
        return selectedCompound?.requiresInjection ?? false
    }

    var recommendedSite: String? {
        guard let compound = selectedCompound else { return nil }
        return InjectionSiteRecommendationService.shared.recommendNextSite(for: compound)
    }

    var recommendedSiteRawValue: String? {
        guard let compound = selectedCompound else { return nil }
        return InjectionSiteRecommendationService.shared.recommendNextSiteRawValue(for: compound)
    }

    var lastUsedSite: String? {
        guard let compound = selectedCompound else { return nil }
        return InjectionSiteRecommendationService.shared.lastUsedSiteDisplayName(for: compound)
    }

    var lastUsedSiteRawValue: String? {
        guard let compound = selectedCompound else { return nil }
        return InjectionSiteRecommendationService.shared.lastUsedSiteRawValue(for: compound)
    }

    var selectedSiteDisplayName: String {
        guard let site = selectedInjectionSite, let compound = selectedCompound else {
            return "None selected"
        }

        if compound.category == .ped {
            return PEDInjectionSite(rawValue: site)?.displayName ?? site
        } else {
            return PeptideInjectionSite(rawValue: site)?.displayName ?? site
        }
    }

    // MARK: - Validation Constants
    static let maxDosageAmount: Double = 10000
    static let minDosageAmount: Double = 0.001

    var dosageValidationError: String? {
        guard let amount = Double(dosageAmount) else {
            return dosageAmount.isEmpty ? nil : "Enter a valid number"
        }
        if amount <= 0 {
            return "Dosage must be greater than 0"
        }
        if amount > Self.maxDosageAmount {
            return "Dosage exceeds maximum (\(Int(Self.maxDosageAmount)))"
        }
        return nil
    }

    var canLogDose: Bool {
        guard selectedCompound != nil else { return false }
        guard let amount = Double(dosageAmount),
              amount > Self.minDosageAmount,
              amount <= Self.maxDosageAmount else { return false }
        if requiresInjectionSite && selectedInjectionSite == nil { return false }
        return true
    }

    var injectionSiteOptions: [(name: String, sites: [(rawValue: String, displayName: String)])] {
        guard let compound = selectedCompound else { return [] }

        switch compound.category {
        case .ped:
            return PEDInjectionSite.grouped.map { group in
                (name: group.name, sites: group.sites.map { ($0.rawValue, $0.displayName) })
            }
        case .peptide:
            return PeptideInjectionSite.grouped.map { group in
                (name: group.name, sites: group.sites.map { ($0.rawValue, $0.displayName) })
            }
        default:
            return []
        }
    }

    // MARK: - Private Properties
    private let coreDataManager = CoreDataManager.shared

    // MARK: - Initialization
    init() {
        loadTrackedCompounds()
    }

    init(preselectedCompound: Compound) {
        loadTrackedCompounds()
        selectCompound(preselectedCompound)
    }

    // MARK: - Load Tracked Compounds
    func loadTrackedCompounds() {
        trackedCompounds = coreDataManager.fetchTrackedCompounds(activeOnly: true)
    }

    // MARK: - Select Compound
    func selectCompound(_ compound: Compound) {
        selectedCompound = compound
        configureForCompound(compound)
    }

    func selectTrackedCompound(_ tracked: TrackedCompound) {
        guard let compound = tracked.compound else { return }
        selectedCompound = compound

        // Pre-fill from tracked settings
        dosageAmount = String(tracked.dosageAmount)
        selectedUnit = tracked.dosageUnit

        // Set recommended injection site
        if compound.requiresInjection {
            selectedInjectionSite = recommendedSiteRawValue
        } else {
            selectedInjectionSite = nil
        }
    }

    // MARK: - Configure for Compound
    private func configureForCompound(_ compound: Compound) {
        // Set default unit
        selectedUnit = compound.defaultUnit

        // Pre-fill dosage if tracking exists
        if let tracked = compound.trackedCompound {
            dosageAmount = String(tracked.dosageAmount)
            selectedUnit = tracked.dosageUnit
        }

        // Set recommended injection site
        if compound.requiresInjection {
            selectedInjectionSite = recommendedSiteRawValue
        } else {
            selectedInjectionSite = nil
        }
    }

    // MARK: - Reset Form
    func resetForm() {
        selectedCompound = nil
        dosageAmount = ""
        selectedUnit = .mg
        selectedInjectionSite = nil
        timestamp = Date()
        notes = ""
        errorMessage = nil
        showSuccess = false
    }

    // MARK: - Log Dose
    func logDose() {
        guard canLogDose else {
            errorMessage = "Please fill in all required fields"
            return
        }

        guard let compound = selectedCompound,
              let amount = Double(dosageAmount) else {
            errorMessage = "Invalid dosage amount"
            return
        }

        isLoading = true
        errorMessage = nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let _ = self.coreDataManager.logDose(
                compound: compound,
                dosageAmount: amount,
                dosageUnit: self.selectedUnit,
                timestamp: self.timestamp,
                injectionSite: self.selectedInjectionSite,
                notes: self.notes.isEmpty ? nil : self.notes
            )

            // Schedule next notification
            if let tracked = compound.trackedCompound, tracked.notificationEnabled {
                NotificationService.shared.scheduleDoseReminder(for: tracked)
            }

            self.isLoading = false
            self.showSuccess = true

            // Reset after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.resetForm()
            }
        }
    }

    // MARK: - Quick Log (for notifications)
    func quickLog(for compound: Compound) -> Bool {
        guard let tracked = compound.trackedCompound else { return false }

        let _ = coreDataManager.logDose(
            compound: compound,
            dosageAmount: tracked.dosageAmount,
            dosageUnit: tracked.dosageUnit,
            timestamp: Date(),
            injectionSite: InjectionSiteRecommendationService.shared.recommendNextSiteRawValue(for: compound),
            notes: nil
        )

        // Schedule next notification
        if tracked.notificationEnabled {
            NotificationService.shared.scheduleDoseReminder(for: tracked)
        }

        return true
    }
}
