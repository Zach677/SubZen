//
//  SubscriptionManager+CRUD.swift
//  SubZen
//
//  Created by Star on 2025/7/15.
//

import Foundation

extension SubscriptionManager {
    func createSubscription(
        name: String,
        price: Decimal,
        cycle: BillingCycle,
        lastBillingDate: Date,
        currencyCode: String,
        reminderIntervals: [Int] = []
    ) throws -> Subscription {
        let subscription = try Subscription(
            name: name,
            price: price,
            cycle: cycle,
            lastBillingDate: lastBillingDate,
            currencyCode: currencyCode,
            reminderIntervals: reminderIntervals
        )

        subscriptions.append(subscription)
        saveSubscriptions()

        print("[+] created a new subscription with: \(subscription.name)")
        NotificationCenter.default.post(name: .newSubCreated, object: subscription.id)

        // Schedule notifications if reminder intervals are set
        if !reminderIntervals.isEmpty {
            Task {
                await SubscriptionNotificationManager.shared.handleSubscriptionCreated(subscription)
            }
        }

        return subscription
    }

    func subscription(identifier: UUID) -> Subscription? {
        guard let subscription = subscriptions.first(where: { $0.id == identifier }) else {
            return nil
        }
        return subscription
    }

    func deleteSubscription(identifier: UUID) {
        guard let subscription = subscriptions.first(where: { $0.id == identifier }) else { return }

        // Cancel notifications before deleting
        Task {
            await SubscriptionNotificationManager.shared.handleSubscriptionDeleted(subscription)
        }

        subscriptions.removeAll { $0.id == identifier }
        saveSubscriptions()
    }

    func eraseAll() {
        // Cancel all notifications before erasing
        Task {
            await SubscriptionNotificationManager.shared.cancelAllNotifications()
        }

        subscriptions.removeAll()
        saveSubscriptions()
    }
}

extension Notification.Name {
    static let newSubCreated = Notification.Name("newSubCreated")
    static let subscriptionUpdated = Notification.Name("subscriptionUpdated")
    static let settingsDidReset = Notification.Name("settingsDidReset")
}
