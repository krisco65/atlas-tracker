import Foundation
import SwiftUI
import Combine

// MARK: - Reconstitution Result
struct ReconstitutionResult {
    let concentration: Double       // mg per ml
    let volumeToDrawMl: Double     // ml to draw for desired dose
    let syringeUnits: Double       // insulin syringe units (100-unit syringe)
    let dosesPerVial: Double       // number of doses per vial
    let totalVolumeMl: Double      // total volume after reconstitution

    var concentrationString: String {
        String(format: "%.2f mg/ml", concentration)
    }

    var volumeToDrawString: String {
        String(format: "%.3f ml", volumeToDrawMl)
    }

    var syringeUnitsString: String {
        String(format: "%.1f units", syringeUnits)
    }

    var dosesPerVialString: String {
        String(format: "%.0f doses", dosesPerVial.rounded(.down))
    }

    // Warning states
    var isVolumeVerySmall: Bool {
        volumeToDrawMl < 0.05 // Less than 5 units on insulin syringe
    }

    var isVolumeLarge: Bool {
        volumeToDrawMl > 1.0 // More than 1ml per injection
    }
}

// MARK: - Reconstitution View Model
final class ReconstitutionViewModel: ObservableObject {

    // MARK: - Input Properties
    @Published var vialSizeMg: String = ""
    @Published var desiredDoseMg: String = ""
    @Published var bacWaterMl: String = ""

    // Toggle between mg and mcg for dose input
    @Published var doseUnitIsMcg: Bool = false

    // MARK: - Output Properties
    @Published var result: ReconstitutionResult?
    @Published var errorMessage: String?
    @Published var showBeginnerGuide: Bool = false

    // MARK: - Selected Compound (for saving settings)
    @Published var selectedCompound: TrackedCompound?

    // MARK: - Common Presets
    struct Preset: Identifiable {
        let id = UUID()
        let name: String
        let vialSizeMg: Double
        let typicalDoseMcg: Double
        let suggestedBacMl: Double
    }

    let commonPresets: [Preset] = [
        Preset(name: "HGH (10 IU)", vialSizeMg: 3.33, typicalDoseMcg: 333, suggestedBacMl: 1.0),
        Preset(name: "BPC-157 (5mg)", vialSizeMg: 5, typicalDoseMcg: 250, suggestedBacMl: 2.0),
        Preset(name: "TB-500 (5mg)", vialSizeMg: 5, typicalDoseMcg: 500, suggestedBacMl: 2.0),
        Preset(name: "Tirzepatide (5mg)", vialSizeMg: 5, typicalDoseMcg: 2500, suggestedBacMl: 1.0),
        Preset(name: "Semaglutide (3mg)", vialSizeMg: 3, typicalDoseMcg: 250, suggestedBacMl: 1.5),
        Preset(name: "CJC-1295 (2mg)", vialSizeMg: 2, typicalDoseMcg: 100, suggestedBacMl: 2.0),
        Preset(name: "Ipamorelin (2mg)", vialSizeMg: 2, typicalDoseMcg: 100, suggestedBacMl: 2.0),
    ]

    // MARK: - Computed Properties

    var canCalculate: Bool {
        guard let vial = Double(vialSizeMg), vial > 0,
              let dose = Double(desiredDoseMg), dose > 0,
              let bac = Double(bacWaterMl), bac > 0 else {
            return false
        }
        return true
    }

    var desiredDoseInMg: Double? {
        guard let dose = Double(desiredDoseMg), dose > 0 else { return nil }
        return doseUnitIsMcg ? dose / 1000 : dose
    }

    var doseUnitLabel: String {
        doseUnitIsMcg ? "mcg" : "mg"
    }

    // MARK: - Calculation

    func calculate() {
        errorMessage = nil

        guard let vialMg = Double(vialSizeMg), vialMg > 0 else {
            errorMessage = "Please enter a valid vial size"
            result = nil
            return
        }

        guard let doseMg = desiredDoseInMg, doseMg > 0 else {
            errorMessage = "Please enter a valid desired dose"
            result = nil
            return
        }

        guard let bacMl = Double(bacWaterMl), bacMl > 0 else {
            errorMessage = "Please enter a valid BAC water amount"
            result = nil
            return
        }

        // Validate dose isn't larger than vial
        if doseMg > vialMg {
            errorMessage = "Desired dose cannot exceed vial size"
            result = nil
            return
        }

        // Calculate concentration: mg per ml
        let concentration = vialMg / bacMl

        // Calculate volume to draw for desired dose
        let volumeToDraw = doseMg / concentration

        // Calculate insulin syringe units (100-unit syringe = 1ml)
        let syringeUnits = volumeToDraw * 100

        // Calculate doses per vial
        let dosesPerVial = vialMg / doseMg

        result = ReconstitutionResult(
            concentration: concentration,
            volumeToDrawMl: volumeToDraw,
            syringeUnits: syringeUnits,
            dosesPerVial: dosesPerVial,
            totalVolumeMl: bacMl
        )
    }

