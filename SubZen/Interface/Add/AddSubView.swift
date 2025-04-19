//
//  AddSubView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import SwiftData
import SwiftUI

struct AddSubView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) var dismiss

  @State private var subscriptionName: String = ""
  @State private var price: Decimal = 0.0
  @State private var Cycle: String = "Monthly"
  @State private var selectedCurrency: String = CurrencyList.allCurrencies.first?.code ?? "USD"
  @State private var showingCurrencySelector = false

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

          TextField("Price", value: $price, format: .number)
            .keyboardType(.decimalPad)
        }
        Picker("Cycle", selection: $Cycle) {
          Text("Monthly").tag("Monthly")
          Text("Yearly").tag("Yearly")
        }
      }
      Section {
        Button("Save") {
          saveSubscription()
        }
        // Disable save button if name or price is empty
        .disabled(
          subscriptionName.trimmingCharacters(in: .whitespaces)
            .isEmpty
					|| price <= 0
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

    let newSubscription = Subscription(
      name: trimmedName,
      price: price,
      Cycle: Cycle,
      dateAdded: .now,
      currencyCode: selectedCurrency
    )

    modelContext.insert(newSubscription)

    do {
      try modelContext.save()
    } catch {
      print("Error saving context: \(error)")
		  alertMessage = "Failed to save subscription. Error: \(error.localizedDescription)"
		  showingAlert = true
    }

    dismiss()
  }
}
