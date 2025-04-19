//
//  AddSubView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import Foundation
import SwiftData
import SwiftUI

// Define the Cycle enum
enum Cycle: String, CaseIterable, Identifiable {
  case monthly = "Monthly"
  case yearly = "Yearly"
  case weekly = "Weekly"
  case daily = "Daily"

  var id: String { self.rawValue }
}

struct AddSubView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) var dismiss

  @State private var subscriptionName: String = ""
  @State private var price: Decimal? = nil
  @State private var cycle: Cycle = .monthly
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

          TextField("0.00", value: $price, format: .number)
            .keyboardType(.decimalPad)
        }
        Picker("Cycle", selection: $cycle) {
          ForEach(Cycle.allCases) { cycleCase in
            Text(cycleCase.rawValue.capitalized).tag(cycleCase)
          }
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

    let newSubscription = Subscription(
      name: trimmedName,
      price: price ?? 0.0,
      cycle: cycle.rawValue,
      dateAdded: .now,
      currencyCode: selectedCurrency
    )

    modelContext.insert(newSubscription)

    do {
      try modelContext.save()
      dismiss()
    } catch {
      print("Error saving context: \(error)")
      alertMessage = "Failed to save subscription. Error: \(error.localizedDescription)"
      showingAlert = true
    }
  }
}
