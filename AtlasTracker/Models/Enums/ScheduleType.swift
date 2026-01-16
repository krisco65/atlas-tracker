import Foundation

enum ScheduleType: String, CaseIterable, Codable {
    case daily = "daily"
    case everyXDays = "everyXDays"
    case specificDays = "specificDays"
    case asNeeded = "asNeeded"

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .everyXDays: return "Every X Days"
        case .specificDays: return "Specific Days"
        case .asNeeded: return "As Needed"
        }
    }

    var requiresInterval: Bool {
        return self == .everyXDays
    }

    var requiresDaySelection: Bool {
        return self == .specificDays
    }
}

enum Weekday: Int, CaseIterable, Codable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

// Schedule helper for E3.5D alternating pattern
struct ScheduleInterval {
    let days: Double

    // For fractional days like 3.5, returns alternating pattern
    var alternatingPattern: [Int] {
        let wholeDays = Int(days)
        let fraction = days - Double(wholeDays)

        if fraction == 0 {
            return [wholeDays]
        } else if fraction == 0.5 {
            // E3.5D = alternating 3 and 4 days
            return [wholeDays, wholeDays + 1]
        } else {
            // For other fractions, round to nearest
            return [Int(days.rounded())]
        }
    }

    var displayString: String {
        if days == 1 {
            return "Daily"
        } else if days == Double(Int(days)) {
            return "Every \(Int(days)) days"
        } else {
            return "Every \(days) days"
        }
    }
}
