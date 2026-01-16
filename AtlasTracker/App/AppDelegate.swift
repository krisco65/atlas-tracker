import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case AppConstants.NotificationActions.logNow:
            handleLogNow(userInfo: userInfo)

        case AppConstants.NotificationActions.snooze:
            handleSnooze(userInfo: userInfo)

        case AppConstants.NotificationActions.skip:
            // Skip action - just dismiss, no logging
            break

        case UNNotificationDefaultActionIdentifier:
            // User tapped notification - open app to log
            handleLogNow(userInfo: userInfo)

        default:
            break
        }

        completionHandler()
    }

    // MARK: - Action Handlers

    private func handleLogNow(userInfo: [AnyHashable: Any]) {
        guard let compoundIdString = userInfo["compoundId"] as? String,
              let compoundId = UUID(uuidString: compoundIdString),
              let compound = CoreDataManager.shared.fetchCompound(by: compoundId) else {
            return
        }

        // Log the dose with default values
        let viewModel = DoseLogViewModel(preselectedCompound: compound)
        _ = viewModel.quickLog(for: compound)

        // Post notification for UI update
        NotificationCenter.default.post(name: .doseLogged, object: nil, userInfo: ["compoundId": compoundId])
    }

    private func handleSnooze(userInfo: [AnyHashable: Any]) {
        guard let compoundIdString = userInfo["compoundId"] as? String,
              let compoundId = UUID(uuidString: compoundIdString),
              let compound = CoreDataManager.shared.fetchCompound(by: compoundId) else {
            return
        }

        NotificationService.shared.snoozeNotification(for: compound)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let doseLogged = Notification.Name("doseLogged")
}
