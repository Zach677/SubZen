//
//  SubscriptionNotificationService.swift
//  SubZen
//
//  Created by Star on 2025/9/30.
//

import Foundation
import UserNotifications

struct DeliveredNotificationSnapshot {
    let request: UNNotificationRequest
    let deliveryDate: Date
}

protocol NotificationCenterManaging {
    func authorizationStatus() async -> UNAuthorizationStatus
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func deliveredNotifications() async -> [DeliveredNotificationSnapshot]
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func add(_ request: UNNotificationRequest) async throws
}

extension UNUserNotificationCenter: NotificationCenterManaging {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }

    func deliveredNotifications() async -> [DeliveredNotificationSnapshot] {
        await withCheckedContinuation { continuation in
            getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }.map { notification in
            DeliveredNotificationSnapshot(request: notification.request, deliveryDate: notification.date)
        }
    }
}

protocol SubscriptionNotificationScheduling {
    #if DEBUG
        func triggerDebugExpirationPreview(for subscription: Subscription) async throws
    #endif
    func scheduleNotifications(for subscription: Subscription) async throws
    func cancelAllScheduledNotifications() async
    func cancelNotifications(for subscription: Subscription) async
}

class SubscriptionNotificationService: SubscriptionNotificationScheduling {
    private enum Constants {
        static let reminderHour = 9
        static let reminderMinute = 0
    }

    private let notificationCenter: NotificationCenterManaging

    init(notificationCenter: NotificationCenterManaging = UNUserNotificationCenter.current()) {
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

            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)

            let deliveredNotifications = await notificationCenter.deliveredNotifications()
            let deliveredIdentifiersToRemove = deliveredNotifications
                .map(\.request.identifier)
                .filter { $0.hasPrefix(debugIdentifierPrefix) }

            notificationCenter.removeDeliveredNotifications(withIdentifiers: deliveredIdentifiersToRemove)

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
        let subscriptionId = subscription.id.uuidString
        let nextBillingDate = subscription.nextBillingDate()
        let currentBillingKey = billingDateIdentifierKey(from: nextBillingDate)

        async let pendingRequestsTask = notificationCenter.pendingNotificationRequests()
        async let deliveredNotificationsTask = notificationCenter.deliveredNotifications()

        let pendingRequests = await pendingRequestsTask
        let deliveredNotifications = await deliveredNotificationsTask

        let pendingIdentifiersToRemove = pendingRequests
            .filter { isSubscriptionExpiryNotification($0, subscriptionId: subscriptionId) }
            .map(\.identifier)

