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
				
				newSubscription(subscription)
				return subscription
		}
		
		func subscription(withId id: UUID) -> Subscription? {
				return subscriptions.first { $0.id == id }
		}
		
		func subscriptions(for currency: String) -> [Subscription] {
				return subscriptions.filter { $0.currencyCode == currency }
		}
		
		func subscriptions(for cycle: BillingCycle) -> [Subscription] {
				return subscriptions.filter { $0.cycle == cycle }
		}
		
		
		func updateSubscription(
				_ subscription: Subscription,
				name: String? = nil,
				price: Decimal? = nil,
				cycle: BillingCycle? = nil,
				lastBillingDate: Date? = nil,
				currencyCode: String? = nil
		) throws {
				var updatedSubscription = subscription
				
				if let name = name {
						updatedSubscription.name = name }
				if let price = price {
						updatedSubscription.price = price }
				if let cycle = cycle {
						updatedSubscription.cycle = cycle }
				if let lastBillingDate = lastBillingDate {
						updatedSubscription.lastBillingDate = lastBillingDate }
				if let currencyCode = currencyCode {
						updatedSubscription.currencyCode = currencyCode }
				
				// Update in storage
				if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
						subscriptions[index] = updatedSubscription
						saveSubscriptions()
				}
		}
		
		func removeSubscription(withId id: UUID) {
				subscriptions.removeAll { $0.id == id }
				saveSubscriptions()
		}
				
		func removeSubscription(_ subscription: Subscription) {
				removeSubscription(withId: subscription.id)
		}
}
