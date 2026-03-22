//
//  NotificationManager.swift
//  SafeExit
//
//  Created on 3/22/26.
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {}
    
    /// Request notification permission from the user
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            throw error
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    /// Schedule a local notification
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body/message
    ///   - timeInterval: Seconds from now to deliver the notification
    ///   - identifier: Unique identifier for this notification
    func scheduleNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        identifier: String = UUID().uuidString
    ) async throws {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Create trigger (time-based)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        let center = UNUserNotificationCenter.current()
        try await center.add(request)
        
        print("✅ Notification scheduled: \(title) in \(timeInterval) seconds")
    }
    
    /// Schedule a repeating daily notification
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body
    ///   - hour: Hour of day (0-23)
    ///   - minute: Minute of hour (0-59)
    ///   - identifier: Unique identifier
    func scheduleDailyNotification(
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        identifier: String = UUID().uuidString
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Create date components for daily trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        let center = UNUserNotificationCenter.current()
        try await center.add(request)
        
        print("✅ Daily notification scheduled: \(title) at \(hour):\(minute)")
    }
    
    /// Cancel a specific notification
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
        print("🗑️ Cancelled notification: \(identifier)")
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ All notifications cancelled")
    }
    
    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    /// Clear badge count
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
