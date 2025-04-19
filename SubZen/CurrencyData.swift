//
//  CurrencyData.swift
//  SubZen
//
//  Created by Star on 2025/4/19.
//

import Foundation

struct Currency: Identifiable, Hashable {
  let id: String
  let code: String
  let symbol: String
  let name: String

  // Create id from code for Identifiable protocol
  init(code: String, symbol: String, name: String) {
    self.id = code
    self.code = code
    self.symbol = symbol
    self.name = name
  }
}

enum CurrencyList {
  static let allCurrencies: [Currency] = [
    Currency(code: "USD", symbol: "$", name: "US Dollar"),
    Currency(code: "EUR", symbol: "€", name: "Euro"),
    Currency(code: "GBP", symbol: "£", name: "British Pound"),
    Currency(code: "TRY", symbol: "₺", name: "Turkish Lira"),
    Currency(code: "TWD", symbol: "NT$", name: "Taiwan Dollar"),
    Currency(code: "UAH", symbol: "₴", name: "Ukrainian Hryvnia"),
    Currency(code: "UYU", symbol: "$", name: "Uruguayan Peso"),
    Currency(code: "VND", symbol: "₫", name: "Vietnamese Dong"),
    Currency(code: "XPF", symbol: "CFP", name: "CFP Franc"),
    // Add more currencies as needed
  ]

  static func getCurrency(byCode code: String) -> Currency? {
    return allCurrencies.first { $0.code == code }
  }

  static func getSymbol(for code: String) -> String {
    return getCurrency(byCode: code)?.symbol ?? code
  }
}
