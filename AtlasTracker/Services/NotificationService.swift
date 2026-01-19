import Foundation
import UserNotifications

// MARK: - Notification Service
final class NotificationService: ObservableObject {

    // MARK: - Singleton
    static let shared = NotificationService()

    // MARK: - Published Properties
    @Published var isAuthorized = false

    // MARK: - Notification Center
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            if granted {
                await registerNotificationCategories()
            }
            return granted
        } catch {
            Logger.error("Notification authorization error", error: error)
            return false
        }
    }

    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Notification Categories & Actions

    private func registerNotificationCategories() async {
        let logAction = UNNotificationAction(
            identifier: AppConstants.NotificationActions.logNow,
            title: "Log Now",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: AppConstants.NotificationActions.snooze,
            title: "Snooze 30 min",
            options: []
        )

        let skipAction = UNNotificationAction(
            identifier: AppConstants.NotificationActions.skip,
            title: "Skip",
            options: [.destructive]
        )

        let doseCategory = UNNotificationCategory(
            identifier: AppConstants.NotificationIdentifiers.doseReminder,
            actions: [logAction, snoozeAction, skipAction],
            intentIdentifiers: [],
            options: []
        )

        let lowInventoryCategory = UNNotificationCategory(
            identifier: AppConstants.NotificationIdentifiers.lowInventory,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([doseCategory, lowInventoryCategory])
    }

    // MARK: - Discreet Mode Check
    private var isDiscreetMode: Bool {
        UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.discreetNotifications)
    }

    // MARK: - Schedule Dose Reminder

    func scheduleDoseReminder(for trackedCompound: TrackedCompound) {
        guard trackedCompound.notificationEnabled,
              let compound = trackedCompound.compound,
              let compoundName = compound.name else {
            return
        }

        // Cancel existing notifications for this compound
        cancelNotifications(for: compound)

        // Calculate next dose date
        guard let nextDoseDate = trackedCompound.nextDoseDate() else {
            return
        }

        // Create notification content based on discreet mode
        let content = UNMutableNotificationContent()

        if isDiscreetMode {
            content.title = "Dose Reminder"
            content.body = "Time for your scheduled dose"
        } else {
            content.title = "Time for \(compoundName)"
            content.body = buildNotificationBody(for: trackedCompound)
        }

        content.sound = .default
        content.categoryIdentifier = AppConstants.NotificationIdentifiers.doseReminder

        // Add compound ID to userInfo for handling
        content.userInfo = [
            "compoundId": compound.id?.uuidString ?? "",
            "trackedCompoundId": trackedCompound.id?.uuidString ?? ""
        ]

        // Create trigger
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: nextDoseDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // Create request
        let identifier = notificationIdentifier(for: compound)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Schedule
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.error("Error scheduling notification", error: error)
            } else {
                Logger.notification("Scheduled notification for \(compoundName) at \(nextDoseDate)")
            }
        }
    }

    private func buildNotificationBody(for trackedCompound: TrackedCompound) -> String {
        // If discreet mode, return generic body
        if isDiscreetMode {
            return "Time for your scheduled dose"
        }

        var body = trackedCompound.dosageString

        // Add recommended injection site if applicable
        if let compound = trackedCompound.compound,
           compound.requiresInjection {
            let recommendedSite = InjectionSiteRecommendationService.shared.recommendNextSite(for: compound)
            if let siteName = recommendedSite {
                body += " - \(siteName)"
            }
        }

        return body
    }

    // MARK: - Schedule Recurring Notifications

    func scheduleRecurringNotifications(for trackedCompound: TrackedCompound, daysAhead: Int = 7) {
        guard trackedCompound.notificationEnabled,
              let compound = trackedCompound.compound else {
            return
        }

        // Cancel existing
        cancelNotifications(for: compound)

        // Schedule for next X days
        var currentDate = Date()
        var scheduledCount = 0
        let maxNotifications = 64 // iOS limit

        while scheduledCount < daysAhead && scheduledCount < maxNotifications {
            if let nextDose = trackedCompound.nextDoseDate(from: currentDate) {
                scheduleNotification(for: trackedCompound, at: nextDose, index: scheduledCount)
                currentDate = nextDose.daysFromNow(1)
                scheduledCount += 1
            } else {
                break
            }
        }
    }

    private func scheduleNotification(for trackedCompound: TrackedCompound, at date: Date, index: Int) {
        guard let compound = trackedCompound.compound,
              let compoundName = compound.name else {
            return
        }

        let content = UNMutableNotificationContent()

        if isDiscreetMode {
            content.title = "Dose Reminder"
            content.body = "Time for your scheduled dose"
        } else {
            content.title = "Time for \(compoundName)"
            content.body = buildNotificationBody(for: trackedCompound)
        }

        content.sound = .default
        content.categoryIdentifier = AppConstants.NotificationIdentifiers.doseReminder
        content.userInfo = [
            "compoundId": compound.id?.uuidString ?? "",
            "trackedCompoundId": trackedCompound.id?.uuidString ?? ""
        ]

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = "\(notificationIdentifier(for: compound))_\(index)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request)
    }

    // MARK: - Snooze Notification

    func snoozeNotification(for compound: Compound) {
        guard let trackedCompound = compound.trackedCompound else { return }

        let snoozeDate = Date().addingTimeInterval(TimeInterval(AppConstants.snoozeDurationMinutes * 60))

        let content = UNMutableNotificationContent()

        if isDiscreetMode {
            content.title = "Dose Reminder"
            content.body = "Time for your scheduled dose"
        } else {
            content.title = "Reminder: \(compound.name ?? "Dose")"
            content.body = trackedCompound.dosageString
        }

        content.sound = .default
        content.categoryIdentifier = AppConstants.NotificationIdentifiers.doseReminder

        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: snoozeDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = "\(notificationIdentifier(for: compound))_snooze"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request)
    }

    // MARK: - Low Inventory Alert

    func scheduleLowInventoryAlert(for compound: Compound, vialCount: Int) {
        guard let compoundName = compound.name else { return }

        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert"
        content.body = "\(compoundName): Only \(vialCount) vial\(vialCount == 1 ? "" : "s") remaining. Consider reordering."
        content.sound = .default
        content.categoryIdentifier = AppConstants.NotificationIdentifiers.lowInventory

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let identifier = "\(AppConstants.NotificationIdentifiers.categoryPrefix)inventory_\(compound.id?.uuidString ?? "")"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request)
    }

    // MARK: - Cancel Notifications

    func cancelNotifications(for compound: Compound) {
        let baseIdentifier = notificationIdentifier(for: compound)

        // Get all pending notifications
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(baseIdentifier) }
                .map { $0.identifier }

            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private func notificationIdentifier(for compound: Compound) -> String {
        return "\(AppConstants.NotificationIdentifiers.categoryPrefix)\(compound.id?.uuidString ?? "")"
    }

    // MARK: - Reschedule All Active Notifications

    func rescheduleAllNotifications() {
        let trackedCompounds = CoreDataManager.shared.fetchTrackedCompounds(activeOnly: true)

        for tracked in trackedCompounds {
            if tracked.notificationEnabled {
                scheduleRecurringNotifications(for: tracked)
            }
        }
    }

    // MARK: - Get Pending Notifications Count

    func getPendingNotificationsCount(completion: @escaping (Int) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            completion(requests.count)
        }
    }
}
