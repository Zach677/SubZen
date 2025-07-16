//
//  AddSubView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import Foundation
import SwiftUI

struct AddSubView: View {
    @Environment(\.dismiss) var dismiss

    var onSave: (Subscription) -> Void

    @State private var subscriptionName: String = ""
    @State private var price: Decimal? = nil
    @State private var cycle: BillingCycle = .monthly
    @State private var selectedCurrency: String =
        CurrencyList.allCurrencies.first?.code ?? "USD"
    @State private var showingCurrencySelector = false
    @State private var lastBillingDate: Date = .now

    @State private var showingAlert = false
    @State private var alertMessage = ""

    private var currencySymbol: String {
        CurrencyList.getSymbol(for: selectedCurrency)
    }

    var body: some View {
        Form {
            Section(header: Text("New Subscription")) {
                TextField("Name", text: $subscriptionName)
                HStack {
                    Button(currencySymbol) {
                        showingCurrencySelector = true
                    }
                    .buttonStyle(.bordered)
                    .sheet(isPresented: $showingCurrencySelector) {
                        CurrencySelectionView(
                            selectedCurrency: $selectedCurrency
                        )
                    }

                    TextField("0.00", value: $price, format: .number)
                        .keyboardType(.decimalPad)
                }
                Picker("Cycle", selection: $cycle) {
                    ForEach(BillingCycle.allCases, id: \.self) { cycleCase in
                        Text(cycleCase.rawValue).tag(cycleCase)
                    }
                }
                DatePicker(
                    "Last Billing Date",
                    selection: $lastBillingDate,
                    displayedComponents: .date
                )
            }
            Section {
                Button("Save") {
                    saveSubscription()
                }
                // Disable save button if name or price is empty
                .disabled(
                    subscriptionName.trimmingCharacters(in: .whitespaces)
                        .isEmpty
                        || price == nil
                        || price ?? 0 <= 0
                )
            }
        }
        .navigationTitle("Add Subscription")
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func saveSubscription() {
        let trimmedName = subscriptionName.trimmingCharacters(in: .whitespaces)

        do {
            let newSubscription = try Subscription(
                name: trimmedName,
                price: price ?? 0.0,
                cycle: cycle,
                lastBillingDate: lastBillingDate,
                currencyCode: selectedCurrency
            )

            onSave(newSubscription)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}
