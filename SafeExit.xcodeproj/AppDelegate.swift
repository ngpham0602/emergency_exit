//
//  AppDelegate.swift
//  SafeExit
//
//  Created on 3/22/26.
//
//  Use this if you need to handle notification responses
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when notification is received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle the notification tap here
        print("📱 User tapped notification: \(response.notification.request.identifier)")
        print("📱 User info: \(userInfo)")
        
        // You can navigate to specific screens or perform actions here
        // For example, post a notification to update your UI:
        // NotificationCenter.default.post(name: NSNotification.Name("HandleNotificationTap"), object: userInfo)
        
        completionHandler()
    }
}
