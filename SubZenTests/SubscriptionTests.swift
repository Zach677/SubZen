@testable import SubZen
import XCTest

final class SubscriptionTests: XCTestCase {
    func testInitValidationEmptyName() {
        XCTAssertThrowsError(try Subscription(name: "", price: 1, cycle: .monthly, lastBillingDate: .now, currencyCode: "USD")) { error in
            XCTAssertEqual(error as? SubscriptionValidationError, .emptyName)
        }
    }

    func testInitValidationNonPositivePrice() {
        XCTAssertThrowsError(try Subscription(name: "Netflix", price: 0, cycle: .monthly, lastBillingDate: .now, currencyCode: "USD")) { error in
            XCTAssertEqual(error as? SubscriptionValidationError, .negativePriceQuestionablePrice)
        }
    }

    func testInitValidationInvalidCurrency() {
        XCTAssertThrowsError(try Subscription(name: "Spotify", price: 9.99, cycle: .monthly, lastBillingDate: .now, currencyCode: "US")) { error in
            XCTAssertEqual(error as? SubscriptionValidationError, .invalidCurrency)
        }
    }

    func testInitValidationUnsupportedCurrencyCode() {
        XCTAssertThrowsError(try Subscription(name: "Disney+", price: 9.99, cycle: .monthly, lastBillingDate: .now, currencyCode: "ZZZ")) { error in
            XCTAssertEqual(error as? SubscriptionValidationError, .invalidCurrency)
        }
    }

    func testInitValidationFutureBillingDate() {
        let future = Date().addingTimeInterval(24 * 60 * 60)
        XCTAssertThrowsError(try Subscription(name: "iCloud", price: 1.0, cycle: .monthly, lastBillingDate: future, currencyCode: "USD")) { error in
            XCTAssertEqual(error as? SubscriptionValidationError, .futureBillingDate)
        }
    }

    func testInitValidationEndDateBeforeLastBillingDate() {
        let lastBillingDate = Date()
        let endDate = lastBillingDate.addingTimeInterval(-24 * 60 * 60)

        XCTAssertThrowsError(
            try Subscription(
                name: "Pro",
                price: 5,
                cycle: .monthly,
                lastBillingDate: lastBillingDate,
                endDate: endDate,
                currencyCode: "USD"
            )
        ) { error in
            XCTAssertEqual(error as? SubscriptionValidationError, .endDateBeforeLastBillingDate)
        }
    }

    func testCodableBackwardCompatibilityWithStringCycle() throws {
        // Prepare JSON where cycle is a string (legacy data)
        let json = """
        {"id":"00000000-0000-0000-0000-000000000001","name":"A","price":12.34,"cycle":"Monthly","lastBillingDate":0,"currencyCode":"USD"}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Subscription.self, from: json)
        XCTAssertEqual(decoded.cycle, .monthly)

        // When encoding, we expect cycle to be encoded as string for compatibility
        let encoded = try JSONEncoder().encode(decoded)
        let encodedString = String(data: encoded, encoding: .utf8)!
        XCTAssertTrue(encodedString.contains("\"cycle\":\"Monthly\""))
    }

    func testEqualityByAllFieldsAndId() throws {
        let a = try Subscription(name: "A", price: 10, cycle: .monthly, lastBillingDate: Date(timeIntervalSince1970: 0), currencyCode: "USD")
        let b = try Subscription(name: "A", price: 10, cycle: .monthly, lastBillingDate: Date(timeIntervalSince1970: 0), currencyCode: "USD")

        // Equal only if id is the same
        let sameId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        a.id = sameId
        b.id = sameId
        XCTAssertEqual(a, b)

        b.id = UUID()
        XCTAssertNotEqual(a, b)
    }

    func testNextBillingDateIsInFuture() throws {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let s = try Subscription(name: "Pro", price: 5, cycle: .monthly, lastBillingDate: lastMonth, currencyCode: "USD")

        let next = s.nextBillingDate()
        XCTAssertTrue(next > Date())
        XCTAssertTrue(next > s.lastBillingDate)
    }

    func testRemainingDaysNonNegative() throws {
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let s = try Subscription(name: "Pro", price: 5, cycle: .weekly, lastBillingDate: lastWeek, currencyCode: "USD")

        XCTAssertGreaterThanOrEqual(s.remainingDays, 0)
    }

    func testRemainingDaysUsesEndDateWhenSet() throws {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let lastBillingDate = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        let endDate = calendar.date(byAdding: .day, value: 3, to: startOfToday)!

        let subscription = try Subscription(
            name: "Pro",
            price: 5,
            cycle: .monthly,
            lastBillingDate: lastBillingDate,
            endDate: endDate,
            currencyCode: "USD"
        )

        XCTAssertEqual(subscription.remainingDays, 3)
    }

    func testMonthlyAmountIsZeroWhenEndDateIsSet() throws {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let lastBillingDate = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        let endDate = calendar.date(byAdding: .day, value: 3, to: startOfToday)!

        let subscription = try Subscription(
            name: "Pro",
            price: 10,
            cycle: .monthly,
            lastBillingDate: lastBillingDate,
            endDate: endDate,
            currencyCode: "USD"
        )

        XCTAssertEqual(SubscriptionSpendingCalculator().monthlyAmount(for: subscription), .zero)
    }

    func testIsEndedTrueWhenEndDateIsInPast() throws {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let lastBillingDate = calendar.date(byAdding: .day, value: -30, to: startOfToday)!
        let endDate = calendar.date(byAdding: .day, value: -1, to: startOfToday)!

        let subscription = try Subscription(
            name: "Pro",
            price: 10,
            cycle: .monthly,
            lastBillingDate: lastBillingDate,
            endDate: endDate,
            currencyCode: "USD"
        )

        XCTAssertTrue(subscription.isEnded())
    }
}
