import Foundation
import CoreGraphics

// MARK: - Injection Site Type (IM vs SubQ)
enum InjectionType: String, Codable {
    case intramuscular = "im"      // PEDs - larger volume
    case subcutaneous = "subq"     // Peptides - smaller volume
}

// MARK: - PED Injection Sites (Intramuscular)
enum PEDInjectionSite: String, CaseIterable, Codable {
    // Glutes with upper/lower sub-zones
    case gluteLeftUpper = "glute_left_upper"
    case gluteLeftLower = "glute_left_lower"
    case gluteRightUpper = "glute_right_upper"
    case gluteRightLower = "glute_right_lower"

    // Deltoids (no sub-zones needed for IM)
    case deltLeft = "delt_left"
    case deltRight = "delt_right"

    // Quads (no sub-zones needed for IM)
    case quadLeft = "quad_left"
    case quadRight = "quad_right"

    // Ventrogluteal with upper/lower sub-zones
    case vgLeftUpper = "vg_left_upper"
    case vgLeftLower = "vg_left_lower"
    case vgRightUpper = "vg_right_upper"
    case vgRightLower = "vg_right_lower"

    var displayName: String {
        switch self {
        case .gluteLeftUpper: return "Left Glute - Upper"
        case .gluteLeftLower: return "Left Glute - Lower"
        case .gluteRightUpper: return "Right Glute - Upper"
        case .gluteRightLower: return "Right Glute - Lower"
        case .deltLeft: return "Left Delt"
        case .deltRight: return "Right Delt"
        case .quadLeft: return "Left Quad"
        case .quadRight: return "Right Quad"
        case .vgLeftUpper: return "Left VG - Upper"
        case .vgLeftLower: return "Left VG - Lower"
        case .vgRightUpper: return "Right VG - Upper"
        case .vgRightLower: return "Right VG - Lower"
        }
    }

    var shortName: String {
        switch self {
        case .gluteLeftUpper: return "L Glute U"
        case .gluteLeftLower: return "L Glute L"
        case .gluteRightUpper: return "R Glute U"
        case .gluteRightLower: return "R Glute L"
        case .deltLeft: return "L Delt"
        case .deltRight: return "R Delt"
        case .quadLeft: return "L Quad"
        case .quadRight: return "R Quad"
        case .vgLeftUpper: return "L VG U"
        case .vgLeftLower: return "L VG L"
        case .vgRightUpper: return "R VG U"
        case .vgRightLower: return "R VG L"
        }
    }

    var bodyPart: String {
        switch self {
        case .gluteLeftUpper, .gluteLeftLower, .gluteRightUpper, .gluteRightLower:
            return "Glute"
        case .deltLeft, .deltRight:
            return "Delt"
        case .quadLeft, .quadRight:
            return "Quad"
        case .vgLeftUpper, .vgLeftLower, .vgRightUpper, .vgRightLower:
            return "Ventrogluteal"
        }
    }

    var side: String {
        switch self {
        case .gluteLeftUpper, .gluteLeftLower, .deltLeft, .quadLeft, .vgLeftUpper, .vgLeftLower:
            return "Left"
        case .gluteRightUpper, .gluteRightLower, .deltRight, .quadRight, .vgRightUpper, .vgRightLower:
            return "Right"
        }
    }

    var isLeftSide: Bool {
        return side == "Left"
    }

    static var grouped: [(name: String, sites: [PEDInjectionSite])] {
        return [
            ("Glutes", [.gluteLeftUpper, .gluteLeftLower, .gluteRightUpper, .gluteRightLower]),
            ("Delts", [.deltLeft, .deltRight]),
            ("Quads", [.quadLeft, .quadRight]),
            ("Ventrogluteal", [.vgLeftUpper, .vgLeftLower, .vgRightUpper, .vgRightLower])
        ]
    }

