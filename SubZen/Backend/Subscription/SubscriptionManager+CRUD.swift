//
//  SubscriptionManager+CRUD.swift
//  SubZen
//
//  Created by Star on 2025/7/15.
//

import Foundation

extension SubscriptionManager {
		func scanAll() {
				guard let data = userDefaults.data(forKey: subscriptionsKey),
							let loadedSubscriptions = try? JSONDecoder().decode([Subscription].self, from: data) else {
						return
				}
				subscriptions = loadedSubscriptions
				print("[+] scanned \(subscriptions.count) subscriptions")
		}
		
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
				scanAll()
				
				print("[+] created a new subscription with: \(subscription.name)")
				NotificationCenter.default.post(name: .newSubCreated, object: subscription.id)
				return subscription
		}
		
		func subscription(identifier: UUID) -> Subscription? {
				guard let subscription = subscriptions.first(where: { $0.id == identifier }) else {
						print("[-] subscription not found with id: \(identifier)")
						return nil
				}
				return subscription
		}
		
		func subscriptions(for currency: String) -> [Subscription] {
				return subscriptions.filter { $0.currencyCode == currency }
		}
		
		func subscriptions(for cycle: BillingCycle) -> [Subscription] {
				return subscriptions.filter { $0.cycle == cycle }
		}
		
		func removeSubscription(identifier: UUID) {
				subscriptions.removeAll { $0.id == identifier }
				saveSubscriptions()
				scanAll()
		}
		
		func eraseAll() {
				subscriptions.removeAll()
				saveSubscriptions()
		}
}

extension Notification.Name {
		static let newSubCreated = Notification.Name("newSubCreated")
}

