import Foundation
import SwiftUI

enum CompoundCategory: String, CaseIterable, Codable {
    case supplement = "supplement"
    case ped = "ped"
    case peptide = "peptide"
    case medicine = "medicine"

    var displayName: String {
        switch self {
        case .supplement: return "Supplement"
        case .ped: return "PED"
        case .peptide: return "Peptide"
        case .medicine: return "Medicine"
        }
    }

    var color: Color {
        switch self {
        case .supplement: return Color.categorySuplement
        case .ped: return Color.categoryPED
        case .peptide: return Color.categoryPeptide
        case .medicine: return Color.categoryMedicine
        }
    }

    var icon: String {
        switch self {
        case .supplement: return "leaf.fill"
        case .ped: return "bolt.fill"
        case .peptide: return "drop.fill"
        case .medicine: return "pills.fill"
        }
    }

    var supportsInventory: Bool {
        switch self {
        case .ped, .peptide: return true
        case .supplement, .medicine: return false
        }
    }
}