    // Body shape positioning - corrected for proper anatomy
    var bodyMapPosition: (x: CGFloat, y: CGFloat) {
        switch self {
        // Deltoids - on shoulders (not at head)
        case .deltLeft: return (0.22, 0.24)
        case .deltRight: return (0.78, 0.24)
        // Glutes - butt area (stacked vertically)
        case .gluteLeftUpper: return (0.32, 0.48)
        case .gluteLeftLower: return (0.32, 0.54)
        case .gluteRightUpper: return (0.68, 0.48)
        case .gluteRightLower: return (0.68, 0.54)
        // VG - hip area, below glutes
        case .vgLeftUpper: return (0.26, 0.50)
        case .vgLeftLower: return (0.26, 0.56)
        case .vgRightUpper: return (0.74, 0.50)
        case .vgRightLower: return (0.74, 0.56)
        // Quads - mid-thigh (not at knees)
        case .quadLeft: return (0.38, 0.62)
        case .quadRight: return (0.62, 0.62)
        }
    }
}

// MARK: - Peptide Injection Sites (Subcutaneous)
enum PeptideInjectionSite: String, CaseIterable, Codable {
    // Belly zones (6 total: Upper/Lower × Left/Middle/Right)
    case leftBellyUpper = "left_belly_upper"
    case centerBellyUpper = "center_belly_upper"
    case rightBellyUpper = "right_belly_upper"
    case leftBellyLower = "left_belly_lower"
    case centerBellyLower = "center_belly_lower"
    case rightBellyLower = "right_belly_lower"

    // Glute quadrants for SubQ (4 zones)
    case gluteLeftUpper = "glute_left_upper"
    case gluteLeftLower = "glute_left_lower"
    case gluteRightUpper = "glute_right_upper"
    case gluteRightLower = "glute_right_lower"

    // Thighs (6 zones: Upper/Middle/Lower × Left/Right)
    case thighLeftUpper = "thigh_left_upper"
    case thighLeftMiddle = "thigh_left_middle"
    case thighLeftLower = "thigh_left_lower"
    case thighRightUpper = "thigh_right_upper"
    case thighRightMiddle = "thigh_right_middle"
    case thighRightLower = "thigh_right_lower"

    // Deltoids (2 zones)
    case deltLeft = "delt_left"
    case deltRight = "delt_right"

    var displayName: String {
        switch self {
        case .leftBellyUpper: return "Belly - Upper Left"
        case .centerBellyUpper: return "Belly - Upper Middle"
        case .rightBellyUpper: return "Belly - Upper Right"
        case .leftBellyLower: return "Belly - Lower Left"
        case .centerBellyLower: return "Belly - Lower Middle"
        case .rightBellyLower: return "Belly - Lower Right"
        case .gluteLeftUpper: return "Left Glute - Upper"
        case .gluteLeftLower: return "Left Glute - Lower"
        case .gluteRightUpper: return "Right Glute - Upper"
        case .gluteRightLower: return "Right Glute - Lower"
        case .thighLeftUpper: return "Left Thigh - Upper"
        case .thighLeftMiddle: return "Left Thigh - Middle"
        case .thighLeftLower: return "Left Thigh - Lower"
        case .thighRightUpper: return "Right Thigh - Upper"
        case .thighRightMiddle: return "Right Thigh - Middle"
        case .thighRightLower: return "Right Thigh - Lower"
        case .deltLeft: return "Left Deltoid"
        case .deltRight: return "Right Deltoid"
        }
    }

    var shortName: String {
        switch self {
        case .leftBellyUpper: return "Belly UL"
        case .centerBellyUpper: return "Belly UM"
        case .rightBellyUpper: return "Belly UR"
        case .leftBellyLower: return "Belly LL"
        case .centerBellyLower: return "Belly LM"
        case .rightBellyLower: return "Belly LR"
        case .gluteLeftUpper: return "L Glute U"
        case .gluteLeftLower: return "L Glute L"
        case .gluteRightUpper: return "R Glute U"
        case .gluteRightLower: return "R Glute L"
        case .thighLeftUpper: return "L Thigh U"
        case .thighLeftMiddle: return "L Thigh M"
        case .thighLeftLower: return "L Thigh L"
        case .thighRightUpper: return "R Thigh U"
        case .thighRightMiddle: return "R Thigh M"
        case .thighRightLower: return "R Thigh L"
        case .deltLeft: return "L Delt"
        case .deltRight: return "R Delt"
        }
    }

