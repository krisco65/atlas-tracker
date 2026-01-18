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
    // Left side of belly button (2 zones)
    case leftBellyUpper = "left_belly_upper"
    case leftBellyLower = "left_belly_lower"

    // Right side of belly button (2 zones)
    case rightBellyUpper = "right_belly_upper"
    case rightBellyLower = "right_belly_lower"

    // Left love handle (2 zones)
    case leftLoveHandleUpper = "left_love_handle_upper"
    case leftLoveHandleLower = "left_love_handle_lower"

    // Right love handle (2 zones)
    case rightLoveHandleUpper = "right_love_handle_upper"
    case rightLoveHandleLower = "right_love_handle_lower"

    // Glute quadrants for SubQ (4 zones)
    case gluteLeftUpper = "glute_left_upper"
    case gluteLeftLower = "glute_left_lower"
    case gluteRightUpper = "glute_right_upper"
    case gluteRightLower = "glute_right_lower"

    // Thighs (2 zones)
    case thighLeft = "thigh_left"
    case thighRight = "thigh_right"

    var displayName: String {
        switch self {
        case .leftBellyUpper: return "Left of Navel - Upper"
        case .leftBellyLower: return "Left of Navel - Lower"
        case .rightBellyUpper: return "Right of Navel - Upper"
        case .rightBellyLower: return "Right of Navel - Lower"
        case .leftLoveHandleUpper: return "Left Love Handle - Upper"
        case .leftLoveHandleLower: return "Left Love Handle - Lower"
        case .rightLoveHandleUpper: return "Right Love Handle - Upper"
        case .rightLoveHandleLower: return "Right Love Handle - Lower"
        case .gluteLeftUpper: return "Left Glute - Upper"
        case .gluteLeftLower: return "Left Glute - Lower"
        case .gluteRightUpper: return "Right Glute - Upper"
        case .gluteRightLower: return "Right Glute - Lower"
        case .thighLeft: return "Left Thigh"
        case .thighRight: return "Right Thigh"
        }
    }

    var shortName: String {
        switch self {
        case .leftBellyUpper: return "L Belly U"
        case .leftBellyLower: return "L Belly L"
        case .rightBellyUpper: return "R Belly U"
        case .rightBellyLower: return "R Belly L"
        case .leftLoveHandleUpper: return "L Handle U"
        case .leftLoveHandleLower: return "L Handle L"
        case .rightLoveHandleUpper: return "R Handle U"
        case .rightLoveHandleLower: return "R Handle L"
        case .gluteLeftUpper: return "L Glute U"
        case .gluteLeftLower: return "L Glute L"
        case .gluteRightUpper: return "R Glute U"
        case .gluteRightLower: return "R Glute L"
        case .thighLeft: return "L Thigh"
        case .thighRight: return "R Thigh"
        }
    }

    var bodyPart: String {
        switch self {
        case .leftBellyUpper, .leftBellyLower, .rightBellyUpper, .rightBellyLower:
            return "Belly"
        case .leftLoveHandleUpper, .leftLoveHandleLower, .rightLoveHandleUpper, .rightLoveHandleLower:
            return "Love Handles"
        case .gluteLeftUpper, .gluteLeftLower, .gluteRightUpper, .gluteRightLower:
            return "Glutes"
        case .thighLeft, .thighRight:
            return "Thighs"
        }
    }

    var isLeftSide: Bool {
        switch self {
        case .leftBellyUpper, .leftBellyLower, .leftLoveHandleUpper, .leftLoveHandleLower,
             .gluteLeftUpper, .gluteLeftLower, .thighLeft:
            return true
        default:
            return false
        }
    }

    static var grouped: [(name: String, sites: [PeptideInjectionSite])] {
        return [
            ("Belly (Left of Navel)", [.leftBellyUpper, .leftBellyLower]),
            ("Belly (Right of Navel)", [.rightBellyUpper, .rightBellyLower]),
            ("Left Love Handle", [.leftLoveHandleUpper, .leftLoveHandleLower]),
            ("Right Love Handle", [.rightLoveHandleUpper, .rightLoveHandleLower]),
            ("Glutes", [.gluteLeftUpper, .gluteLeftLower, .gluteRightUpper, .gluteRightLower]),
            ("Thighs", [.thighLeft, .thighRight])
        ]
    }

    // Body shape positioning (calibrated for ProfessionalBodyShape)
    // x: 0=left edge, 1=right edge; y: 0=top, 1=bottom
    var bodyMapPosition: (x: CGFloat, y: CGFloat) {
        switch self {
        // Belly - left of navel (inner abdomen)
        case .leftBellyUpper: return (0.40, 0.37)
        case .leftBellyLower: return (0.40, 0.42)
        // Belly - right of navel (inner abdomen)
        case .rightBellyUpper: return (0.60, 0.37)
        case .rightBellyLower: return (0.60, 0.42)
        // Love handles - outer sides
        case .leftLoveHandleUpper: return (0.24, 0.37)
        case .leftLoveHandleLower: return (0.24, 0.42)
        case .rightLoveHandleUpper: return (0.76, 0.37)
        case .rightLoveHandleLower: return (0.76, 0.42)
        // Glutes (SubQ) - hip area
        case .gluteLeftUpper: return (0.30, 0.50)
        case .gluteLeftLower: return (0.30, 0.55)
        case .gluteRightUpper: return (0.70, 0.50)
        case .gluteRightLower: return (0.70, 0.55)
        // Thighs - front of legs
        case .thighLeft: return (0.38, 0.68)
        case .thighRight: return (0.62, 0.68)
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
