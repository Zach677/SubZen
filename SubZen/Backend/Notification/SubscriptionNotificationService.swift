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
    func scheduleNotifications(for subscription: Subscription) async throws
    func cancelAllScheduledNotifications() async
    func cancelNotifications(for subscription: Subscription) async
}

class SubscriptionNotificationService: SubscriptionNotificationScheduling {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - Debug Preview

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

    // MARK: - Custom Reminder Scheduling

    /// Schedule notifications for a subscription based on its reminder intervals
    func scheduleNotifications(for subscription: Subscription) async throws {
        // Get current notification settings to check if we have permission
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("Notification permission not granted, skipping scheduling for '\(subscription.name)'")
            return
        }

        let remainingDays = subscription.remainingDays
        let nextBillingDate = subscription.getNextBillingDate()

        // Only schedule notifications for subscriptions that will expire in the future
        guard remainingDays > 0 else {
            print("Subscription '\(subscription.name)' has already expired or expires today, skipping notification")
            return
        }

        // Schedule notifications for each reminder interval
        for daysBefore in subscription.reminderIntervals {
            guard remainingDays >= daysBefore else {
                print("Subscription '\(subscription.name)' expires in \(remainingDays) days, skipping \(daysBefore)-day reminder")
                continue
            }

            let notificationDate = Calendar.current.date(
                byAdding: .day,
                value: -daysBefore,
                to: nextBillingDate
            ) ?? nextBillingDate

            // Only schedule if notification date is in the future
            guard notificationDate > Date() else {
                print("Notification date for \(daysBefore)-day reminder is in the past, skipping")
                continue
            }

            let identifier = "\(subscription.id.uuidString).expiry.\(daysBefore)days"
            let content = createNotificationContent(for: subscription, daysBefore: daysBefore)
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate), repeats: false)

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try await notificationCenter.add(request)
            print("Scheduled \(daysBefore)-day reminder for '\(subscription.name)'")
        }
    }

    /// Create notification content for a subscription
    private func createNotificationContent(for subscription: Subscription, daysBefore: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        switch daysBefore {
        case 1:
            content.title = "Subscription Renews Tomorrow!"
            content.body = "\"\(subscription.name)\" (\(subscription.formattedPrice)) will renew tomorrow."
        case 3:
            content.title = "Subscription Renews in 3 Days"
            content.body = "\"\(subscription.name)\" (\(subscription.formattedPrice)) will renew in 3 days."
        case 7:
            content.title = "Subscription Renews Next Week"
            content.body = "\"\(subscription.name)\" (\(subscription.formattedPrice)) will renew next week."
        case 14:
            content.title = "Subscription Renews in 2 Weeks"
            content.body = "\"\(subscription.name)\" (\(subscription.formattedPrice)) will renew in 2 weeks."
        default:
            content.title = "Subscription Reminder"
            content.body = "\"\(subscription.name)\" (\(subscription.formattedPrice)) will renew in \(daysBefore) days."
        }

        content.sound = .default
        content.userInfo = ["subscriptionId": subscription.id.uuidString]

        return content
    }

    // MARK: - Notification Management

    /// Cancel all scheduled subscription notifications
    func cancelAllScheduledNotifications() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let subscriptionIdentifiers = pendingRequests.filter { $0.identifier.contains(".expiry.") }.map { $0.identifier }

        if !subscriptionIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: subscriptionIdentifiers)
            print("Cancelled \(subscriptionIdentifiers.count) scheduled subscription notifications")
        }
    }

    /// Cancel notifications for a specific subscription
    func cancelNotifications(for subscription: Subscription) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let subscriptionIdentifiers = pendingRequests.filter { $0.identifier.hasPrefix("\(subscription.id.uuidString).expiry.") }.map { $0.identifier }

        if !subscriptionIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: subscriptionIdentifiers)
            print("Cancelled \(subscriptionIdentifiers.count) notifications for '\(subscription.name)'")
        }
    }
}
