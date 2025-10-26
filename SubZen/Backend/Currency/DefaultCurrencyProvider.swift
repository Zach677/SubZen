//
//  DefaultCurrencyProvider.swift
//  SubZen
//
//  Created by Star on 2025/10/26.
//

import Foundation

protocol DefaultCurrencyProviding {
    func loadDefaultCurrency() -> Currency
    func saveDefaultCurrency(_ currency: Currency)
}

struct DefaultCurrencyProvider: DefaultCurrencyProviding {
    private let userDefaults: UserDefaults
    private let key: String

    init(userDefaults: UserDefaults = .standard, key: String = "settings.defaultCurrencyCode") {
        self.userDefaults = userDefaults
        self.key = key
    }

    func loadDefaultCurrency() -> Currency {
        if let code = userDefaults.string(forKey: key),
           let c = CurrencyList.getCurrency(byCode: code)
        {
            return c
        }

        if let localeCode = Locale.current.currency?.identifier,
           let c = CurrencyList.getCurrency(byCode: localeCode)
        {
            return c
        }

        return Currency(code: "USD", numeric: "840", name: "US Dollar", symbol: "$", decimalDigits: 2)
    }

    func saveDefaultCurrency(_ currency: Currency) {
        userDefaults.set(currency.code, forKey: key)
    }
}

