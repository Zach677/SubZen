//
//  EditSubscriptionView.swift
//  SubZen
//
//  Created by Star on 2025/4/19.
//

import SwiftUI

struct EditSubscriptionView: View {
		@Environment(\.dismiss) var dismiss
		@Bindable var subscription: Subscription

		var body: some View {
				NavigationView {
						 Form {
								 TextField("Name", text: $subscription.name)
								 TextField("Price", value: $subscription.price, format: .number)
										 .keyboardType(.decimalPad)
								 Picker("Cycle", selection: $subscription.Cycle) {
										 Text("Monthly").tag("Monthly")
										 Text("Yearly").tag("Yearly")
								 }
						 }
						 .navigationTitle("Edit \(subscription.name)")
						 .toolbar {
								 ToolbarItem(placement: .cancellationAction) {
										 Button("Cancel") { dismiss() }
								 }
								 ToolbarItem(placement: .confirmationAction) {
										 Button("Save") {
												 dismiss()
										 }
								 }
						 }
				}
		}
}
