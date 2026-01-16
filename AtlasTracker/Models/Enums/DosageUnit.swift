import Foundation

enum DosageUnit: String, CaseIterable, Codable {
    case mg = "mg"
    case mcg = "mcg"
    case iu = "IU"
    case ml = "ml"
    case g = "g"
    case units = "units"
    case capsules = "caps"
    case tablets = "tabs"

    var displayName: String {
        return rawValue
    }

    var longName: String {
        switch self {
        case .mg: return "milligrams"
        case .mcg: return "micrograms"
        case .iu: return "international units"
        case .ml: return "milliliters"
        case .g: return "grams"
        case .units: return "units"
        case .capsules: return "capsules"
        case .tablets: return "tablets"
        }
    }

    static var injectableUnits: [DosageUnit] {
        return [.mg, .mcg, .iu, .ml]
    }

    static var oralUnits: [DosageUnit] {
        return [.mg, .mcg, .g, .capsules, .tablets]
    }

    // Conversion factor to base unit (mg for mass, ml for volume)
    var conversionFactor: Double {
        switch self {
        case .mg: return 1.0
        case .mcg: return 0.001
        case .g: return 1000.0
        case .ml: return 1.0
        case .iu, .units, .capsules, .tablets: return 1.0
        }
    }
}
