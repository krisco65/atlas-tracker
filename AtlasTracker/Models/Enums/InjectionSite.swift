import Foundation
import CoreGraphics

// MARK: - Injection Site Type (IM vs SubQ)
enum InjectionType: String, Codable {
    case intramuscular = "im"      // PEDs - larger volume
    case subcutaneous = "subq"     // Peptides - smaller volume
}

// MARK: - PED Injection Sites (Intramuscular)
enum PEDInjectionSite: String, CaseIterable, Codable {
    case gluteLeft = "glute_left"
    case gluteRight = "glute_right"
    case deltLeft = "delt_left"
    case deltRight = "delt_right"
    case quadLeft = "quad_left"
    case quadRight = "quad_right"
    case vgLeft = "vg_left"         // Ventrogluteal
    case vgRight = "vg_right"

    var displayName: String {
        switch self {
        case .gluteLeft: return "Left Glute"
        case .gluteRight: return "Right Glute"
        case .deltLeft: return "Left Delt"
        case .deltRight: return "Right Delt"
        case .quadLeft: return "Left Quad"
        case .quadRight: return "Right Quad"
        case .vgLeft: return "Left VG"
        case .vgRight: return "Right VG"
        }
    }

    var shortName: String {
        switch self {
        case .gluteLeft: return "L Glute"
        case .gluteRight: return "R Glute"
        case .deltLeft: return "L Delt"
        case .deltRight: return "R Delt"
        case .quadLeft: return "L Quad"
        case .quadRight: return "R Quad"
        case .vgLeft: return "L VG"
        case .vgRight: return "R VG"
        }
    }

    var bodyPart: String {
        switch self {
        case .gluteLeft, .gluteRight: return "Glute"
        case .deltLeft, .deltRight: return "Delt"
        case .quadLeft, .quadRight: return "Quad"
        case .vgLeft, .vgRight: return "Ventrogluteal"
        }
    }

    var side: String {
        switch self {
        case .gluteLeft, .deltLeft, .quadLeft, .vgLeft: return "Left"
        case .gluteRight, .deltRight, .quadRight, .vgRight: return "Right"
        }
    }

    var isLeftSide: Bool {
        return side == "Left"
    }

    // Get opposite side for rotation
    var oppositeSite: PEDInjectionSite {
        switch self {
        case .gluteLeft: return .gluteRight
        case .gluteRight: return .gluteLeft
        case .deltLeft: return .deltRight
        case .deltRight: return .deltLeft
        case .quadLeft: return .quadRight
        case .quadRight: return .quadLeft
        case .vgLeft: return .vgRight
        case .vgRight: return .vgLeft
        }
    }

    static var grouped: [(name: String, sites: [PEDInjectionSite])] {
        return [
            ("Glutes", [.gluteLeft, .gluteRight]),
            ("Delts", [.deltLeft, .deltRight]),
            ("Quads", [.quadLeft, .quadRight]),
            ("Ventrogluteal", [.vgLeft, .vgRight])
        ]
    }

    // Body shape positioning (calibrated for ProfessionalBodyShape)
    // x: 0=left edge, 1=right edge; y: 0=top, 1=bottom
    var bodyMapPosition: (x: CGFloat, y: CGFloat) {
        switch self {
        case .deltLeft: return (0.15, 0.17)     // Left shoulder/deltoid
        case .deltRight: return (0.85, 0.17)    // Right shoulder/deltoid
        case .vgLeft: return (0.22, 0.48)       // Left ventrogluteal (hip)
        case .vgRight: return (0.78, 0.48)      // Right ventrogluteal (hip)
        case .gluteLeft: return (0.30, 0.52)    // Left glute
        case .gluteRight: return (0.70, 0.52)   // Right glute
        case .quadLeft: return (0.38, 0.68)     // Left quadricep
        case .quadRight: return (0.62, 0.68)    // Right quadricep
        }
    }
}

// MARK: - Peptide Injection Sites (Subcutaneous)
enum PeptideInjectionSite: String, CaseIterable, Codable {
    // Belly zones (6 total: Upper/Lower × Left/Middle/Right)
    case leftBellyUpper = "left_belly_upper"
    case leftBellyLower = "left_belly_lower"
    case rightBellyUpper = "right_belly_upper"
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
        case .leftBellyLower: return "Belly - Lower Left"
        case .rightBellyUpper: return "Belly - Upper Right"
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
        case .leftBellyLower: return "Belly LL"
        case .rightBellyUpper: return "Belly UR"
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
        case .leftBellyUpper, .leftBellyLower, .rightBellyUpper, .rightBellyLower:
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
        default:
            return false
        }
    }

    static var grouped: [(name: String, sites: [PeptideInjectionSite])] {
        return [
            ("Belly", [.leftBellyUpper, .leftBellyLower, .rightBellyUpper, .rightBellyLower]),
            ("Glutes", [.gluteLeftUpper, .gluteLeftLower, .gluteRightUpper, .gluteRightLower]),
            ("Left Thigh", [.thighLeftUpper, .thighLeftMiddle, .thighLeftLower]),
            ("Right Thigh", [.thighRightUpper, .thighRightMiddle, .thighRightLower]),
            ("Deltoids", [.deltLeft, .deltRight])
        ]
    }

    // Body shape positioning (calibrated for scaled-up body silhouette)
    var bodyMapPosition: (x: CGFloat, y: CGFloat) {
        switch self {
        // Belly zones
        case .leftBellyUpper: return (0.40, 0.36)
        case .leftBellyLower: return (0.40, 0.42)
        case .rightBellyUpper: return (0.60, 0.36)
        case .rightBellyLower: return (0.60, 0.42)
        // Glutes
        case .gluteLeftUpper: return (0.32, 0.50)
        case .gluteLeftLower: return (0.32, 0.56)
        case .gluteRightUpper: return (0.68, 0.50)
        case .gluteRightLower: return (0.68, 0.56)
        // Thighs (corrected - now at actual thigh position)
        case .thighLeftUpper: return (0.36, 0.60)
        case .thighLeftMiddle: return (0.36, 0.66)
        case .thighLeftLower: return (0.36, 0.72)
        case .thighRightUpper: return (0.64, 0.60)
        case .thighRightMiddle: return (0.64, 0.66)
        case .thighRightLower: return (0.64, 0.72)
        // Deltoids
        case .deltLeft: return (0.18, 0.20)
        case .deltRight: return (0.82, 0.20)
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
