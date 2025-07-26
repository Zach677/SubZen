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
        currencyCode: String
    ) throws -> Subscription {
        let subscription = try Subscription(
            name: name,
            price: price,
            cycle: cycle,
            lastBillingDate: lastBillingDate,
            currencyCode: currencyCode
        )

        subscriptions.append(subscription)
        saveSubscriptions()

        print("[+] created a new subscription with: \(subscription.name)")
        NotificationCenter.default.post(name: .newSubCreated, object: subscription.id)
        return subscription
    }

    func subscription(identifier: UUID) -> Subscription? {
        guard let subscription = subscriptions.first(where: { $0.id == identifier }) else {
            return nil
        }
        return subscription
    }

    func deleteSubscription(identifier: UUID) {
        subscriptions.removeAll { $0.id == identifier }
        saveSubscriptions()
    }

    func eraseAll() {
        subscriptions.removeAll()
        saveSubscriptions()
    }
}

extension Notification.Name {
    static let newSubCreated = Notification.Name("newSubCreated")
}
