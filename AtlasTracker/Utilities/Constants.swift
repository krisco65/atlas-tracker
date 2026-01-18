import Foundation

struct AppConstants {
    // MARK: - App Info
    static let appName = "Atlas Tracker"
    static let appVersion = "1.0.0"

    // MARK: - Core Data
    static let coreDataModelName = "AtlasTracker"

    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredWeightUnit = "preferredWeightUnit"
        static let biometricEnabled = "biometricEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let lastSeedDataVersion = "lastSeedDataVersion"
    }

    // MARK: - Notification Identifiers
    struct NotificationIdentifiers {
        static let doseReminder = "doseReminder"
        static let lowInventory = "lowInventory"
        static let categoryPrefix = "atlas.notification."
    }

    // MARK: - Notification Actions
    struct NotificationActions {
        static let logNow = "LOG_NOW"
        static let snooze = "SNOOZE"
        static let skip = "SKIP"
    }

    // MARK: - Snooze Duration
    static let snoozeDurationMinutes = 30

    // MARK: - Animation Durations
    struct Animation {
        static let quick: Double = 0.2
        static let standard: Double = 0.3
        static let slow: Double = 0.5
    }

    // MARK: - Layout
    struct Layout {
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16
    }

    // MARK: - Inventory
    struct Inventory {
        static let defaultLowStockThreshold: Int16 = 2
    }

    // MARK: - Injection Site Rotation
    struct InjectionRotation {
        /// Number of past injections to consider for recommendations
        static let historyLookback = 20

        /// Number of past injections for analytics/stats view
        static let statsLookback = 50

        /// Weight decay rate for time-weighted scoring (higher = faster decay)
        static let timeDecayFactor: Double = 1.0
    }

    // MARK: - Seed Data
    static let seedDataVersion = 2  // Bumped to add GLOW, MOTS-C, Retatrutide
}

// MARK: - Weight Unit
enum WeightUnit: String, CaseIterable, Codable {
    case lbs = "lbs"
    case kg = "kg"

    var displayName: String {
        switch self {
        case .lbs: return "Pounds (lbs)"
        case .kg: return "Kilograms (kg)"
        }
    }

    var shortName: String {
        return rawValue
    }

    func convert(to unit: WeightUnit, value: Double) -> Double {
        if self == unit { return value }
        switch (self, unit) {
        case (.lbs, .kg): return value * 0.453592
        case (.kg, .lbs): return value / 0.453592
        default: return value
        }
    }
}
