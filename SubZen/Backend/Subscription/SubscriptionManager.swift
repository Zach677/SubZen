//
//  SubscriptionManager.swift
//  SubZen
//
//  Created by Star on 2025/7/15.
//

import Foundation

class SubscriptionManager {
    static let shared = SubscriptionManager()

    var subscriptions: [Subscription] = []
    private let userDefaults = UserDefaults.standard
    private let subscriptionsKey = "subscriptions"

    private init() {
        scanAll()
    }

    func scanAll() {
        guard let data = userDefaults.data(forKey: subscriptionsKey),
              let loadedSubscriptions = try? JSONDecoder().decode([Subscription].self, from: data)
        else {
            return
        }
        subscriptions = loadedSubscriptions
        print("[+] scanned \(subscriptions.count) subscriptions")
    }

    func saveSubscriptions() {
        if subscriptions.isEmpty {
            userDefaults.removeObject(forKey: subscriptionsKey)
            return
        }

        do {
            let data = try JSONEncoder().encode(subscriptions)
            userDefaults.set(data, forKey: subscriptionsKey)
        } catch {
            print("[*] failed to save subscriptions: \(error)")
        }
    }

    func allSubscriptions() -> [Subscription] {
        subscriptions
    }

    func subscriptionEdit(identifier: UUID, _ block: @escaping (inout Subscription) -> Void) {
        guard let index = subscriptions.firstIndex(where: { $0.id == identifier }) else { return }

        let subscription = subscriptions[index]
        let previousReminderIntervals = subscription.reminderIntervals
        let previousName = subscription.name
        let previousPrice = subscription.price
        let previousCycle = subscription.cycle
        let previousBillingDate = subscription.lastBillingDate
        let previousCurrencyCode = subscription.currencyCode

        block(&subscriptions[index])
        saveSubscriptions()

        let updatedSubscription = subscriptions[index]
        let schedulingDataChanged = previousReminderIntervals != updatedSubscription.reminderIntervals ||
            previousName != updatedSubscription.name ||
            previousPrice != updatedSubscription.price ||
            previousCycle != updatedSubscription.cycle ||
            previousBillingDate != updatedSubscription.lastBillingDate ||
            previousCurrencyCode != updatedSubscription.currencyCode

        if schedulingDataChanged {
            Task {
                await SubscriptionNotificationManager.shared.handleSubscriptionUpdated(updatedSubscription)
            }
        }

        NotificationCenter.default.post(name: .subscriptionUpdated, object: identifier)
    }
}
