import Foundation
import UserNotifications
import AVFoundation

final class EmergencyNotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = EmergencyNotificationManager()

    static let emergencyCategoryID = "EMERGENCY_ALERT"
    static let openMapActionID     = "OPEN_MAP_ACTION"

    /// Called when user taps the notification — forwarded via this closure.
    var onNotificationTapped: ((EmergencyType) -> Void)?

    private override init() {
        super.init()
        // Set delegate immediately so foreground + tap callbacks work
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Setup

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()

        // First try requesting with criticalAlert.
        // If the app doesn't have the Critical Alerts entitlement, iOS ignores that flag
        // but still grants the other permissions — so notifications still work,
        // just without the lock-screen alarm bypass.
        center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if let error = error {
                print("[Notifications] Auth error: \(error.localizedDescription)")
                // Retry without criticalAlert
                center.requestAuthorization(options: [.alert, .sound, .badge]) { g, _ in
                    print("[Notifications] Fallback permission granted: \(g)")
                }
                return
            }
            print("[Notifications] Permission granted: \(granted)")
        }

        // Register the "Open Map" action button on the notification
        let openMapAction = UNNotificationAction(
            identifier: Self.openMapActionID,
            title: "Open Evacuation Map",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.emergencyCategoryID,
            actions: [openMapAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Fire notification

    func fireEmergencyNotification(type: EmergencyType) {
        let content = UNMutableNotificationContent()
        content.title = type.notificationTitle
        content.subtitle = "SafeExit Emergency"
        content.body = type.shortInstruction
        content.categoryIdentifier = Self.emergencyCategoryID
        content.userInfo = ["emergencyType": type.rawValue]

        // Use criticalAlert sound — plays even in silent/DND mode if entitlement is present.
        // If entitlement is missing iOS falls back to default sound behavior.
        content.sound = UNNotificationSound.defaultCritical
        content.interruptionLevel = .critical

        // Fire immediately (0.1s trigger — minimum allowed)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "emergency-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notifications] Schedule failed: \(error.localizedDescription)")
            } else {
                print("[Notifications] Emergency notification scheduled for type: \(type.rawValue)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Show notification banner + sound even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    // Handle notification tap or action button — navigate to map
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let rawType = userInfo["emergencyType"] as? String,
           let emergencyType = EmergencyType(rawValue: rawType) {
            DispatchQueue.main.async { [weak self] in
                self?.onNotificationTapped?(emergencyType)
            }
        }
        completionHandler()
    }
}
