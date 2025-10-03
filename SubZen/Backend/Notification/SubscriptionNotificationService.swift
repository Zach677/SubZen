//
//  SubscriptionNotificationService.swift
//  SubZen
//
//  Created by Star on 2025/9/30.
//

import Foundation
import UserNotifications

protocol SubscriptionNotificationScheduling {
    func triggerDebugExprirationPreview() async throws
}

class SubscriptionNotificationService: SubscriptionNotificationScheduling {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func triggerDebugExprirationPreview() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Expiring Soon!!"
        content.body = "Debug Preview: a subscription is about to renew."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "debug.subscription.expiry.preview",
            content: content,
            trigger: trigger
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            notificationCenter.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
