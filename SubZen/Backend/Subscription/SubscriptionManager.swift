//
//  SubscriptionManager.swift
//  SubZen
//
//  Created by Star on 2025/7/15.
//

import Foundation

class SubscriptionManager {
		static let shared = SubscriptionManager()
		
		private(set) var subscriptions: [Subscription] = []
		private let userDefaults = UserDefaults.standard
		private let subscriptionsKey = "SavedSubscriptions"
		
		private init() {
				loadSubscriptions()
		}
		
		func newSubscription(_ subscription: Subscription) {
				subscriptions.append(subscription)
				saveSubscriptions()
		}
		
		func getAllSubscriptions() -> [Subscription] {
				return subscriptions
		}
		
		// MARK: - Persistence
		func saveSubscriptions() {
				do {
						let data = try JSONEncoder().encode(subscriptions)
						userDefaults.set(data, forKey: subscriptionsKey)
				} catch {
						print("Failed to save subscriptions: \(error)")
				}
		}
		
		private func loadSubscriptions() {
				guard let data = userDefaults.data(forKey: subscriptionsKey) else {
						print("No saved subscriptions found.")
						return
				}
				
				do {
						subscriptions = try JSONDecoder().decode([Subscription].self, from: data)
				} catch {
						print("Failed to load subscriptions: \(error)")
						subscriptions = []
				}
		}
}


