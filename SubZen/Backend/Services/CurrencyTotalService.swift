//
//  CurrencyTotalService.swift
//  SubZen
//
//  Created by Star on 2025/6/15.
//

import Foundation

@MainActor
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

  /// 计算月度总计（转换为基准货币）
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

        let monthlyAmount: Decimal
        switch subscription.cycle {
        case "Monthly":
          monthlyAmount = convertedPrice
        case "Weekly":
          monthlyAmount = convertedPrice * Decimal(4)
        case "Daily":
          monthlyAmount = convertedPrice * Decimal(30)
        case "Yearly":
          monthlyAmount = convertedPrice / Decimal(12)
        default:
          monthlyAmount = convertedPrice
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

  /// 计算年度总计（转换为基准货币）
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

        let yearlyAmount: Decimal
        switch subscription.cycle {
        case "Yearly":
          yearlyAmount = convertedPrice
        case "Monthly":
          yearlyAmount = convertedPrice * Decimal(12)
        case "Weekly":
          yearlyAmount = convertedPrice * Decimal(52)
        case "Daily":
          yearlyAmount = convertedPrice * Decimal(365)
        default:
          yearlyAmount = convertedPrice * Decimal(12)
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

  /// 设置基准货币
  func setBaseCurrency(_ currency: String) {
    baseCurrency = currency
    saveBaseCurrency()
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

  /// 按货币分组订阅
  func groupSubscriptionsByCurrency(_ subscriptions: [Subscription]) -> [String: [Subscription]] {
    Dictionary(grouping: subscriptions) { $0.currencyCode }
  }

  /// 获取所有使用的货币代码
  func getUsedCurrencies(from subscriptions: [Subscription]) -> Set<String> {
    Set(subscriptions.map { $0.currencyCode })
  }

  /// 检查是否包含多种货币
  func hasMultipleCurrencies(in subscriptions: [Subscription]) -> Bool {
    getUsedCurrencies(from: subscriptions).count > 1
  }
}
