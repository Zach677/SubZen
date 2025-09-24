//
//  CurrencyTotalServiceTests.swift
//  SubZenTests
//
//  Created by Codex on 2025/8/28.
//

@testable import SubZen
import XCTest

final class CurrencyTotalServiceTests: XCTestCase {
    func testSetBaseCurrencyRejectsUnsupportedCode() {
        let service = CurrencyTotalService.shared
        let original = service.baseCurrency
        service.setBaseCurrency("ZZZ")
        XCTAssertEqual(service.baseCurrency, original)
    }
}
