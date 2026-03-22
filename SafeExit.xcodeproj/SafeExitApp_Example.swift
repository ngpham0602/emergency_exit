//
//  SafeExitApp.swift
//  SafeExit
//
//  Example of how to integrate the AppDelegate with your SwiftUI App
//

import SwiftUI

@main
struct SafeExitApp: App {
    // Connect the AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// If you already have a main App file, just add this line to it:
// @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
