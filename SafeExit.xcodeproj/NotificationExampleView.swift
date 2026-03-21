//
//  NotificationExampleView.swift
//  SafeExit
//
//  Created on 3/22/26.
//

import SwiftUI

struct NotificationExampleView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var notificationTitle = "SafeExit Reminder"
    @State private var notificationBody = "Don't forget to check in!"
    @State private var delaySeconds: Double = 10
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Permission Status")) {
                    HStack {
                        Text("Notifications Authorized")
                        Spacer()
                        Image(systemName: notificationManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(notificationManager.isAuthorized ? .green : .red)
                    }
                    
                    if !notificationManager.isAuthorized {
                        Button("Request Permission") {
                            Task {
                                do {
                                    try await notificationManager.requestAuthorization()
                                } catch {
                                    alertMessage = "Failed to request permission: \(error.localizedDescription)"
                                    showingAlert = true
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Schedule Notification")) {
                    TextField("Title", text: $notificationTitle)
                    TextField("Message", text: $notificationBody)
                    
                    VStack(alignment: .leading) {
                        Text("Delay: \(Int(delaySeconds)) seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $delaySeconds, in: 5...300, step: 5)
                    }
                    
                    Button("Schedule Notification") {
                        Task {
                            do {
                                try await notificationManager.scheduleNotification(
                                    title: notificationTitle,
                                    body: notificationBody,
                                    timeInterval: delaySeconds
                                )
                                alertMessage = "Notification scheduled for \(Int(delaySeconds)) seconds from now!"
                                showingAlert = true
                            } catch {
                                alertMessage = "Failed to schedule: \(error.localizedDescription)"
                                showingAlert = true
                            }
                        }
                    }
                    .disabled(!notificationManager.isAuthorized)
                }
                
                Section(header: Text("Daily Notification")) {
                    Button("Schedule Daily 9:00 AM Reminder") {
                        Task {
                            do {
                                try await notificationManager.scheduleDailyNotification(
                                    title: "Good Morning!",
                                    body: "Time to check your SafeExit status",
                                    hour: 9,
                                    minute: 0
                                )
                                alertMessage = "Daily notification scheduled for 9:00 AM"
                                showingAlert = true
                            } catch {
                                alertMessage = "Failed to schedule: \(error.localizedDescription)"
                                showingAlert = true
                            }
                        }
                    }
                    .disabled(!notificationManager.isAuthorized)
                }
                
                Section(header: Text("Manage Notifications")) {
                    Button("View Pending Notifications") {
                        Task {
                            let pending = await notificationManager.getPendingNotifications()
                            alertMessage = "Pending notifications: \(pending.count)\n\n" +
                                pending.map { "• \($0.content.title)" }.joined(separator: "\n")
                            showingAlert = true
                        }
                    }
                    
                    Button("Cancel All Notifications", role: .destructive) {
                        notificationManager.cancelAllNotifications()
                        alertMessage = "All notifications cancelled"
                        showingAlert = true
                    }
                    
                    Button("Clear Badge") {
                        notificationManager.clearBadge()
                    }
                }
            }
            .navigationTitle("Local Notifications")
            .task {
                await notificationManager.checkAuthorizationStatus()
            }
            .alert("Notification Manager", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

#Preview {
    NotificationExampleView()
}
