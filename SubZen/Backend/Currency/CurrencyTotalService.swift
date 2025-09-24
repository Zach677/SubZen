//
//  CurrencyTotalService.swift
//  SubZen
//
//  Created by Star on 2025/6/15.
//

import Foundation

enum CurrencyTotalServiceError: LocalizedError {
    case unsupportedBaseCurrency(String)
    case unsupportedCurrencies([String])

    var errorDescription: String? {
        switch self {
        case let .unsupportedBaseCurrency(code):
            return "Unsupported base currency: \(code)"
        case let .unsupportedCurrencies(codes):
            let joined = codes.sorted().joined(separator: ", ")
            return "Unsupported currency codes: \(joined)"
        }
    }
}

class CurrencyTotalService: ObservableObject {
    static let shared = CurrencyTotalService()

    @Published var baseCurrency: String = ExchangeRateConfig.defaultBaseCurrency.uppercased()
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
            try validateCurrencies(for: subscriptions)
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
            try validateCurrencies(for: subscriptions)
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
        let normalized = normalize(code: currency)
        guard CurrencyList.supports(code: normalized) else {
            print("[CurrencyTotalService] Attempted to set unsupported base currency: \(currency)")
            return
        }
        baseCurrency = normalized
        saveBaseCurrency()
    }

    /// Reset to default base currency and drop persisted override
    func resetBaseCurrency() {
        baseCurrency = ExchangeRateConfig.defaultBaseCurrency.uppercased()
        UserDefaults.standard.removeObject(forKey: "BaseCurrency")
    }

    // MARK: - Private Methods

    private func loadBaseCurrency() {
        if let savedCurrency = UserDefaults.standard.string(forKey: "BaseCurrency") {
            let normalized = normalize(code: savedCurrency)
            if CurrencyList.supports(code: normalized) {
                baseCurrency = normalized
            } else {
                print("[CurrencyTotalService] Persisted base currency \(savedCurrency) is not supported. Falling back to default.")
                baseCurrency = ExchangeRateConfig.defaultBaseCurrency.uppercased()
                UserDefaults.standard.removeObject(forKey: "BaseCurrency")
            }
        } else {
            baseCurrency = ExchangeRateConfig.defaultBaseCurrency.uppercased()
        }
    }

    private func saveBaseCurrency() {
        UserDefaults.standard.set(baseCurrency.uppercased(), forKey: "BaseCurrency")
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

    private func validateCurrencies(for subscriptions: [Subscription]) throws {
        let normalizedBase = normalize(code: baseCurrency)
        guard CurrencyList.supports(code: normalizedBase) else {
            throw CurrencyTotalServiceError.unsupportedBaseCurrency(normalizedBase)
        }

        let currencyCodes = Set(subscriptions.map { normalize(code: $0.currencyCode) })
        let unsupported = currencyCodes.filter { !CurrencyList.supports(code: $0) }

        if !unsupported.isEmpty {
            throw CurrencyTotalServiceError.unsupportedCurrencies(Array(unsupported))
        }
    }

    private func normalize(code: String) -> String {
        code.uppercased()
    }
}
