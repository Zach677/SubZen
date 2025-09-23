//
//  CurrencyTotalService.swift
//  SubZen
//
//  Created by Star on 2025/6/15.
//

import Foundation

class CurrencyTotalService: ObservableObject {
    static let shared = CurrencyTotalService()

    @Published var baseCurrency: String = "USD"
    @Published var isCalculating = false
    @Published var lastCalculationError: Error?

    private let exchangeRateService = ExchangeRateService.shared

    private init() {
        loadBaseCurrency()
    }

    // MARK: - Public Methods

    /// Calculate monthly total (converted to base currency)
    func calculateMonthlyTotal(for subscriptions: [Subscription]) async throws -> Decimal {
        isCalculating = true
        lastCalculationError = nil

        do {
            let rates = try await exchangeRateService.fetchExchangeRates(baseCurrency: baseCurrency)

            let total = subscriptions.reduce(Decimal.zero) { total, subscription in
                let convertedPrice = exchangeRateService.convertAmount(
                    subscription.price,
                    from: subscription.currencyCode,
                    to: baseCurrency,
                    rates: rates
                )

                let monthlyAmount: Decimal = switch subscription.cycle {
                case .monthly:
                    convertedPrice
                case .weekly:
                    convertedPrice * Decimal(4)
                case .daily:
                    convertedPrice * Decimal(30)
                case .yearly:
                    convertedPrice / Decimal(12)
                }

                return total + monthlyAmount
            }

            isCalculating = false
            return total
        } catch {
            isCalculating = false
            lastCalculationError = error
            throw error
        }
    }

    /// Calculate yearly total (converted to base currency)
    func calculateYearlyTotal(for subscriptions: [Subscription]) async throws -> Decimal {
        isCalculating = true
        lastCalculationError = nil

        do {
            let rates = try await exchangeRateService.fetchExchangeRates(baseCurrency: baseCurrency)

            let total = subscriptions.reduce(Decimal.zero) { total, subscription in
                let convertedPrice = exchangeRateService.convertAmount(
                    subscription.price,
                    from: subscription.currencyCode,
                    to: baseCurrency,
                    rates: rates
                )

                let yearlyAmount: Decimal = switch subscription.cycle {
                case .yearly:
                    convertedPrice
                case .monthly:
                    convertedPrice * Decimal(12)
                case .weekly:
                    convertedPrice * Decimal(52)
                case .daily:
                    convertedPrice * Decimal(365)
                }

                return total + yearlyAmount
            }

            isCalculating = false
            return total
        } catch {
            isCalculating = false
            lastCalculationError = error
            throw error
        }
    }

    /// Set base currency
    func setBaseCurrency(_ currency: String) {
        baseCurrency = currency
        saveBaseCurrency()
    }

    /// Reset to default base currency and drop persisted override
    func resetBaseCurrency() {
        baseCurrency = ExchangeRateConfig.defaultBaseCurrency
        UserDefaults.standard.removeObject(forKey: "BaseCurrency")
    }

    // MARK: - Private Methods

    private func loadBaseCurrency() {
        if let savedCurrency = UserDefaults.standard.string(forKey: "BaseCurrency") {
            baseCurrency = savedCurrency
        }
    }

    private func saveBaseCurrency() {
        UserDefaults.standard.set(baseCurrency, forKey: "BaseCurrency")
    }

    // MARK: - Utility Methods for Subscriptions Array

    /// Group subscriptions by currency
    func groupSubscriptionsByCurrency(_ subscriptions: [Subscription]) -> [String: [Subscription]] {
        Dictionary(grouping: subscriptions) { $0.currencyCode }
    }

    /// Get all used currency codes
    func getUsedCurrencies(from subscriptions: [Subscription]) -> Set<String> {
        Set(subscriptions.map(\.currencyCode))
    }

    /// Check if contains multiple currencies
    func hasMultipleCurrencies(in subscriptions: [Subscription]) -> Bool {
        getUsedCurrencies(from: subscriptions).count > 1
    }
}
