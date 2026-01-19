import Foundation
import UIKit

// MARK: - Data Export Service
/// Service for exporting user data to various formats
final class DataExportService {

    // MARK: - Singleton
    static let shared = DataExportService()

    private let coreDataManager = CoreDataManager.shared
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private init() {}

    // MARK: - Export Dose Logs to CSV

    /// Export all dose logs to a CSV file
    /// - Returns: URL to the generated CSV file, or nil if export failed
    func exportDoseLogsToCSV() -> URL? {
        let doseLogs = coreDataManager.fetchDoseLogs(from: Date.distantPast, to: Date())

        guard !doseLogs.isEmpty else {
            Logger.general("No dose logs to export")
            return nil
        }

        // Build CSV content
        var csvContent = buildCSVHeader()
        csvContent += buildMetadataHeader(totalLogs: doseLogs.count)
        csvContent += buildDoseLogRows(doseLogs)

        // Write to file
        return writeToFile(content: csvContent, filename: "atlas_dose_history")
    }

    /// Export dose logs for a specific compound
    func exportDoseLogsToCSV(for compound: Compound) -> URL? {
        let doseLogs = coreDataManager.fetchDoseLogs(for: compound)

        guard !doseLogs.isEmpty else {
            Logger.general("No dose logs to export for \(compound.name ?? "compound")")
            return nil
        }

        var csvContent = buildCSVHeader()
        csvContent += buildMetadataHeader(totalLogs: doseLogs.count, compoundName: compound.name)
        csvContent += buildDoseLogRows(doseLogs)

        let safeName = (compound.name ?? "compound").replacingOccurrences(of: " ", with: "_").lowercased()
        return writeToFile(content: csvContent, filename: "atlas_\(safeName)_history")
    }

    /// Export dose logs within a date range
    func exportDoseLogsToCSV(from startDate: Date, to endDate: Date) -> URL? {
        let doseLogs = coreDataManager.fetchDoseLogs(from: startDate, to: endDate)

        guard !doseLogs.isEmpty else {
            Logger.general("No dose logs to export for date range")
            return nil
        }

        var csvContent = buildCSVHeader()
        csvContent += buildMetadataHeader(totalLogs: doseLogs.count, startDate: startDate, endDate: endDate)
        csvContent += buildDoseLogRows(doseLogs)

        let startStr = dateFormatter.string(from: startDate)
        let endStr = dateFormatter.string(from: endDate)
        return writeToFile(content: csvContent, filename: "atlas_history_\(startStr)_to_\(endStr)")
    }

    // MARK: - CSV Building Helpers

    private func buildCSVHeader() -> String {
        return "Date,Time,Compound,Category,Dosage,Unit,Injection Site,Side Effects,Notes\n"
    }

    private func buildMetadataHeader(totalLogs: Int, compoundName: String? = nil, startDate: Date? = nil, endDate: Date? = nil) -> String {
        var metadata = "# Atlas Tracker Export\n"
        metadata += "# Export Date: \(dateFormatter.string(from: Date())) \(timeFormatter.string(from: Date()))\n"
        metadata += "# App Version: \(AppConstants.appVersion)\n"
        metadata += "# Total Records: \(totalLogs)\n"

        if let name = compoundName {
            metadata += "# Compound: \(name)\n"
        }

        if let start = startDate, let end = endDate {
            metadata += "# Date Range: \(dateFormatter.string(from: start)) to \(dateFormatter.string(from: end))\n"
        }

        metadata += "#\n"
        return metadata
    }

    private func buildDoseLogRows(_ doseLogs: [DoseLog]) -> String {
        var rows = ""

        for log in doseLogs {
            let date = log.timestamp.map { dateFormatter.string(from: $0) } ?? ""
            let time = log.timestamp.map { timeFormatter.string(from: $0) } ?? ""
            let compoundName = escapeCSV(log.compound?.name ?? "Unknown")
            let category = log.compound?.category.displayName ?? ""
            let dosage = log.dosageAmount > 0 ? String(format: "%.2f", log.dosageAmount) : "0"
            let unit = log.dosageUnit.displayName
            let injectionSite = escapeCSV(log.injectionSiteDisplayName ?? "")
            let sideEffects = escapeCSV(log.sideEffectsString ?? "")
            let notes = escapeCSV(log.notes ?? "")

            rows += "\(date),\(time),\(compoundName),\(category),\(dosage),\(unit),\(injectionSite),\(sideEffects),\(notes)\n"
        }

        return rows
    }

    private func escapeCSV(_ value: String) -> String {
        // If value contains comma, quote, or newline, wrap in quotes and escape internal quotes
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    private func writeToFile(content: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let timestamp = dateFormatter.string(from: Date())
        let fileURL = tempDir.appendingPathComponent("\(filename)_\(timestamp).csv")

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            Logger.general("CSV exported to: \(fileURL.path)")
            return fileURL
        } catch {
            Logger.error("Failed to write CSV file", error: error)
            return nil
        }
    }

    // MARK: - Export Summary Statistics

    /// Generate a summary report of tracking data
    func generateSummaryReport() -> String {
        let allCompounds = coreDataManager.fetchAllCompounds()
        let trackedCompounds = coreDataManager.fetchTrackedCompounds(activeOnly: true)
        let totalDoseLogs = coreDataManager.doseCount(from: Date.distantPast, to: Date())

        // Calculate date range
        let allLogs = coreDataManager.fetchDoseLogs(from: Date.distantPast, to: Date())
        let oldestLog = allLogs.last?.timestamp
        let newestLog = allLogs.first?.timestamp

        var report = """
        ═══════════════════════════════════════
        ATLAS TRACKER SUMMARY REPORT
        Generated: \(dateFormatter.string(from: Date())) \(timeFormatter.string(from: Date()))
        ═══════════════════════════════════════

        OVERVIEW
        ────────
        Total Compounds in Library: \(allCompounds.count)
        Currently Tracking: \(trackedCompounds.count)
        Total Doses Logged: \(totalDoseLogs)

        """

        if let oldest = oldestLog, let newest = newestLog {
            report += """
            Tracking Since: \(dateFormatter.string(from: oldest))
            Last Log: \(dateFormatter.string(from: newest))

            """
        }

        report += """

        ACTIVE TRACKING
        ───────────────
        """

        for tracked in trackedCompounds {
            let name = tracked.compound?.name ?? "Unknown"
            let dosage = tracked.dosageString
            let schedule = tracked.scheduleDescription

            report += """

            • \(name)
              Dosage: \(dosage)
              Schedule: \(schedule)
            """
        }

        return report
    }
}

