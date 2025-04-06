//
//  AddSubView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import SwiftUI

struct AddSubView: View {
		@State private var subscriptionView: String = ""
		@State private var price: String = ""
		@State private var billingCycle: String = "Monthly"
		
		var body: some View {
				NavigationStack {
						Form {
								Section(header: Text("New Subscription")) {
										TextField("Name", text: $subscriptionView)
										TextField("Price", text: $price)
												.keyboardType(.decimalPad)
										Picker("Due", selection: $billingCycle) {
												Text("Monthly").tag("Monthly");	Text("Yearly").tag("Yearly")
										}
								}
								Section {
										Button("Save") {
												// Manage Subscriptions
										}
								}
						}
						.navigationTitle("Add Subscription")
				}
		}
}

#Preview {
    AddSubView()
}
