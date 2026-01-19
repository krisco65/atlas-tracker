import Foundation
import Observation

// MARK: - Compound Detail View Model
@Observable
final class CompoundDetailViewModel {

    // MARK: - Observable Properties
    var compound: Compound
    var recentDoseLogs: [DoseLog] = []
    var isTracked: Bool = false
    var trackedCompound: TrackedCompound?

    // Tracking Setup Properties
    var dosageAmount: String = ""
    var selectedUnit: DosageUnit = .mg
    var scheduleType: ScheduleType = .daily
    var scheduleInterval: String = "1"
    var selectedDays: Set<Int> = []
    var notificationEnabled: Bool = true
    var notificationTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()

    var isLoading = false
    var showTrackingSetup = false
    var errorMessage: String?

    // MARK: - Computed Properties
    var availableUnits: [DosageUnit] {
        return compound.supportedUnits
    }

    var requiresInjection: Bool {
        return compound.requiresInjection
    }

    var canSaveTracking: Bool {
        guard let amount = Double(dosageAmount), amount > 0 else { return false }

        switch scheduleType {
        case .everyXDays:
            guard let interval = Int(scheduleInterval), interval > 0 else { return false }
        case .specificDays:
            if selectedDays.isEmpty { return false }
        default:
            break
        }

        return true
    }

    var scheduleDescription: String {
        switch scheduleType {
        case .daily:
            return "Daily at \(notificationTime.timeString)"
        case .everyXDays:
            let interval = Int(scheduleInterval) ?? 1
            if interval == 3 || interval == 4 {
                return "Every 3.5 days (E3.5D)"
            }
            return "Every \(interval) days at \(notificationTime.timeString)"
        case .specificDays:
            let dayNames = selectedDays.sorted().compactMap { Weekday(rawValue: $0)?.shortName }
            return dayNames.joined(separator: ", ") + " at \(notificationTime.timeString)"
        case .asNeeded:
            return "As needed (no schedule)"
        }
    }

    var lastUsedSite: String? {
        return InjectionSiteRecommendationService.shared.lastUsedSiteDisplayName(for: compound)
    }

    var recommendedNextSite: String? {
        return InjectionSiteRecommendationService.shared.recommendNextSite(for: compound)
    }

    // MARK: - Private Properties
    private let coreDataManager = CoreDataManager.shared

    // MARK: - Initialization
    init(compound: Compound) {
        self.compound = compound
        loadData()
    }

    // MARK: - Load Data
    func loadData() {
        isTracked = compound.isTracked
        trackedCompound = compound.trackedCompound
        recentDoseLogs = coreDataManager.fetchDoseLogs(for: compound, limit: 10)

        // Pre-fill tracking setup if already tracked
        if let tracked = trackedCompound {
            dosageAmount = String(tracked.dosageAmount)
            selectedUnit = tracked.dosageUnit
            scheduleType = tracked.scheduleType
            scheduleInterval = String(tracked.scheduleInterval)
            selectedDays = Set(tracked.scheduleDays)
            notificationEnabled = tracked.notificationEnabled
            notificationTime = tracked.notificationTime ?? Date()
        } else {
            // Set defaults
            selectedUnit = compound.defaultUnit
        }
    }

    // MARK: - Toggle Favorite
    func toggleFavorite() {
        coreDataManager.toggleFavorite(compound: compound)
        // @Observable automatically tracks property changes
    }

    // MARK: - Start Tracking
    func startTracking() {
        guard canSaveTracking else {
            errorMessage = "Please fill in all required fields"
            return
        }

        guard let amount = Double(dosageAmount) else {
            errorMessage = "Invalid dosage amount"
            return
        }

        isLoading = true
        errorMessage = nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let interval: Int16? = self.scheduleType == .everyXDays
                ? Int16(self.scheduleInterval) ?? 1
                : nil

            let days: [Int]? = self.scheduleType == .specificDays
                ? Array(self.selectedDays)
                : nil

            let tracked = self.coreDataManager.startTracking(
                compound: self.compound,
                dosageAmount: amount,
                dosageUnit: self.selectedUnit,
                scheduleType: self.scheduleType,
                scheduleInterval: interval,
                scheduleDays: days,
                notificationEnabled: self.notificationEnabled,
                notificationTime: self.notificationTime
            )

            // Schedule notifications
            if self.notificationEnabled {
                NotificationService.shared.scheduleRecurringNotifications(for: tracked)
            }

            self.isTracked = true
            self.trackedCompound = tracked
            self.isLoading = false
            self.showTrackingSetup = false
        }
    }

    // MARK: - Stop Tracking
    func stopTracking() {
        guard let tracked = trackedCompound else { return }

        // Cancel notifications
        NotificationService.shared.cancelNotifications(for: compound)

        coreDataManager.deleteTracking(tracked)
        isTracked = false
        trackedCompound = nil
    }

    // MARK: - Update Tracking
    func updateTracking() {
        guard canSaveTracking else {
            errorMessage = "Please fill in all required fields"
            return
        }

        guard let tracked = trackedCompound,
              let amount = Double(dosageAmount) else {
            errorMessage = "Invalid tracking configuration"
            return
        }

        isLoading = true
        errorMessage = nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Update existing TrackedCompound in place (preserves all history)
            tracked.dosageAmount = amount
            tracked.dosageUnitRaw = self.selectedUnit.rawValue
            tracked.scheduleTypeRaw = self.scheduleType.rawValue

            if self.scheduleType == .everyXDays {
                tracked.scheduleInterval = Int16(self.scheduleInterval) ?? 1
            }

            if self.scheduleType == .specificDays {
                tracked.scheduleDaysRaw = Array(self.selectedDays).map { Int16($0) }
            }

            tracked.notificationEnabled = self.notificationEnabled
            tracked.notificationTime = self.notificationTime

            self.coreDataManager.saveContext()

            // Reschedule notifications
            NotificationService.shared.cancelNotifications(for: self.compound)
            if self.notificationEnabled {
                NotificationService.shared.scheduleRecurringNotifications(for: tracked)
            }

            self.isLoading = false
            self.showTrackingSetup = false

            // Haptic feedback for success
            HapticManager.success()
        }
    }

    // MARK: - Toggle Day Selection
    func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }

    // MARK: - Delete Compound (Custom Only)
    func deleteCompound() -> Bool {
        guard compound.isCustom else { return false }

        // Cancel any notifications
        NotificationService.shared.cancelNotifications(for: compound)

        coreDataManager.deleteCompound(compound)
        return true
    }

    // MARK: - Dose History Stats
    var totalDosesLogged: Int {
        return compound.totalDosesLogged
    }

    var dosesSinceStarting: Int {
        guard let tracked = trackedCompound,
              let startDate = tracked.startDate else {
            return totalDosesLogged
        }

        return recentDoseLogs.filter { ($0.timestamp ?? Date()) >= startDate }.count
    }
}
