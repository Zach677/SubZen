//
//  SubscriptionRowView.swift
//  SubZen
//
//  Created by Star on 2025/4/13.
//

import SwiftUI

struct SubscriptionRowView: View {
		let subscription: Subscription // Input is a Subscription object

		var body: some View {
				HStack {
						Text(subscription.name)
								.font(.headline)
						Spacer() // Pushes price and cycle to the right
						VStack(alignment: .trailing) { // Align price and cycle vertically
								Text(subscription.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD")) // Format price as currency
										.font(.subheadline)
								Text("/ \(subscription.Cycle)")
										.font(.caption)
										.foregroundStyle(.secondary) // Make cycle less prominent
						}
				}
				.padding(.vertical, 4) // Add a little vertical padding
		}
}

// Preview requires a sample Subscription object
#Preview {
		// Create a sample subscription for the preview
		let sampleSub = Subscription(name: "SampleFlix", price: 14.99, Cycle: "Monthly")
		return List { // Show it within a List for context
				 SubscriptionRowView(subscription: sampleSub)
		}
		// Note: No model container needed here as it just displays data, doesn't modify it.
}


