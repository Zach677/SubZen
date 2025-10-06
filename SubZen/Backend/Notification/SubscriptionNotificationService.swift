//
//  SubscriptionNotificationService.swift
//  SubZen
//
//  Created by Star on 2025/9/30.
//

import Foundation
import UserNotifications

protocol SubscriptionNotificationScheduling {
    #if DEBUG
        func triggerDebugExpirationPreview(for subscription: Subscription) async throws
    #endif
    func scheduleNotifications(for subscription: Subscription) async throws
    func cancelAllScheduledNotifications() async
    func cancelNotifications(for subscription: Subscription) async
}

class SubscriptionNotificationService: SubscriptionNotificationScheduling {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    #if DEBUG

        // MARK: - Debug Preview

        func triggerDebugExpirationPreview(for subscription: Subscription) async throws {
            let intervals = subscription.reminderIntervals.sorted()

            guard !intervals.isEmpty else {
                print("[DebugNotification] Subscription '\(subscription.name)' has no reminder intervals; skipping preview.")
                return
            }

            let debugIdentifierPrefix = "debug.subscription.preview.\(subscription.id.uuidString)."

            let pendingRequests = await notificationCenter.pendingNotificationRequests()
            let identifiersToRemove = pendingRequests
                .filter { $0.identifier.hasPrefix(debugIdentifierPrefix) }
                .map(\.identifier)

            if !identifiersToRemove.isEmpty {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            }

            var delay: TimeInterval = 1

            for daysBefore in intervals {
                let content = createNotificationContent(for: subscription, daysBefore: daysBefore)

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
                let identifier = "\(debugIdentifierPrefix)\(daysBefore)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                try await notificationCenter.add(request)

                delay += 3
            }
        }
    #endif

    // MARK: - Custom Reminder Scheduling

    /// Schedule notifications for a subscription based on its reminder intervals
    func scheduleNotifications(for subscription: Subscription) async throws {
        let settings = await notificationCenter.notificationSettings()
        let allowedStatuses: Set<UNAuthorizationStatus> = [.authorized, .provisional, .ephemeral]

        guard allowedStatuses.contains(settings.authorizationStatus) else {
            print("Notification permission not granted (status: \(settings.authorizationStatus)), skipping scheduling for '\(subscription.name)'")
            return
        }

        let remainingDays = subscription.remainingDays
        let nextBillingDate = subscription.getNextBillingDate()

        guard remainingDays > 0 else {
            print("Subscription '\(subscription.name)' has already expired or expires today, skipping notification")
            return
        }

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

            let identifier = "\(subscription.id.uuidString).expiry.\(daysBefore)days"
            let content = createNotificationContent(for: subscription, daysBefore: daysBefore)

            let trigger: UNNotificationTrigger
            if notificationDate <= Date() {
                let fallbackInterval: TimeInterval = 5
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: fallbackInterval, repeats: false)
                print("Notification date for \(daysBefore)-day reminder already passed, scheduling immediate fallback")
            } else {
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            }

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
            content.body = "\(subscription.name) will renew tomorrow."
        case 3:
            content.title = "Subscription Renews in 3 Days"
            content.body = "\(subscription.name) will renew in 3 days."
        case 7:
            content.title = "Subscription Renews Next Week"
            content.body = "\(subscription.name) will renew next week."
        case 14:
            content.title = "Subscription Renews in 2 Weeks"
            content.body = "\(subscription.name) will renew in 2 weeks."
        default:
            content.title = "Subscription Reminder"
            content.body = "\(subscription.name) will renew in \(daysBefore) days."
        }

        content.sound = .default
        content.userInfo = ["subscriptionId": subscription.id.uuidString]

        return content
    }

    // MARK: - Notification Management

    /// Cancel all scheduled subscription notifications
    func cancelAllScheduledNotifications() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let subscriptionIdentifiers = pendingRequests.filter { $0.identifier.contains(".expiry.") }.map(\.identifier)

        if !subscriptionIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: subscriptionIdentifiers)
            print("Cancelled \(subscriptionIdentifiers.count) scheduled subscription notifications")
        }
    }

    /// Cancel notifications for a specific subscription
    func cancelNotifications(for subscription: Subscription) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let subscriptionIdentifiers = pendingRequests.filter { $0.identifier.hasPrefix("\(subscription.id.uuidString).expiry.") }.map(\.identifier)

        if !subscriptionIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: subscriptionIdentifiers)
            print("Cancelled \(subscriptionIdentifiers.count) notifications for '\(subscription.name)'")
        }
    }
}
