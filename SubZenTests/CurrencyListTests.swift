//
//  CurrencyListTests.swift
//  SubZenTests
//
//  Created by Codex on 2025/8/28.
//

@testable import SubZen
import XCTest

final class CurrencyListTests: XCTestCase {
    func testLoadsCurrenciesFromJSON() {
        XCTAssertFalse(CurrencyList.allCurrencies.isEmpty, "Currency list should not be empty")

        let usd = CurrencyList.getCurrency(byCode: "USD")
        XCTAssertNotNil(usd)
        XCTAssertEqual(usd?.symbol, "$")
        XCTAssertEqual(usd?.decimalDigits, 2)
    }

    func testSupportsUppercasedAndLowercasedCodes() {
        XCTAssertTrue(CurrencyList.supports(code: "eur"))
        XCTAssertTrue(CurrencyList.supports(code: "EUR"))
        XCTAssertFalse(CurrencyList.supports(code: "ZZZ"))
    }

    func testDisplaySymbolFallsBackToLocaleMapping() {
        let symbol = CurrencyList.displaySymbol(for: "AED")
        XCTAssertNotEqual(symbol.uppercased(), "AED", "Expected localized symbol for AED, got \(symbol)")
    }
}
