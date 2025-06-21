//
//  CurrencyTotal.swift
//  SubZen
//
//  Created by Star on 2025/4/19.
//
import Foundation

extension Array where Element == Subscription {

  /// 计算转换为基准货币的月度总计
  func monthlyTotal() async throws -> Decimal {
    return try await CurrencyTotalService.shared.calculateMonthlyTotal(for: self)
  }

  /// 计算转换为基准货币的年度总计
  func yearlyTotal() async throws -> Decimal {
    return try await CurrencyTotalService.shared.calculateYearlyTotal(for: self)
  }

  // MARK: - Utility Methods

  /// 按货币分组订阅
  var groupedByCurrency: [String: [Subscription]] {
    Dictionary(grouping: self) { $0.currencyCode }
  }

  /// 获取所有使用的货币代码
  var usedCurrencies: Set<String> {
    Set(map { $0.currencyCode })
  }

  /// 检查是否包含多种货币
  var hasMultipleCurrencies: Bool {
    usedCurrencies.count > 1
  }
}


