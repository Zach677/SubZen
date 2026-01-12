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

    struct DeliveredNotificationSnapshot: Equatable {
        let identifier: String
        let date: Date
    }

    static func wasAlreadyDelivered(
        identifier: String,
        scheduledDate: Date,
        deliveredNotifications: [DeliveredNotificationSnapshot]
    ) -> Bool {
        let deliveryThreshold = scheduledDate.addingTimeInterval(-1)
        return deliveredNotifications.contains { snapshot in
            snapshot.identifier == identifier && snapshot.date >= deliveryThreshold
        }
    }

    private func fetchDeliveredNotifications() async -> [UNNotification] {
        await withCheckedContinuation { continuation in
            notificationCenter.getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }
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

            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)

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
            #if DEBUG
                print("Notification permission not granted (status: \(settings.authorizationStatus)), skipping scheduling for '\(subscription.name)'")
            #endif
            return
        }

        let remainingDays = subscription.remainingDays
        let expirationDate = subscription.endDate ?? subscription.nextBillingDate()
        let now = Date()
        var deliveredNotifications: [DeliveredNotificationSnapshot]?

        guard remainingDays > 0 else {
            #if DEBUG
                print("Subscription '\(subscription.name)' has already expired or expires today, skipping notification")
            #endif
            return
        }

        for daysBefore in subscription.reminderIntervals {
            guard remainingDays >= daysBefore else {
                #if DEBUG
                    print("Subscription '\(subscription.name)' expires in \(remainingDays) days, skipping \(daysBefore)-day reminder")
                #endif
                continue
            }

            let notificationDate = Calendar.current.date(
                byAdding: .day,
                value: -daysBefore,
                to: expirationDate
            ) ?? expirationDate

            let identifier = "\(subscription.id.uuidString).expiry.\(daysBefore)days"
            let content = createNotificationContent(for: subscription, daysBefore: daysBefore)

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
            let scheduledDate = Calendar.current.date(from: components) ?? notificationDate

            let trigger: UNNotificationTrigger
            if scheduledDate <= now {
                if deliveredNotifications == nil {
                    deliveredNotifications = await fetchDeliveredNotifications().map { notification in
                        DeliveredNotificationSnapshot(
                            identifier: notification.request.identifier,
                            date: notification.date
                        )
                    }
                }

                let alreadyDeliveredForCurrentCycle = Self.wasAlreadyDelivered(
                    identifier: identifier,
                    scheduledDate: scheduledDate,
                    deliveredNotifications: deliveredNotifications ?? []
                )

                guard !alreadyDeliveredForCurrentCycle else {
                    #if DEBUG
                        print("Notification for '\(subscription.name)' \(daysBefore)-day reminder already delivered, skipping fallback")
                    #endif
                    continue
                }

                let fallbackInterval: TimeInterval = 5
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: fallbackInterval, repeats: false)
                #if DEBUG
                    print("Notification date for \(daysBefore)-day reminder already passed, scheduling immediate fallback")
                #endif
            } else {
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            }

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try await notificationCenter.add(request)
            #if DEBUG
                print("Scheduled \(daysBefore)-day reminder for '\(subscription.name)'")
            #endif
        }
    }

    /// Create notification content for a subscription
    private func createNotificationContent(for subscription: Subscription, daysBefore: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let isEnding = subscription.endDate != nil

        switch daysBefore {
        case 1:
            content.title = String(localized: isEnding ? "Subscription Ends Tomorrow!" : "Subscription Renews Tomorrow!")
            let key: String.LocalizationValue = isEnding ? "\(subscription.name) will end tomorrow." : "\(subscription.name) will renew tomorrow."
            content.body = String(localized: key)
        case 3:
            content.title = String(localized: isEnding ? "Subscription Ends in 3 Days" : "Subscription Renews in 3 Days")
            let key: String.LocalizationValue = isEnding ? "\(subscription.name) will end in 3 days." : "\(subscription.name) will renew in 3 days."
            content.body = String(localized: key)
        case 7:
            content.title = String(localized: isEnding ? "Subscription Ends Next Week" : "Subscription Renews Next Week")
            let key: String.LocalizationValue = isEnding ? "\(subscription.name) will end next week." : "\(subscription.name) will renew next week."
            content.body = String(localized: key)
        case 14:
            content.title = String(localized: isEnding ? "Subscription Ends in 2 Weeks" : "Subscription Renews in 2 Weeks")
            let key: String.LocalizationValue = isEnding ? "\(subscription.name) will end in 2 weeks." : "\(subscription.name) will renew in 2 weeks."
            content.body = String(localized: key)
        default:
            content.title = String(localized: "Subscription Reminder")
            let daysValue = Int64(daysBefore)
            let key: String.LocalizationValue = isEnding ? "\(subscription.name) will end in \(daysValue) days." : "\(subscription.name) will renew in \(daysValue) days."
            content.body = String(localized: key)
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

        notificationCenter.removePendingNotificationRequests(withIdentifiers: subscriptionIdentifiers)
        guard !subscriptionIdentifiers.isEmpty else { return }
        #if DEBUG
            print("Cancelled \(subscriptionIdentifiers.count) scheduled subscription notifications")
        #endif
    }

    /// Cancel notifications for a specific subscription
    func cancelNotifications(for subscription: Subscription) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let subscriptionIdentifiers = pendingRequests.filter { $0.identifier.hasPrefix("\(subscription.id.uuidString).expiry.") }.map(\.identifier)

        notificationCenter.removePendingNotificationRequests(withIdentifiers: subscriptionIdentifiers)
        guard !subscriptionIdentifiers.isEmpty else { return }
        #if DEBUG
            print("Cancelled \(subscriptionIdentifiers.count) notifications for '\(subscription.name)'")
        #endif
    }
}
