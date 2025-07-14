//
//  SubscriptionListView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import SwiftUI
import UIKit

struct SubscriptionListView: View {
    @State private var subscriptions: [Subscription] = []
    @State private var subscriptionToEdit: Subscription?
    @State private var monthlyTotal: Decimal = 0
    @State private var isCalculatingTotal = false
    @State private var isRefreshing = false
    @State private var refreshTrigger = UUID() // 用于强制刷新列表

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
                        if isCalculatingTotal || isRefreshing {
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
                                    .fill(Color(.tertiarySystemGroupedBackground))
                                    .shadow(color: .primary.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color(.separator).opacity(0.4), lineWidth: 0.8)
                                    )
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 2)
                            )
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await refreshExchangeRates()
                    }
                    .id(refreshTrigger) // 当 refreshTrigger 改变时强制重新创建列表
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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
                    refreshTrigger = UUID() // 强制刷新列表
                    calculateMonthlyTotal()
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
                let total = try await CurrencyTotalService.shared.calculateMonthlyTotal(for: subscriptions)
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

    /// 刷新汇率数据并重新计算总计
    @MainActor
    private func refreshExchangeRates() async {
        guard !subscriptions.isEmpty else { return }

        isRefreshing = true

        do {
            // 强制刷新汇率数据
            let baseCurrency = CurrencyTotalService.shared.baseCurrency
            _ = try await ExchangeRateService.shared.refreshExchangeRates(baseCurrency: baseCurrency)

            // 重新计算总计
            let total = try await CurrencyTotalService.shared.calculateMonthlyTotal(for: subscriptions)
            monthlyTotal = total

            print("汇率数据已刷新，总计已更新")
        } catch {
            print("刷新汇率数据失败: \(error)")
        }

        isRefreshing = false
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
