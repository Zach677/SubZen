//
//  SubView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import ColorfulX
import SwiftUI

struct SubscriptionListView: View {
  @State private var subscriptions: [Subscription] = []
  @State private var subscriptionToEdit: Subscription?
  @State private var monthlyTotal: Decimal = 0
  @State private var isCalculatingTotal = false

  private let subscriptionsKey = "subscriptions"

  private var currencyFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = CurrencyTotalService.shared.baseCurrency
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        if !subscriptions.isEmpty {
          HStack {
            if isCalculatingTotal {
              ProgressView()
                .scaleEffect(0.8)
            }
            Text(
              "\(monthlyTotal as NSNumber, formatter: currencyFormatter)"
            )
            .font(.largeTitle)
            .foregroundColor(.primary)
          }
          .padding(.vertical, 20)
          .frame(maxWidth: .infinity, alignment: .center)
          Divider()
        }

        if subscriptions.isEmpty {
          ContentUnavailableView(
            "No Subscriptions",
            systemImage: "list.bullet.rectangle.portrait",
            description: Text(
              "Tap the + button to add your first subscription."
            )
          )
          .frame(maxHeight: .infinity)
        } else {
          List {
            ForEach(subscriptions) { sub in
              SubscriptionRowView(
                subscription: sub,
                onEdit: {
                  print(
                    "ListView received onEdit for \(sub.name)"
                  )
                  subscriptionToEdit = sub
                },
                onDelete: {
                  print(
                    "ListView received onDelete for \(sub.name)"
                  )
                  deleteSubscription(sub)
                }
              )
              .listRowBackground(
                RoundedRectangle(cornerRadius: 15)
                  .fill(Color(.secondarySystemGroupedBackground).opacity(0.7))
                  .padding(.vertical, 4)
              )
              .listRowSeparator(.hidden)
            }
          }
          .listStyle(.plain)
          .background(Color.clear)
          .scrollContentBackground(.hidden)
          .scrollIndicators(.hidden)
        }
      }
      .background {
        ColorfulView(color: .jelly, noise: .constant(32))
          .ignoresSafeArea()
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          NavigationLink {
            Text("Settings View Placeholder")
          } label: {
            Image(systemName: "gearshape")
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          NavigationLink {
            AddSubView { newSubscription in
              addSubscription(newSubscription)
            }
          } label: {
            Image(systemName: "plus")
          }
        }
      }
      .sheet(item: $subscriptionToEdit) { subscription in
        EditSubscriptionView(subscription: binding(for: subscription)) {
          saveSubscriptions()
        }
      }
      .onAppear {
        loadSubscriptions()
      }
      .onChange(of: subscriptions) { _, _ in
        calculateMonthlyTotal()
      }
    }
  }

  private func calculateMonthlyTotal() {
    guard !subscriptions.isEmpty else {
      monthlyTotal = 0
      return
    }

    isCalculatingTotal = true
    Task {
      do {
        let total = try await subscriptions.monthlyTotal()
        await MainActor.run {
          monthlyTotal = total
          isCalculatingTotal = false
        }
      } catch {
        await MainActor.run {
          monthlyTotal = 0
          isCalculatingTotal = false
        }
        print("Error calculating monthly total: \(error)")
      }
    }
  }

  private func binding(for subscription: Subscription) -> Binding<Subscription> {
    guard
      let index = subscriptions.firstIndex(where: {
        $0.id == subscription.id
      })
    else {
      fatalError("Subscription not found")
    }
    return $subscriptions[index]
  }

  private func addSubscription(_ subscription: Subscription) {
    subscriptions.append(subscription)
    saveSubscriptions()
  }

  private func deleteSubscription(_ subscription: Subscription) {
    print("Executing delete for \(subscription.name)")
    if let index = subscriptions.firstIndex(where: {
      $0.id == subscription.id
    }) {
      subscriptions.remove(at: index)
      saveSubscriptions()
    }
  }

  private func loadSubscriptions() {
    if let savedData = UserDefaults.standard.data(forKey: subscriptionsKey) {
      let decoder = JSONDecoder()
      if let loadedSubscriptions = try? decoder.decode(
        [Subscription].self,
        from: savedData
      ) {
        subscriptions = loadedSubscriptions
        subscriptions.sort { $0.lastBillingDate > $1.lastBillingDate }
        print(
          "Loaded \(subscriptions.count) subscriptions from UserDefaults"
        )
        return
      }
    }
    subscriptions = []
    print("No saved subscriptions found or decoding failed.")
  }

  private func saveSubscriptions() {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(subscriptions) {
      UserDefaults.standard.set(encoded, forKey: subscriptionsKey)
      print("Saved \(subscriptions.count) subscriptions to UserDefaults")
    } else {
      print("Failed to save subscriptions.")
    }
  }
}
