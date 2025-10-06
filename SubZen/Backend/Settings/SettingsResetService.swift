//
//  SettingsResetService.swift
//  SubZen
//
//  Created by Star on 2025/9/12.
//

import Foundation

protocol SubscriptionManaging {
    func eraseAll()
}

protocol NotificationPermissionResetting {
    func resetRequestTracking()
}

final class SettingsResetService {
    enum Scope {
        case settingsOnly
        case full
    }

    static let shared = SettingsResetService()

    private let subscriptionManager: SubscriptionManaging
    private let notificationService: NotificationPermissionResetting
    private let notificationCenter: NotificationCenter

    init(
        subscriptionManager: SubscriptionManaging = SubscriptionManager.shared,
        notificationService: NotificationPermissionResetting = NotificationPermissionService.shared,
        notificationCenter: NotificationCenter = .default
    ) {
        self.subscriptionManager = subscriptionManager
        self.notificationService = notificationService
        self.notificationCenter = notificationCenter
    }

    func resetAll(scope: Scope = .full, completion: ((Result<Void, Error>) -> Void)? = nil) {
        let performReset = { [weak self] in
            guard let self else { return }

            notificationService.resetRequestTracking()

            if scope == .full {
                subscriptionManager.eraseAll()
            }

            notificationCenter.post(name: .settingsDidReset, object: nil)
            completion?(.success(()))
        }

        if Thread.isMainThread {
            performReset()
        } else {
            DispatchQueue.main.async {
                performReset()
            }
        }
    }
}

extension SubscriptionManager: SubscriptionManaging {}

extension NotificationPermissionService: NotificationPermissionResetting {}
