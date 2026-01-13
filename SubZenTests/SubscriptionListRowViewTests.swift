@testable import SubZen
import XCTest

@MainActor
final class SubscriptionListRowViewTests: XCTestCase {
    func testConfigureLifetimeSubscription_doesNotAppendCycleToPriceLabel() throws {
        let subscription = try Subscription(
            name: "Lifetime",
            price: 99,
            cycle: .lifetime,
            lastBillingDate: Date(timeIntervalSince1970: 0),
            currencyCode: "USD"
        )

        let view = SubscriptionListRowView()
        view.configure(with: subscription, iconStore: nil)

        let labelText = try XCTUnwrap(view.priceLabel.attributedText?.string)
        XCTAssertFalse(labelText.contains(" / "))
        XCTAssertEqual(view.priceLabel.accessibilityLabel, labelText)
    }

    func testConfigureRecurringSubscription_appendsCycleToPriceLabel() throws {
        let subscription = try Subscription(
            name: "Monthly",
            price: 9,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSince1970: 0),
            currencyCode: "USD"
        )

        let view = SubscriptionListRowView()
        view.configure(with: subscription, iconStore: nil)

        let labelText = try XCTUnwrap(view.priceLabel.attributedText?.string)
        XCTAssertTrue(labelText.contains(" / "))
        XCTAssertFalse(view.priceLabel.accessibilityLabel?.contains(" / ") ?? true)
    }
}