        if !pendingIdentifiersToRemove.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: pendingIdentifiersToRemove)
        }

        let deliveredExpiryNotifications = deliveredNotifications
            .filter { isSubscriptionExpiryNotification($0.request, subscriptionId: subscriptionId) }

        let deliveredExpiryIdentifiersForCurrentBilling = Set(
            deliveredExpiryNotifications
                .map(\.request.identifier)
                .filter { $0.hasSuffix(".\(currentBillingKey)") }
        )

        let now = Date()
        let calendar = Calendar.current
        let hasDeliveredExpiryNotificationToday = deliveredExpiryNotifications.contains { notification in
            calendar.isDate(notification.deliveryDate, inSameDayAs: now)
        }
        let deliveredIdentifiersToRemove = deliveredExpiryNotifications
            .filter { notification in
                let isCurrentBilling = notification.request.identifier.hasSuffix(".\(currentBillingKey)")
                let deliveredToday = calendar.isDate(notification.deliveryDate, inSameDayAs: now)
                return !isCurrentBilling && !deliveredToday
            }
            .map(\.request.identifier)

        if !deliveredIdentifiersToRemove.isEmpty {
            notificationCenter.removeDeliveredNotifications(withIdentifiers: deliveredIdentifiersToRemove)
        }

        let authorizationStatus = await notificationCenter.authorizationStatus()
        let allowedStatuses: Set<UNAuthorizationStatus> = [.authorized, .provisional, .ephemeral]

        guard allowedStatuses.contains(authorizationStatus) else {
            print("Notification permission not granted (status: \(authorizationStatus)), skipping scheduling for '\(subscription.name)'")
            return
        }

        let remainingDays = subscription.remainingDays

        guard remainingDays > 0 else {
            print("Subscription '\(subscription.name)' has already expired or expires today, skipping notification")
            return
        }

        let uniqueIntervals = Set(subscription.reminderIntervals).filter { $0 > 0 }.sorted()

        for daysBefore in uniqueIntervals {
            guard remainingDays >= daysBefore else {
                print("Subscription '\(subscription.name)' expires in \(remainingDays) days, skipping \(daysBefore)-day reminder")
                continue
            }

            let notificationDate = reminderDate(for: nextBillingDate, daysBefore: daysBefore)
            let identifier = notificationIdentifier(for: subscription, daysBefore: daysBefore, billingDate: nextBillingDate)
            let content = createNotificationContent(for: subscription, daysBefore: daysBefore)

            let trigger: UNNotificationTrigger
            if notificationDate <= now {
                guard !hasDeliveredExpiryNotificationToday else {
                    print("Subscription '\(subscription.name)' already received an expiry reminder today; skipping fallback scheduling")
                    continue
                }
                guard !deliveredExpiryIdentifiersForCurrentBilling.contains(identifier) else {
                    print("Reminder '\(identifier)' already delivered, skipping fallback scheduling")
                    continue
                }
                let fallbackInterval: TimeInterval = 5
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: fallbackInterval, repeats: false)
                print("Notification date for \(daysBefore)-day reminder already passed, scheduling immediate fallback")
            } else {
                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: notificationDate
                )
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
            content.title = String(localized: "Subscription Renews Tomorrow!")
            content.body = String(localized: "\(subscription.name) will renew tomorrow.")
        case 3:
            content.title = String(localized: "Subscription Renews in 3 Days")
            content.body = String(localized: "\(subscription.name) will renew in 3 days.")
        case 7:
            content.title = String(localized: "Subscription Renews Next Week")
            content.body = String(localized: "\(subscription.name) will renew next week.")
        case 14:
            content.title = String(localized: "Subscription Renews in 2 Weeks")
            content.body = String(localized: "\(subscription.name) will renew in 2 weeks.")
        default:
            content.title = String(localized: "Subscription Reminder")
            content.body = String(localized: "\(subscription.name) will renew in \(daysBefore) days.")
        }

        content.sound = .default
        content.userInfo = ["subscriptionId": subscription.id.uuidString]

        return content
    }

    private func isSubscriptionExpiryNotification(_ request: UNNotificationRequest, subscriptionId: String) -> Bool {
        guard request.identifier.contains(".expiry.") else { return false }

        if request.identifier.hasPrefix("\(subscriptionId).expiry.") {
            return true
        }

        let requestSubscriptionId = request.content.userInfo["subscriptionId"] as? String
        return requestSubscriptionId == subscriptionId
    }

    private func reminderDate(for billingDate: Date, daysBefore: Int) -> Date {
        let calendar = Calendar.current
        let billingDayStart = calendar.startOfDay(for: billingDate)
        let reminderDay = calendar.date(byAdding: .day, value: -daysBefore, to: billingDayStart) ?? billingDayStart

        return calendar.date(
            bySettingHour: Constants.reminderHour,
            minute: Constants.reminderMinute,
            second: 0,
            of: reminderDay
        ) ?? reminderDay
    }

    private func notificationIdentifier(for subscription: Subscription, daysBefore: Int, billingDate: Date) -> String {
        let key = billingDateIdentifierKey(from: billingDate)
        return "\(subscription.id.uuidString).expiry.\(daysBefore)days.\(key)"
    }

    private func billingDateIdentifierKey(from billingDate: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: billingDate)

        guard
            let year = components.year,
            let month = components.month,
            let day = components.day
        else {
            return String(Int(billingDate.timeIntervalSince1970))
        }

        return String(format: "%04d%02d%02d", year, month, day)
    }

    // MARK: - Notification Management

    /// Cancel all scheduled subscription notifications
    func cancelAllScheduledNotifications() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let subscriptionIdentifiers = pendingRequests.filter { $0.identifier.contains(".expiry.") }.map(\.identifier)

        notificationCenter.removePendingNotificationRequests(withIdentifiers: subscriptionIdentifiers)

        let deliveredNotifications = await notificationCenter.deliveredNotifications()
        let deliveredIdentifiers = deliveredNotifications.map(\.request.identifier).filter { $0.contains(".expiry.") }
        notificationCenter.removeDeliveredNotifications(withIdentifiers: deliveredIdentifiers)

        guard !subscriptionIdentifiers.isEmpty else { return }
        print("Cancelled \(subscriptionIdentifiers.count) scheduled subscription notifications")
    }

    /// Cancel notifications for a specific subscription
    func cancelNotifications(for subscription: Subscription) async {
        let subscriptionId = subscription.id.uuidString

        async let pendingRequestsTask = notificationCenter.pendingNotificationRequests()
        async let deliveredNotificationsTask = notificationCenter.deliveredNotifications()

        let pendingRequests = await pendingRequestsTask
        let deliveredNotifications = await deliveredNotificationsTask

        let pendingIdentifiers = pendingRequests
            .filter { isSubscriptionExpiryNotification($0, subscriptionId: subscriptionId) }
            .map(\.identifier)

        notificationCenter.removePendingNotificationRequests(withIdentifiers: pendingIdentifiers)

        let deliveredIdentifiers = deliveredNotifications
            .filter { isSubscriptionExpiryNotification($0.request, subscriptionId: subscriptionId) }
            .map(\.request.identifier)

        notificationCenter.removeDeliveredNotifications(withIdentifiers: deliveredIdentifiers)

        let removedCount = pendingIdentifiers.count + deliveredIdentifiers.count
        guard removedCount > 0 else { return }
        print("Cancelled \(removedCount) notifications for '\(subscription.name)'")
    }
}