    var bodyPart: String {
        switch self {
        case .leftBellyUpper, .centerBellyUpper, .rightBellyUpper,
             .leftBellyLower, .centerBellyLower, .rightBellyLower:
            return "Belly"
        case .gluteLeftUpper, .gluteLeftLower, .gluteRightUpper, .gluteRightLower:
            return "Glutes"
        case .thighLeftUpper, .thighLeftMiddle, .thighLeftLower,
             .thighRightUpper, .thighRightMiddle, .thighRightLower:
            return "Thighs"
        case .deltLeft, .deltRight:
            return "Deltoids"
        }
    }

    var isLeftSide: Bool {
        switch self {
        case .leftBellyUpper, .leftBellyLower,
             .gluteLeftUpper, .gluteLeftLower,
             .thighLeftUpper, .thighLeftMiddle, .thighLeftLower,
             .deltLeft:
            return true
        case .centerBellyUpper, .centerBellyLower:
            return false  // Center is neutral, treat as right for alternation
        default:
            return false
        }
    }

    static var grouped: [(name: String, sites: [PeptideInjectionSite])] {
        return [
            ("Belly", [.leftBellyUpper, .centerBellyUpper, .rightBellyUpper,
                       .leftBellyLower, .centerBellyLower, .rightBellyLower]),
            ("Glutes", [.gluteLeftUpper, .gluteLeftLower, .gluteRightUpper, .gluteRightLower]),
            ("Left Thigh", [.thighLeftUpper, .thighLeftMiddle, .thighLeftLower]),
            ("Right Thigh", [.thighRightUpper, .thighRightMiddle, .thighRightLower]),
            ("Deltoids", [.deltLeft, .deltRight])
        ]
    }

    // Body shape positioning (calibrated for scaled-up body silhouette)
    var bodyMapPosition: (x: CGFloat, y: CGFloat) {
        switch self {
        // Belly zones (3 columns × 2 rows) - centered on actual belly
        case .leftBellyUpper: return (0.38, 0.40)
        case .centerBellyUpper: return (0.50, 0.40)
        case .rightBellyUpper: return (0.62, 0.40)
        case .leftBellyLower: return (0.38, 0.46)
        case .centerBellyLower: return (0.50, 0.46)
        case .rightBellyLower: return (0.62, 0.46)
        // Glutes
        case .gluteLeftUpper: return (0.32, 0.50)
        case .gluteLeftLower: return (0.32, 0.56)
        case .gluteRightUpper: return (0.68, 0.50)
        case .gluteRightLower: return (0.68, 0.56)
        // Thighs
        case .thighLeftUpper: return (0.36, 0.60)
        case .thighLeftMiddle: return (0.36, 0.66)
        case .thighLeftLower: return (0.36, 0.72)
        case .thighRightUpper: return (0.64, 0.60)
        case .thighRightMiddle: return (0.64, 0.66)
        case .thighRightLower: return (0.64, 0.72)
        // Deltoids - on top of shoulders, not overlapping silhouette
        case .deltLeft: return (0.18, 0.26)
        case .deltRight: return (0.82, 0.26)
        }
    }
}

// MARK: - Unified Injection Site
enum InjectionSite: Codable, Equatable {
    case ped(PEDInjectionSite)
    case peptide(PeptideInjectionSite)
    case none

    var rawValue: String {
        switch self {
        case .ped(let site): return site.rawValue
        case .peptide(let site): return site.rawValue
        case .none: return "none"
        }
    }

    var displayName: String {
        switch self {
        case .ped(let site): return site.displayName
        case .peptide(let site): return site.displayName
        case .none: return "Not Applicable"
        }
    }

    var injectionType: InjectionType? {
        switch self {
        case .ped: return .intramuscular
        case .peptide: return .subcutaneous
        case .none: return nil
        }
    }

    static func from(rawValue: String, category: CompoundCategory) -> InjectionSite {
        if category == .ped {
            if let site = PEDInjectionSite(rawValue: rawValue) {
                return .ped(site)
            }
        } else if category == .peptide {
            if let site = PeptideInjectionSite(rawValue: rawValue) {
                return .peptide(site)
            }
        }
        return .none
    }
}
