//
//  SubscriptionSpendingCalculator.swift
//  SubZen
//
//  Created by Star on 202510/8.
//

import Foundation

struct SubscriptionSpendingResult {
    let total: Decimal
    let missingCurrencyCodes: [String]
}

enum SpendingCalculationMode {
    /// All subscriptions use the base currency; no conversion needed.
    case noCurrencyConversion(total: Decimal)
    /// At least one subscription uses a different currency; rates are required.
    case requiresConversion
}

/// Normalizes subscriptions to a monthly spend and converts into a target currency using a cached rate snapshot.
struct SubscriptionSpendingCalculator {
    private let averageDaysInMonth = Decimal(string: "30.4375")! // 365.25 / 12 for daily normalization
    private let weeksPerYear = Decimal(52)

    /// Determines whether currency conversion is needed for the given subscriptions.
    /// If all subscriptions use the base currency, returns the pre-calculated total to skip network requests.
    func evaluateConversionNeed(
        for subscriptions: [Subscription],
        baseCurrencyCode: String
    ) -> SpendingCalculationMode {
        guard !subscriptions.isEmpty else {
            return .noCurrencyConversion(total: .zero)
        }

        let base = baseCurrencyCode.uppercased()
        var total: Decimal = 0

        for subscription in subscriptions {
            let normalizedAmount = monthlyAmount(for: subscription)
            guard normalizedAmount != .zero else { continue }

            if subscription.currencyCode.uppercased() != base {
                return .requiresConversion
            }
            total += normalizedAmount
        }

        return .noCurrencyConversion(total: total)
    }

    func monthlyTotal(
        for subscriptions: [Subscription],
        baseCurrencyCode: String,
        ratesSnapshot: CurrencyRateSnapshot
    ) -> SubscriptionSpendingResult {
        let base = baseCurrencyCode.uppercased()
        var runningTotal: Decimal = 0
        var missingCodes = Set<String>()

        for subscription in subscriptions {
            let normalizedAmount = monthlyAmount(for: subscription)
            guard normalizedAmount != .zero else { continue }
            let currencyCode = subscription.currencyCode.uppercased()

            if currencyCode == base {
                runningTotal += normalizedAmount
                continue
            }

            guard let converted = ratesSnapshot.convert(amount: normalizedAmount, from: currencyCode, to: base) else {
                missingCodes.insert(currencyCode)
                continue
            }

            runningTotal += converted
        }

        return SubscriptionSpendingResult(
            total: runningTotal,
            missingCurrencyCodes: Array(missingCodes).sorted()
        )
    }

    func monthlyAmount(for subscription: Subscription) -> Decimal {
        guard !subscription.isInTrial() else { return .zero }

        switch subscription.cycle {
        case .lifetime:
            return .zero
        case .monthly:
            return subscription.price
        case .yearly:
            return subscription.price / Decimal(12)
        case .weekly:
            return subscription.price * weeksPerYear / Decimal(12)
        case let .custom(value, unit):
            switch unit {
            case .day:
                // Every N days: price * (days in month / N)
                return subscription.price * averageDaysInMonth / Decimal(value)
            case .week:
                // Every N weeks: price * (52 / N) / 12
                return subscription.price * weeksPerYear / Decimal(value) / Decimal(12)
            case .month:
                // Every N months: price / N
                return subscription.price / Decimal(value)
            case .year:
                // Every N years: price / N / 12
                return subscription.price / Decimal(value) / Decimal(12)
            }
        }
    }
}

/// Aggregates one-time purchases for subscriptions marked as `.lifetime`.
struct LifetimeSpendingCalculator {
    func evaluateConversionNeed(
        for subscriptions: [Subscription],
        baseCurrencyCode: String
    ) -> SpendingCalculationMode {
        guard !subscriptions.isEmpty else {
            return .noCurrencyConversion(total: .zero)
        }

        let base = baseCurrencyCode.uppercased()
        var total: Decimal = 0

        for subscription in subscriptions {
            let amount = subscription.price
            if subscription.currencyCode.uppercased() != base {
                return .requiresConversion
            }
            total += amount
        }

        return .noCurrencyConversion(total: total)
    }

    func total(
        for subscriptions: [Subscription],
        baseCurrencyCode: String,
        ratesSnapshot: CurrencyRateSnapshot
    ) -> SubscriptionSpendingResult {
        let base = baseCurrencyCode.uppercased()
        var runningTotal: Decimal = 0
        var missingCodes = Set<String>()

        for subscription in subscriptions {
            let amount = subscription.price
            let currencyCode = subscription.currencyCode.uppercased()

            if currencyCode == base {
                runningTotal += amount
                continue
            }

            guard let converted = ratesSnapshot.convert(amount: amount, from: currencyCode, to: base) else {
                missingCodes.insert(currencyCode)
                continue
            }

            runningTotal += converted
        }

        return SubscriptionSpendingResult(
            total: runningTotal,
            missingCurrencyCodes: Array(missingCodes).sorted()
        )
    }
}
