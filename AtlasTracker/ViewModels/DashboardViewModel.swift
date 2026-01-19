import Foundation
import Observation

// MARK: - Dashboard View Model
@Observable
final class DashboardViewModel {

    // MARK: - Observable Properties
    var todaysDoses: [TrackedCompound] = []
    var upcomingDoses: [TrackedCompound] = []
    var recentLogs: [DoseLog] = []
    var lowStockItems: [Inventory] = []
    var activeTracked: [TrackedCompound] = []
    var isLoading = false

    // MARK: - Computed Properties
    var hasDosesToday: Bool {
        return !todaysDoses.isEmpty
    }

    var hasUpcomingDoses: Bool {
        return !upcomingDoses.isEmpty
    }

    var hasLowStock: Bool {
        return !lowStockItems.isEmpty
    }

    var todaysCompletedCount: Int {
        // Count how many of today's doses have been logged today
        let today = Date().startOfDay
        return todaysDoses.filter { tracked in
            guard let lastDose = tracked.lastDoseDate else { return false }
            return Calendar.current.isDate(lastDose, inSameDayAs: today)
        }.count
    }

    var todaysTotalCount: Int {
        return todaysDoses.count
    }

    var todaysProgressPercentage: Double {
        guard todaysTotalCount > 0 else { return 0 }
        return Double(todaysCompletedCount) / Double(todaysTotalCount)
    }

    // MARK: - Private Properties
    private let coreDataManager = CoreDataManager.shared

    // MARK: - Initialization
    init() {
        loadData()
    }

    // MARK: - Load Data
    func loadData() {
        isLoading = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Fetch today's scheduled doses
            self.todaysDoses = self.fetchTodaysDoses()

            // Fetch upcoming doses (next 7 days)
            self.upcomingDoses = self.fetchUpcomingDoses()

            // Fetch recent logs
            self.recentLogs = self.fetchRecentLogs()

            // Fetch low stock items
            self.lowStockItems = self.coreDataManager.fetchLowStockItems()

            // Fetch active tracked compounds (for count display)
            self.activeTracked = self.coreDataManager.fetchTrackedCompounds(activeOnly: true)

            self.isLoading = false
        }
    }

    // MARK: - Fetch Today's Doses
    private func fetchTodaysDoses() -> [TrackedCompound] {
        let allTracked = coreDataManager.fetchTrackedCompounds(activeOnly: true)
        return allTracked.filter { $0.isDueToday }
            .sorted { (tc1, tc2) -> Bool in
                // Sort by notification time
                let time1 = tc1.notificationTime ?? Date.distantFuture
                let time2 = tc2.notificationTime ?? Date.distantFuture
                return time1 < time2
            }
    }

    // MARK: - Fetch Upcoming Doses
    private func fetchUpcomingDoses() -> [TrackedCompound] {
        let allTracked = coreDataManager.fetchTrackedCompounds(activeOnly: true)
        let tomorrow = Date().daysFromNow(1).startOfDay
        let nextWeek = Date().daysFromNow(7).endOfDay

        return allTracked.compactMap { tracked -> (TrackedCompound, Date)? in
            guard let nextDose = tracked.nextDoseDate(),
                  nextDose >= tomorrow && nextDose <= nextWeek else {
                return nil
            }
            return (tracked, nextDose)
        }
        .sorted { $0.1 < $1.1 }
        .map { $0.0 }
    }

    // MARK: - Fetch Recent Logs
    private func fetchRecentLogs() -> [DoseLog] {
        let startDate = Date().daysAgo(7)
        let endDate = Date()
        return Array(coreDataManager.fetchDoseLogs(from: startDate, to: endDate).prefix(10))
    }

    // MARK: - Check if Dose is Completed Today
    func isDoseCompletedToday(_ tracked: TrackedCompound) -> Bool {
        guard let lastDose = tracked.lastDoseDate else { return false }
        return Calendar.current.isDateInToday(lastDose)
    }

    // MARK: - Get Next Dose Time String
    func nextDoseTimeString(for tracked: TrackedCompound) -> String {
        guard let nextDose = tracked.nextDoseDate() else {
            return "Not scheduled"
        }

        if Calendar.current.isDateInToday(nextDose) {
            return nextDose.timeString
        } else if Calendar.current.isDateInTomorrow(nextDose) {
            return "Tomorrow, \(nextDose.timeString)"
        } else {
            return nextDose.shortDateString
        }
    }

    // MARK: - Get Recommended Site
    func recommendedSite(for tracked: TrackedCompound) -> String? {
        guard let compound = tracked.compound else { return nil }
        return InjectionSiteRecommendationService.shared.recommendNextSite(for: compound)
    }

    // MARK: - Skip Dose
    func skipDose(for tracked: TrackedCompound) {
        guard let compound = tracked.compound else { return }

        // Log a "skipped" dose with 0 amount and a note
        let _ = coreDataManager.logDose(
            compound: compound,
            dosageAmount: 0,
            dosageUnit: tracked.dosageUnit,
            timestamp: Date(),
            injectionSite: nil,
            notes: "Dose skipped"
        )

        // Update last dose date so the next dose shows correctly
        tracked.lastDoseDate = Date()
        coreDataManager.saveContext()

        // Reschedule notification for next dose
        if tracked.notificationEnabled {
            NotificationService.shared.scheduleDoseReminder(for: tracked)
        }

        // Reload data
        loadData()

        // Haptic feedback
        HapticManager.warning()
    }

    // MARK: - Quick Stats
    var weeklyDoseCount: Int {
        let startDate = Date().startOfWeek
        let endDate = Date()
        return coreDataManager.doseCount(from: startDate, to: endDate)
    }

    var activeCompoundsCount: Int {
        return activeTracked.count
    }

    var activeTrackedCompounds: [TrackedCompound] {
        return activeTracked
    }
}
