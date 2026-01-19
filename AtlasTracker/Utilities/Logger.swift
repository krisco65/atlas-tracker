import Foundation
import os.log

// MARK: - Logger

/// Thread-safe logging utility that only outputs in DEBUG builds
enum Logger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.atlas.tracker"

    // MARK: - Log Categories

    private static let coreDataLog = OSLog(subsystem: subsystem, category: "CoreData")
    private static let networkLog = OSLog(subsystem: subsystem, category: "Network")
    private static let uiLog = OSLog(subsystem: subsystem, category: "UI")
    private static let generalLog = OSLog(subsystem: subsystem, category: "General")

    // MARK: - Log Levels

    /// Debug information - only visible in DEBUG builds
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        os_log(.debug, log: generalLog, "[%{public}@:%{public}d] %{public}@", filename, line, message)
        #endif
    }

    /// Informational messages
    static func info(_ message: String) {
        #if DEBUG
        os_log(.info, log: generalLog, "%{public}@", message)
        #endif
    }

    /// Warning messages - potential issues
    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        os_log(.error, log: generalLog, "⚠️ [%{public}@:%{public}d] %{public}@", filename, line, message)
        #endif
    }

    /// Error messages - something went wrong
    static func error(_ message: String, error: Error? = nil, file: String = #file, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        let errorDetail = error?.localizedDescription ?? "No error details"

        #if DEBUG
        os_log(.fault, log: generalLog, "❌ [%{public}@:%{public}d] %{public}@ - %{public}@", filename, line, message, errorDetail)
        #else
        // In production, we could send to crash reporting service
        os_log(.fault, log: generalLog, "Error: %{public}@", message)
        #endif
    }

    // MARK: - Category-Specific Logging

    /// Core Data specific logging
    static func coreData(_ message: String, error: Error? = nil) {
        #if DEBUG
        if let error = error {
            os_log(.error, log: coreDataLog, "CoreData: %{public}@ - %{public}@", message, error.localizedDescription)
        } else {
            os_log(.debug, log: coreDataLog, "CoreData: %{public}@", message)
        }
        #endif
    }

    /// Notification specific logging
    static func notification(_ message: String) {
        #if DEBUG
        os_log(.debug, log: generalLog, "Notification: %{public}@", message)
        #endif
    }

    /// Health Kit specific logging
    static func healthKit(_ message: String, error: Error? = nil) {
        #if DEBUG
        if let error = error {
            os_log(.error, log: generalLog, "HealthKit: %{public}@ - %{public}@", message, error.localizedDescription)
        } else {
            os_log(.debug, log: generalLog, "HealthKit: %{public}@", message)
        }
        #endif
    }

    /// Seed data specific logging
    static func seedData(_ message: String) {
        #if DEBUG
        os_log(.debug, log: coreDataLog, "SeedData: %{public}@", message)
        #endif
    }

    /// General logging for misc operations
    static func general(_ message: String) {
        #if DEBUG
        os_log(.debug, log: generalLog, "%{public}@", message)
        #endif
    }
}
