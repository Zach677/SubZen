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

    func subscriptionEdit(identifier _: UUID, _ block: @escaping (inout [Subscription]) -> Void) {
        block(&subscriptions)
        saveSubscriptions()
    }
}
