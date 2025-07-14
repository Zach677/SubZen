//
//  SubZenApp.swift
//  SubZen
//
//  Created by Star on 2025/3/29.
//

import SwiftUI

struct SubZenApp: App {
    @StateObject private var notificationService = NotificationPermissionService.shared

    var body: some Scene {
        WindowGroup {
            SubscriptionListView()
                .onAppear {
                    requestNotificationPermissionIfNeeded()
                }
        }
    }

    private func requestNotificationPermissionIfNeeded() {
        if notificationService.shouldRequestPermission() {
            Task {
                await notificationService.requestNotificationPermission()
            }
        }
    }
}