    // MARK: - Apply Preset

    func applyPreset(_ preset: Preset) {
        vialSizeMg = String(format: "%.2f", preset.vialSizeMg)
        desiredDoseMg = String(format: "%.0f", preset.typicalDoseMcg)
        bacWaterMl = String(format: "%.1f", preset.suggestedBacMl)
        doseUnitIsMcg = true

        // Auto-calculate after applying preset
        calculate()

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    // MARK: - Save to Compound

    func saveToCompound() {
        guard let tracked = selectedCompound,
              let bacMl = Double(bacWaterMl),
              let result = result else { return }

        tracked.reconstitutionBAC = bacMl
        tracked.reconstitutionConcentration = result.concentration

        CoreDataManager.shared.saveContext()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Load from Compound

    func loadFromCompound(_ tracked: TrackedCompound) {
        selectedCompound = tracked

        if tracked.reconstitutionBAC > 0 {
            bacWaterMl = String(format: "%.1f", tracked.reconstitutionBAC)
        }

        if tracked.reconstitutionConcentration > 0 {
            // Back-calculate vial size if we have concentration and BAC
            if let bac = Double(bacWaterMl), bac > 0 {
                let vialSize = tracked.reconstitutionConcentration * bac
                vialSizeMg = String(format: "%.2f", vialSize)
            }
        }

        // Set dose from tracked compound
        let dose = tracked.dosageAmount
        if dose < 1 {
            // Convert to mcg for display
            desiredDoseMg = String(format: "%.0f", dose * 1000)
            doseUnitIsMcg = true
        } else {
            desiredDoseMg = String(format: "%.2f", dose)
            doseUnitIsMcg = false
        }
    }

    // MARK: - Reset

    func reset() {
        vialSizeMg = ""
        desiredDoseMg = ""
        bacWaterMl = ""
        doseUnitIsMcg = false
        result = nil
        errorMessage = nil
    }

    // MARK: - Suggested BAC Water

    /// Suggests optimal BAC water based on vial size and desired dose
    /// Targets 25 units on insulin syringe for easy measurement
    func suggestBacWater() -> String? {
        guard let vialMg = Double(vialSizeMg), vialMg > 0,
              let doseMg = desiredDoseInMg, doseMg > 0 else {
            return nil
        }

        // Target: 25 units per dose for easy measurement
        let targetUnits = 25.0
        let targetVolume = targetUnits / 100 // ml (0.25 ml)

        // Formula: BAC water = (vialMg * targetVolume) / doseMg
        let suggestedBac = (vialMg * targetVolume) / doseMg

        // Round to practical amounts (0.5, 1.0, 1.5, 2.0, etc.)
        let roundedBac = (suggestedBac * 2).rounded() / 2

        // Clamp to reasonable range (0.5 - 3.0 ml)
        let clampedBac = max(0.5, min(3.0, roundedBac))

        return String(format: "%.1f", clampedBac)
    }

    /// Auto-calculates with suggested BAC water
    func autoCalculate() {
        guard let suggestion = suggestBacWater() else { return }
        bacWaterMl = suggestion
        calculate()
    }

    /// Human-readable explanation of the math
    var explanationText: String? {
        guard let result = result,
              let vialMg = Double(vialSizeMg),
              let bacMl = Double(bacWaterMl),
              desiredDoseInMg != nil else { return nil }

        let doseString = doseUnitIsMcg ? "\(desiredDoseMg) mcg" : "\(desiredDoseMg) mg"

        return """
        Add \(String(format: "%.1f", bacMl)) ml of BAC water to your \(String(format: "%.0f", vialMg)) mg vial.

        For your \(doseString) dose, draw \(result.syringeUnitsString) (\(result.volumeToDrawString)).

        This vial will give you \(result.dosesPerVialString).
        """
    }
}
