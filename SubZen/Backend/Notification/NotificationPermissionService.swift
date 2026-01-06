//
//  NotificationPermissionService.swift
//  SubZen
//
//  Created by Star on 2025/6/18.
//

import Foundation
import UserNotifications

class NotificationPermissionService: ObservableObject {
    static let shared = NotificationPermissionService()

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var hasRequestedPermission = false
    @Published private(set) var isRequestingPermission = false

    private let userDefaults = UserDefaults.standard
    private let hasRequestedPermissionKey = "HasRequestedNotificationPermission"

    private init() {
        loadPermissionRequestStatus()
        checkCurrentPermissionStatus()
    }

    // MARK: - Public Methods

    /// Returns whether we should prompt for notification permission (first launch).
    func shouldRequestPermission() -> Bool {
        !hasRequestedPermission && permissionStatus == .notDetermined
    }

    /// Requests notification permission.
    func requestNotificationPermission() async {
        let shouldRequest = await MainActor.run { () -> Bool in
            guard !self.hasRequestedPermission, !self.isRequestingPermission else { return false }
            self.isRequestingPermission = true
            return true
        }

        guard shouldRequest else { return }

        defer {
            Task { @MainActor in
                self.isRequestingPermission = false
            }
        }

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )

            await MainActor.run {
                self.hasRequestedPermission = true
                self.permissionStatus = granted ? .authorized : .denied
                self.savePermissionRequestStatus()
            }

            #if DEBUG
                print("Notification permission granted: \(granted)")
            #endif
        } catch {
            await MainActor.run {
                self.hasRequestedPermission = true
                self.permissionStatus = .denied
                self.savePermissionRequestStatus()
            }

            #if DEBUG
                print("Error requesting notification permission: \(error)")
            #endif
        }
    }

    /// Checks the current notification permission status.
    func checkCurrentPermissionStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.permissionStatus = settings.authorizationStatus
            }
        }
    }

    /// Reset local tracking flags so the next launch behaves like fresh install
    func resetRequestTracking() {
        hasRequestedPermission = false
        userDefaults.removeObject(forKey: hasRequestedPermissionKey)
        checkCurrentPermissionStatus()
    }

    // MARK: - Private Methods

    private func loadPermissionRequestStatus() {
        hasRequestedPermission = userDefaults.bool(forKey: hasRequestedPermissionKey)
    }

    private func savePermissionRequestStatus() {
        userDefaults.set(hasRequestedPermission, forKey: hasRequestedPermissionKey)
    }
}
