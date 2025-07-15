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

    private let userDefaults = UserDefaults.standard
    private let hasRequestedPermissionKey = "HasRequestedNotificationPermission"

    private init() {
        loadPermissionRequestStatus()
        checkCurrentPermissionStatus()
    }

    // MARK: - Public Methods

    /// 检查是否需要请求通知权限（首次启动）
    func shouldRequestPermission() -> Bool {
        !hasRequestedPermission && permissionStatus == .notDetermined
    }

    /// 请求通知权限
    func requestNotificationPermission() async {
        guard !hasRequestedPermission else { return }

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )

            await MainActor.run {
                self.hasRequestedPermission = true
                self.permissionStatus = granted ? .authorized : .denied
                self.savePermissionRequestStatus()
            }

            print("Notification permission granted: \(granted)")
        } catch {
            await MainActor.run {
                self.hasRequestedPermission = true
                self.permissionStatus = .denied
                self.savePermissionRequestStatus()
            }

            print("Error requesting notification permission: \(error)")
        }
    }

    /// 检查当前通知权限状态
    func checkCurrentPermissionStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.permissionStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Private Methods

    private func loadPermissionRequestStatus() {
        hasRequestedPermission = userDefaults.bool(forKey: hasRequestedPermissionKey)
    }

    private func savePermissionRequestStatus() {
        userDefaults.set(hasRequestedPermission, forKey: hasRequestedPermissionKey)
    }
}
