//
//  Subscription.swift
//  SubZen
//
//  Created by Star on 2025/4/13.
//

import Foundation
import SwiftData

@Model
final class Subscription {
		var name: String
		var price: Double
		var billingCycle: String
		var dateAdded: Date
		
		init(name: String = "", price: Double = 0.0, billingCycle: String = "Monthly", dateAdded: Date = .now) {
				self.name = name
				self.price = price
				self.billingCycle = billingCycle
				self.dateAdded = dateAdded
		}
}
