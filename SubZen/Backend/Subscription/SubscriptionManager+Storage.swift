//
//  SubscriptionManager+Storage.swift
//  SubZen
//
//  Created by Star on 2025/7/22.
//

import Foundation

extension SubscriptionManager {
    func saveSubscriptions() {
        do {
            let data = try JSONEncoder().encode(subscriptions)
            userDefaults.set(data, forKey: subscriptionsKey)
        } catch {
            print("[*] failed to save subscriptions: \(error)")
        }
    }

    func subscriptionEdit(identifier: UUID, _ block: @escaping (inout Subscription) -> Void) {
        guard let index = subscriptions.firstIndex(where: { $0.id == identifier }) else { return }
        block(&subscriptions[index])
        saveSubscriptions()
    }
}
