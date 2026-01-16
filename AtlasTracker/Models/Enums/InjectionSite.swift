import Foundation

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
}

// MARK: - Peptide Injection Sites (Subcutaneous)
enum PeptideInjectionSite: String, CaseIterable, Codable {
    // Belly quadrants
    case bellyUpperLeft = "belly_upper_left"
    case bellyUpperRight = "belly_upper_right"
    case bellyLowerLeft = "belly_lower_left"
    case bellyLowerRight = "belly_lower_right"

    // Love handles
    case loveHandleLeft = "love_handle_left"
    case loveHandleRight = "love_handle_right"

    // Glute quadrants for SubQ
    case gluteLeftUpper = "glute_left_upper"
    case gluteLeftLower = "glute_left_lower"
    case gluteRightUpper = "glute_right_upper"
    case gluteRightLower = "glute_right_lower"

    // Thighs
    case thighLeft = "thigh_left"
    case thighRight = "thigh_right"

    var displayName: String {
        switch self {
        case .bellyUpperLeft: return "Belly - Upper Left"
        case .bellyUpperRight: return "Belly - Upper Right"
        case .bellyLowerLeft: return "Belly - Lower Left"
        case .bellyLowerRight: return "Belly - Lower Right"
        case .loveHandleLeft: return "Left Love Handle"
        case .loveHandleRight: return "Right Love Handle"
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
        case .bellyUpperLeft: return "Belly UL"
        case .bellyUpperRight: return "Belly UR"
        case .bellyLowerLeft: return "Belly LL"
        case .bellyLowerRight: return "Belly LR"
        case .loveHandleLeft: return "L Handle"
        case .loveHandleRight: return "R Handle"
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
        case .bellyUpperLeft, .bellyUpperRight, .bellyLowerLeft, .bellyLowerRight:
            return "Belly"
        case .loveHandleLeft, .loveHandleRight:
            return "Love Handles"
        case .gluteLeftUpper, .gluteLeftLower, .gluteRightUpper, .gluteRightLower:
            return "Glutes"
        case .thighLeft, .thighRight:
            return "Thighs"
        }
    }

    var isLeftSide: Bool {
        switch self {
        case .bellyUpperLeft, .bellyLowerLeft, .loveHandleLeft,
             .gluteLeftUpper, .gluteLeftLower, .thighLeft:
            return true
        default:
            return false
        }
    }

    static var grouped: [(name: String, sites: [PeptideInjectionSite])] {
        return [
            ("Belly", [.bellyUpperLeft, .bellyUpperRight, .bellyLowerLeft, .bellyLowerRight]),
            ("Love Handles", [.loveHandleLeft, .loveHandleRight]),
            ("Glutes", [.gluteLeftUpper, .gluteLeftLower, .gluteRightUpper, .gluteRightLower]),
            ("Thighs", [.thighLeft, .thighRight])
        ]
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
