//
//  EditSubscriptionView.swift
//  SubZen
//
//  Created by Star on 2025/4/19.
//

import SwiftUI

struct EditSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var subscription: Subscription
    var onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $subscription.name)
                TextField("Price", value: $subscription.price, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Cycle", selection: $subscription.cycle) {
                    Text("Monthly").tag("Monthly")
                    Text("Yearly").tag("Yearly")
                    Text("Weekly").tag("Weekly")
                    Text("Daily").tag("Daily")
                }
            }
            .navigationTitle("Edit \(subscription.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(
                        subscription.name.trimmingCharacters(in: .whitespaces)
                            .isEmpty
                    )
                }
            }
        }
    }
}
