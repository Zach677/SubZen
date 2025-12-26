@testable import SubZen
import XCTest

final class SubscriptionSpendingCalculatorTests: XCTestCase {
    private var calculator: SubscriptionSpendingCalculator!

    override func setUp() {
        super.setUp()
        calculator = SubscriptionSpendingCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - monthlyTotal Tests

    func testMonthlyTotalConvertsCurrenciesAndCycles() throws {
        let snapshot = CurrencyRateSnapshot(
            base: "USD",
            rates: [
                "EUR": Decimal(string: "0.5")!, // 1 USD = 0.5 EUR -> 1 EUR = 2 USD
                "JPY": Decimal(string: "150.0")!, // 1 USD = 150 JPY
            ],
            sourceDate: Date(),
            fetchedAt: Date()
        )

        let subscriptions: [Subscription] = try [
            Subscription(name: "US Monthly", price: 10, cycle: .monthly, lastBillingDate: .now, currencyCode: "USD"),
            Subscription(name: "US Yearly", price: 120, cycle: .yearly, lastBillingDate: .now, currencyCode: "USD"),
            Subscription(name: "EU Monthly", price: 10, cycle: .monthly, lastBillingDate: .now, currencyCode: "EUR"),
            Subscription(name: "JP Weekly", price: 1000, cycle: .weekly, lastBillingDate: .now, currencyCode: "JPY"),
        ]

        let result = calculator.monthlyTotal(for: subscriptions, baseCurrencyCode: "USD", ratesSnapshot: snapshot)

        let expectedEuro = Decimal(10) / Decimal(string: "0.5")! // 20 USD
        let expectedJpyMonthly = Decimal(1000) * Decimal(52) / Decimal(12) // weekly -> monthly in JPY
        let expectedJpyUSD = expectedJpyMonthly / Decimal(string: "150.0")!
        let expectedTotal = Decimal(10) + Decimal(10) + expectedEuro + expectedJpyUSD

        XCTAssertEqual(result.missingCurrencyCodes, [])
        XCTAssertEqual(
            (result.total as NSDecimalNumber).doubleValue,
            (expectedTotal as NSDecimalNumber).doubleValue,
            accuracy: 0.01
        )
    }

    func testMissingCurrenciesAreReported() throws {
        let snapshot = CurrencyRateSnapshot(
            base: "USD",
            rates: [:],
            sourceDate: Date(),
            fetchedAt: Date()
        )

        let subscriptions: [Subscription] = try [
            Subscription(name: "Unsupported", price: 5, cycle: .monthly, lastBillingDate: .now, currencyCode: "CHF"),
        ]

        let result = calculator.monthlyTotal(for: subscriptions, baseCurrencyCode: "USD", ratesSnapshot: snapshot)
        XCTAssertEqual(result.total, .zero)
        XCTAssertEqual(result.missingCurrencyCodes, ["CHF"])
    }

    func testDailyCycleNormalization() throws {
        let snapshot = CurrencyRateSnapshot(
            base: "USD",
            rates: [:],
            sourceDate: Date(),
            fetchedAt: Date()
        )

        let subscriptions: [Subscription] = try [
            Subscription(name: "Daily Sub", price: 1, cycle: .daily, lastBillingDate: .now, currencyCode: "USD"),
        ]

        let result = calculator.monthlyTotal(for: subscriptions, baseCurrencyCode: "USD", ratesSnapshot: snapshot)

        // Daily amount normalized to monthly: 1 * 30.4375 (365.25 / 12)
        let expectedMonthly = Decimal(string: "30.4375")!
        XCTAssertEqual(result.total, expectedMonthly)
        XCTAssertTrue(result.missingCurrencyCodes.isEmpty)
    }

    func testSameCurrencyNoConversionNeeded() throws {
        let snapshot = CurrencyRateSnapshot(
            base: "EUR",
            rates: [:],
            sourceDate: Date(),
            fetchedAt: Date()
        )

        let subscriptions: [Subscription] = try [
            Subscription(name: "Euro Sub 1", price: 10, cycle: .monthly, lastBillingDate: .now, currencyCode: "EUR"),
            Subscription(name: "Euro Sub 2", price: 20, cycle: .monthly, lastBillingDate: .now, currencyCode: "EUR"),
        ]

        let result = calculator.monthlyTotal(for: subscriptions, baseCurrencyCode: "EUR", ratesSnapshot: snapshot)

        XCTAssertEqual(result.total, Decimal(30))
        XCTAssertTrue(result.missingCurrencyCodes.isEmpty)
    }

    func testEmptySubscriptionsReturnsZero() {
        let snapshot = CurrencyRateSnapshot(
            base: "USD",
            rates: ["EUR": Decimal(1)],
            sourceDate: Date(),
            fetchedAt: Date()
        )

        let result = calculator.monthlyTotal(for: [], baseCurrencyCode: "USD", ratesSnapshot: snapshot)

        XCTAssertEqual(result.total, .zero)
        XCTAssertTrue(result.missingCurrencyCodes.isEmpty)
    }

    // MARK: - evaluateConversionNeed Tests

    func testEvaluateConversionNeedWithEmptyList() {
        let mode = calculator.evaluateConversionNeed(for: [], baseCurrencyCode: "USD")

        if case let .noCurrencyConversion(total) = mode {
            XCTAssertEqual(total, .zero)
        } else {
            XCTFail("Expected noCurrencyConversion for empty list")
        }
    }

    func testEvaluateConversionNeedAllSameCurrency() throws {
        let subscriptions: [Subscription] = try [
            Subscription(name: "Sub 1", price: 10, cycle: .monthly, lastBillingDate: .now, currencyCode: "USD"),
            Subscription(name: "Sub 2", price: 20, cycle: .monthly, lastBillingDate: .now, currencyCode: "USD"),
        ]

        let mode = calculator.evaluateConversionNeed(for: subscriptions, baseCurrencyCode: "USD")

        if case let .noCurrencyConversion(total) = mode {
            XCTAssertEqual(total, Decimal(30))
        } else {
            XCTFail("Expected noCurrencyConversion when all currencies match base")
        }
    }

    func testEvaluateConversionNeedMixedCurrencies() throws {
        let subscriptions: [Subscription] = try [
            Subscription(name: "USD Sub", price: 10, cycle: .monthly, lastBillingDate: .now, currencyCode: "USD"),
            Subscription(name: "EUR Sub", price: 20, cycle: .monthly, lastBillingDate: .now, currencyCode: "EUR"),
        ]

        let mode = calculator.evaluateConversionNeed(for: subscriptions, baseCurrencyCode: "USD")

        if case .requiresConversion = mode {
            // Expected
        } else {
            XCTFail("Expected requiresConversion when currencies differ from base")
        }
    }

    func testEvaluateConversionNeedCaseInsensitive() throws {
        let subscriptions: [Subscription] = try [
            Subscription(name: "Sub", price: 10, cycle: .monthly, lastBillingDate: .now, currencyCode: "usd"),
        ]

        let mode = calculator.evaluateConversionNeed(for: subscriptions, baseCurrencyCode: "USD")

        if case let .noCurrencyConversion(total) = mode {
            XCTAssertEqual(total, Decimal(10))
        } else {
            XCTFail("Expected case-insensitive currency matching")
        }
    }

    // MARK: - Cross-currency Conversion Precision Test

    func testCrossCurrencyConversionPrecision() throws {
        // Test EUR -> JPY conversion via USD base
        let snapshot = CurrencyRateSnapshot(
            base: "USD",
            rates: [
                "EUR": Decimal(string: "0.92")!,
                "JPY": Decimal(string: "149.5")!,
            ],
            sourceDate: Date(),
            fetchedAt: Date()
        )

        let subscriptions: [Subscription] = try [
            Subscription(name: "EU Sub", price: 100, cycle: .monthly, lastBillingDate: .now, currencyCode: "EUR"),
        ]

        let result = calculator.monthlyTotal(for: subscriptions, baseCurrencyCode: "JPY", ratesSnapshot: snapshot)

        // EUR 100 -> USD: 100 / 0.92 = 108.6956...
        // USD -> JPY: 108.6956 * 149.5 = 16249.99...
        // Single-step: 100 * 149.5 / 0.92 = 16250
        let expected = Decimal(100) * Decimal(string: "149.5")! / Decimal(string: "0.92")!

        XCTAssertEqual(
            (result.total as NSDecimalNumber).doubleValue,
            (expected as NSDecimalNumber).doubleValue,
            accuracy: 0.01
        )
    }
}
