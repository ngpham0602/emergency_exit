import UIKit
import FirebaseMessaging
import UserNotifications

/// AppDelegate handles APNs registration and Firebase Cloud Messaging.
/// This is required for push notifications to arrive when the app is closed or screen is off.
class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register for remote (push) notifications with APNs
        application.registerForRemoteNotifications()

        // Set FCM delegate
        Messaging.messaging().delegate = self

        // Subscribe to the emergency alerts topic — all devices receive these pushes
        Messaging.messaging().subscribe(toTopic: "emergency_alerts") { error in
            if let error = error {
                print("[FCM] Failed to subscribe to emergency_alerts topic: \(error.localizedDescription)")
            } else {
                print("[FCM] Subscribed to emergency_alerts topic")
            }
        }

        return true
    }

    // MARK: - APNs token → FCM

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Pass the APNs token to Firebase so FCM can send pushes to this device
        Messaging.messaging().apnsToken = deviceToken
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[APNs] Device token: \(tokenString)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs] Registration failed: \(error.localizedDescription)")
    }

    // MARK: - FCM delegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("[FCM] Token: \(fcmToken ?? "nil")")
    }
}
