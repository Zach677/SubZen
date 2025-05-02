//
//  SubView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import SwiftUI

struct SubscriptionListView: View {
  @State private var subscriptions: [Subscription] = []
  @State private var subscriptionToEdit: Subscription?

  private let subscriptionsKey = "subscriptions"

  private var currencyFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    // You could potentially make this dynamic based on user settings or locale later
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        if !subscriptions.isEmpty {
          Text("Total Monthly: \(subscriptions.monthlyTotal as NSNumber, formatter: currencyFormatter)")
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.vertical, 10)
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
                  print("ListView received onEdit for \(sub.name)")
                  subscriptionToEdit = sub
                },
                onDelete: {
                  print("ListView received onDelete for \(sub.name)")
                  deleteSubscription(sub)
                }
              )
            }
          }
        }
      }
      .navigationTitle("All Subscriptions")
      .toolbar {
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
    }
  }

  private func binding(for subscription: Subscription) -> Binding<Subscription> {
    guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else {
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
    if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
      subscriptions.remove(at: index)
      saveSubscriptions()
    }
  }

  private func loadSubscriptions() {
    if let savedData = UserDefaults.standard.data(forKey: subscriptionsKey) {
      let decoder = JSONDecoder()
      if let loadedSubscriptions = try? decoder.decode([Subscription].self, from: savedData) {
        subscriptions = loadedSubscriptions
        subscriptions.sort { $0.dateAdded > $1.dateAdded }
        print("Loaded \(subscriptions.count) subscriptions from UserDefaults")
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
