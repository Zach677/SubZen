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
    let userDefaults = UserDefaults.standard
    let subscriptionsKey = "subscriptions"

    private init() {
        scanAll()
    }
}
