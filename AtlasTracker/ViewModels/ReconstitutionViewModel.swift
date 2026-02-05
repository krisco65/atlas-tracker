import Foundation
import Observation
import SwiftUI

// MARK: - Reconstitution Result
struct ReconstitutionResult {
    let bacWaterMl: Double          // how much BAC water to add (the answer)
    let concentration: Double       // mg per ml after reconstitution
    let volumeToDrawMl: Double     // ml to draw for desired dose
    let syringeUnits: Double       // insulin syringe units per dose
    let dosesPerVial: Double       // number of doses per vial

    var bacWaterString: String {
        String(format: "%.2f ml", bacWaterMl)
    }

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
    var isBacWaterVerySmall: Bool {
        bacWaterMl < 0.3
    }

    var isBacWaterLarge: Bool {
        bacWaterMl > 5.0
    }

    var isVolumeLarge: Bool {
        volumeToDrawMl > 1.0
    }
}

// MARK: - Vial Size Unit
enum VialSizeUnit: String, CaseIterable {
    case mg = "mg"
    case iu = "IU"

    var displayName: String { rawValue }
}

// MARK: - Reconstitution View Model
@Observable
final class ReconstitutionViewModel {

    // MARK: - Input Properties

    // Step 1: Vial size
    var vialSize: String = ""
    var vialSizeUnit: VialSizeUnit = .mg

    // Step 2: Desired dose per injection
    var desiredDose: String = ""
    var doseUnitIsMcg: Bool = false  // toggle between mg/IU and mcg

    // Step 3: Syringe units (how many units on the syringe per dose)
    var syringeUnits: String = "20"

    // MARK: - Output Properties
    var result: ReconstitutionResult?
    var errorMessage: String?
    var showBeginnerGuide: Bool = false

    // MARK: - Selected Compound (for saving settings)
    var selectedCompound: TrackedCompound?

    // MARK: - Backward compat: mapped property for presets
    var vialSizeMg: String {
        get { vialSize }
        set { vialSize = newValue }
    }

    var desiredDoseMg: String {
        get { desiredDose }
        set { desiredDose = newValue }
    }

    // MARK: - Common Presets
    struct Preset: Identifiable {
        let id = UUID()
        let name: String
        let vialSize: Double
        let vialUnit: VialSizeUnit
        let typicalDose: Double    // in the dose display unit
        let doseIsMcg: Bool
        let syringeUnits: Double
    }

    let commonPresets: [Preset] = [
        Preset(name: "Retatrutide (10mg)", vialSize: 10, vialUnit: .mg, typicalDose: 2, doseIsMcg: false, syringeUnits: 20),
        Preset(name: "HGH (10 IU)", vialSize: 10, vialUnit: .iu, typicalDose: 2, doseIsMcg: false, syringeUnits: 20),
        Preset(name: "HCG (5000 IU)", vialSize: 5000, vialUnit: .iu, typicalDose: 500, doseIsMcg: false, syringeUnits: 20),
        Preset(name: "BPC-157 (5mg)", vialSize: 5, vialUnit: .mg, typicalDose: 250, doseIsMcg: true, syringeUnits: 20),
        Preset(name: "Tirzepatide (5mg)", vialSize: 5, vialUnit: .mg, typicalDose: 2.5, doseIsMcg: false, syringeUnits: 20),
        Preset(name: "Semaglutide (3mg)", vialSize: 3, vialUnit: .mg, typicalDose: 250, doseIsMcg: true, syringeUnits: 25),
        Preset(name: "CJC/Ipa (2mg)", vialSize: 2, vialUnit: .mg, typicalDose: 100, doseIsMcg: true, syringeUnits: 20),
    ]

    // MARK: - Computed Properties

    var canCalculate: Bool {
        guard let vial = Double(vialSize), vial > 0,
              let dose = doseInVialUnits, dose > 0,
              let units = Double(syringeUnits), units > 0 else {
            return false
        }
        // Dose must be <= vial size (in same units)
        return dose <= vial
    }

    /// Converts the desired dose into the same unit as the vial (mg or IU)
    var doseInVialUnits: Double? {
        guard let dose = Double(desiredDose), dose > 0 else { return nil }
        if vialSizeUnit == .mg && doseUnitIsMcg {
            return dose / 1000  // mcg → mg
        }
        return dose
    }

