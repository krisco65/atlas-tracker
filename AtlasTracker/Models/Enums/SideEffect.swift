import Foundation
import SwiftUI

// MARK: - Side Effect
/// Common side effects that can be tracked with doses
enum SideEffect: String, CaseIterable, Codable, Identifiable {
    // Gastrointestinal
    case nausea = "nausea"
    case vomiting = "vomiting"
    case diarrhea = "diarrhea"
    case constipation = "constipation"
    case decreasedAppetite = "decreased_appetite"
    case increasedAppetite = "increased_appetite"

    // Neurological
    case headache = "headache"
    case dizziness = "dizziness"
    case fatigue = "fatigue"
    case insomnia = "insomnia"
    case brainFog = "brain_fog"

    // Injection Site
    case injectionSitePain = "injection_site_pain"
    case injectionSiteRedness = "injection_site_redness"
    case injectionSiteSwelling = "injection_site_swelling"

    // Mood/Mental
    case irritability = "irritability"
    case anxiety = "anxiety"
    case moodSwings = "mood_swings"

    // Physical
    case sweating = "sweating"
    case nightSweats = "night_sweats"
    case waterRetention = "water_retention"
    case muscleStiffness = "muscle_stiffness"
    case jointPain = "joint_pain"
    case acne = "acne"

    // Cardiovascular
    case heartPalpitations = "heart_palpitations"
    case elevatedBloodPressure = "elevated_bp"

    // Positive effects (for tracking benefits)
    case increasedEnergy = "increased_energy"
    case improvedMood = "improved_mood"
    case betterSleep = "better_sleep"

    // None/Clear
    case none = "none"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nausea: return "Nausea"
        case .vomiting: return "Vomiting"
        case .diarrhea: return "Diarrhea"
        case .constipation: return "Constipation"
        case .decreasedAppetite: return "Decreased Appetite"
        case .increasedAppetite: return "Increased Appetite"
        case .headache: return "Headache"
        case .dizziness: return "Dizziness"
        case .fatigue: return "Fatigue"
        case .insomnia: return "Insomnia"
        case .brainFog: return "Brain Fog"
        case .injectionSitePain: return "Injection Site Pain"
        case .injectionSiteRedness: return "Injection Site Redness"
        case .injectionSiteSwelling: return "Injection Site Swelling"
        case .irritability: return "Irritability"
        case .anxiety: return "Anxiety"
        case .moodSwings: return "Mood Swings"
        case .sweating: return "Sweating"
        case .nightSweats: return "Night Sweats"
        case .waterRetention: return "Water Retention"
        case .muscleStiffness: return "Muscle Stiffness"
        case .jointPain: return "Joint Pain"
        case .acne: return "Acne"
        case .heartPalpitations: return "Heart Palpitations"
        case .elevatedBloodPressure: return "Elevated BP"
        case .increasedEnergy: return "Increased Energy"
        case .improvedMood: return "Improved Mood"
        case .betterSleep: return "Better Sleep"
        case .none: return "None"
        }
    }

    var icon: String {
        switch self {
        case .nausea, .vomiting, .diarrhea, .constipation:
            return "stomach"
        case .decreasedAppetite, .increasedAppetite:
            return "fork.knife"
        case .headache, .dizziness, .brainFog:
            return "brain.head.profile"
        case .fatigue:
            return "battery.25"
        case .insomnia:
            return "moon.zzz"
        case .injectionSitePain, .injectionSiteRedness, .injectionSiteSwelling:
            return "syringe"
        case .irritability, .anxiety, .moodSwings:
            return "brain"
        case .sweating, .nightSweats:
            return "drop.fill"
        case .waterRetention:
            return "drop.triangle"
        case .muscleStiffness, .jointPain:
            return "figure.walk"
        case .acne:
            return "face.smiling"
        case .heartPalpitations, .elevatedBloodPressure:
            return "heart.fill"
        case .increasedEnergy:
            return "bolt.fill"
        case .improvedMood:
            return "sun.max.fill"
        case .betterSleep:
            return "bed.double.fill"
        case .none:
            return "checkmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .none:
            return .statusSuccess
        case .increasedEnergy, .improvedMood, .betterSleep:
            return .statusSuccess
        case .injectionSitePain, .injectionSiteRedness, .injectionSiteSwelling:
            return .statusWarning
        case .headache, .nausea, .fatigue, .insomnia:
            return .statusWarning
        case .heartPalpitations, .elevatedBloodPressure:
            return .statusError
        default:
            return .textSecondary
        }
    }

    var isPositive: Bool {
        switch self {
        case .increasedEnergy, .improvedMood, .betterSleep, .none:
            return true
        default:
            return false
        }
    }

    // MARK: - Grouped Side Effects for UI
    static var grouped: [(name: String, effects: [SideEffect])] {
        [
            ("Common", [.none, .fatigue, .headache, .nausea]),
            ("Gastrointestinal", [.nausea, .vomiting, .diarrhea, .constipation, .decreasedAppetite, .increasedAppetite]),
            ("Injection Site", [.injectionSitePain, .injectionSiteRedness, .injectionSiteSwelling]),
            ("Neurological", [.headache, .dizziness, .fatigue, .insomnia, .brainFog]),
            ("Mood", [.irritability, .anxiety, .moodSwings]),
            ("Physical", [.sweating, .nightSweats, .waterRetention, .muscleStiffness, .jointPain, .acne]),
            ("Cardiovascular", [.heartPalpitations, .elevatedBloodPressure]),
            ("Positive", [.increasedEnergy, .improvedMood, .betterSleep])
        ]
    }

    // Most common side effects for quick selection
    static var common: [SideEffect] {
        [.none, .nausea, .headache, .fatigue, .insomnia, .injectionSitePain]
    }
}

// MARK: - Side Effects Array Extension
extension Array where Element == SideEffect {
    var displayString: String {
        if isEmpty || (count == 1 && first == .none) {
            return "None"
        }
        return filter { $0 != .none }.map { $0.displayName }.joined(separator: ", ")
    }

    var rawValues: [String] {
        return map { $0.rawValue }
    }

    static func from(rawValues: [String]) -> [SideEffect] {
        return rawValues.compactMap { SideEffect(rawValue: $0) }
    }
}
