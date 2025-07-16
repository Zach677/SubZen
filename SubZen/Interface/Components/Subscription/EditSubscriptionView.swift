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

    @State private var showingCurrencySelector = false

    private var currencySymbol: String {
        CurrencyList.getSymbol(for: subscription.currencyCode)
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $subscription.name)
                HStack {
                    Button(currencySymbol) {
                        showingCurrencySelector = true
                    }
                    .buttonStyle(.bordered)
                    .sheet(isPresented: $showingCurrencySelector) {
                        CurrencySelectionView(
                            selectedCurrency: $subscription.currencyCode
                        )
                    }

                    TextField("Price", value: $subscription.price, format: .number)
                        .keyboardType(.decimalPad)
                }
                Picker("Cycle", selection: $subscription.cycle) {
                    ForEach(BillingCycle.allCases, id: \.self) { cycle in
                        Text(cycle.rawValue).tag(cycle)
                    }
                }
                DatePicker(
                    "Last Billing Date",
                    selection: $subscription.lastBillingDate,
                    displayedComponents: .date
                )
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