    var doseUnitLabel: String {
        if vialSizeUnit == .iu {
            return "IU"
        }
        return doseUnitIsMcg ? "mcg" : "mg"
    }

    // MARK: - Calculation (solves for BAC water)

    func calculate() {
        errorMessage = nil

        guard let vial = Double(vialSize), vial > 0, vial <= 100000 else {
            errorMessage = "Enter a valid vial size"
            result = nil
            return
        }

        guard let dose = doseInVialUnits, dose > 0 else {
            errorMessage = "Enter a valid desired dose"
            result = nil
            return
        }

        guard let units = Double(syringeUnits), units > 0, units <= 100 else {
            errorMessage = "Enter valid syringe units (1-100)"
            result = nil
            return
        }

        if dose > vial {
            errorMessage = "Dose cannot exceed vial size"
            result = nil
            return
        }

        // Formula: bacWaterMl = (syringeUnits * vialSize) / (dose * 100)
        // Derivation:
        //   syringeUnits = volumeToDraw * 100
        //   volumeToDraw = dose / concentration
        //   concentration = vialSize / bacWater
        //   => syringeUnits = (dose * bacWater / vialSize) * 100
        //   => bacWater = (syringeUnits * vialSize) / (dose * 100)
        let bacWaterMl = (units * vial) / (dose * 100)

        let concentration = vial / bacWaterMl
        let volumeToDraw = dose / concentration
        let dosesPerVial = vial / dose

        result = ReconstitutionResult(
            bacWaterMl: bacWaterMl,
            concentration: concentration,
            volumeToDrawMl: volumeToDraw,
            syringeUnits: units,
            dosesPerVial: dosesPerVial
        )
        HapticManager.success()
    }

    // MARK: - Apply Preset

    func applyPreset(_ preset: Preset) {
        vialSize = preset.vialUnit == .iu && preset.vialSize >= 1000
            ? String(format: "%.0f", preset.vialSize)
            : String(format: "%g", preset.vialSize)
        vialSizeUnit = preset.vialUnit
        desiredDose = preset.doseIsMcg
            ? String(format: "%.0f", preset.typicalDose)
            : String(format: "%g", preset.typicalDose)
        doseUnitIsMcg = preset.doseIsMcg
        syringeUnits = String(format: "%.0f", preset.syringeUnits)

        calculate()
        HapticManager.mediumImpact()
    }

    // MARK: - Save to Compound

    func saveToCompound() {
        guard let tracked = selectedCompound,
              let result = result else { return }

        tracked.reconstitutionBAC = result.bacWaterMl
        tracked.reconstitutionConcentration = result.concentration
        CoreDataManager.shared.saveContext()
        HapticManager.success()
    }

    // MARK: - Load from Compound

    func loadFromCompound(_ tracked: TrackedCompound) {
        selectedCompound = tracked

        if let compound = tracked.compound {
            // Determine vial unit based on compound
            let name = (compound.name ?? "").lowercased()
            if name.contains("hgh") || name.contains("hcg") || name.contains("growth") {
                vialSizeUnit = .iu
            }
        }

        // Set dose from tracked compound
        let dose = tracked.dosageAmount
        if dose < 1 && vialSizeUnit == .mg {
            desiredDose = String(format: "%.0f", dose * 1000)
            doseUnitIsMcg = true
        } else {
            desiredDose = String(format: "%g", dose)
            doseUnitIsMcg = false
        }
    }

    // MARK: - Reset

    func reset() {
        vialSize = ""
        desiredDose = ""
        syringeUnits = "20"
        vialSizeUnit = .mg
        doseUnitIsMcg = false
        result = nil
        errorMessage = nil
    }

    // MARK: - Explanation Text

    var explanationText: String? {
        guard let result = result,
              let vial = Double(vialSize) else { return nil }

        let vialStr = "\(String(format: "%g", vial)) \(vialSizeUnit.displayName)"
        let doseStr = "\(desiredDose) \(doseUnitLabel)"
        let unitsStr = String(format: "%.0f", result.syringeUnits)

        return """
        Add \(result.bacWaterString) of BAC water to your \(vialStr) vial.

        Each \(doseStr) dose = \(unitsStr) units on your syringe.

        This vial will give you \(result.dosesPerVialString).
        """
    }
}
