@testable import SubZen
import XCTest

final class SubscriptionManagerTests: XCTestCase {
    private var defaultsGuard: UserDefaultsGuard!
    private let key = "subscriptions"

    override func setUp() {
        super.setUp()
        defaultsGuard = UserDefaultsGuard(key: key)
        defaultsGuard.clear()
        // Ensure manager starts clean
        SubscriptionManager.shared.eraseAll()
    }

    override func tearDown() {
        // Clear and restore defaults via guard deinit
        SubscriptionManager.shared.eraseAll()
        defaultsGuard = nil
        super.tearDown()
    }

    func testCreateAndGetFlow() throws {
        let m = SubscriptionManager.shared
        let sub = try m.createSubscription(
            name: "Netflix",
            price: 15.99,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSince1970: 0),
            currencyCode: "USD"
        )

        let all = m.getAllSubscriptions()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, sub.id)

        let fetched = m.subscription(identifier: sub.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "Netflix")
    }

    func testEditSendsNotificationAndPersists() throws {
        let m = SubscriptionManager.shared
        let sub = try m.createSubscription(
            name: "Spotify",
            price: 9.99,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSince1970: 0),
            currencyCode: "USD"
        )

        let observer = NotificationObserver()
        let exp = observer.expect(name: .subscriptionUpdated)

        m.subscriptionEdit(identifier: sub.id) { s in
            s.name = "Spotify Premium"
        }

        wait(for: [exp], timeout: 1.0)

        let updated = m.subscription(identifier: sub.id)
        XCTAssertEqual(updated?.name, "Spotify Premium")

        // Ensure persisted to UserDefaults: wipe memory then rescan
        m.reloadFromPersistentStore()
        XCTAssertEqual(m.subscription(identifier: sub.id)?.name, "Spotify Premium")
    }

    func testDeleteAndEraseAll() throws {
        let m = SubscriptionManager.shared
        let a = try m.createSubscription(name: "A", price: 1, cycle: .monthly, lastBillingDate: Date(timeIntervalSince1970: 0), currencyCode: "USD")
        _ = try m.createSubscription(name: "B", price: 2, cycle: .monthly, lastBillingDate: Date(timeIntervalSince1970: 0), currencyCode: "USD")

        m.deleteSubscription(identifier: a.id)
        XCTAssertNil(m.subscription(identifier: a.id))
        XCTAssertEqual(m.getAllSubscriptions().count, 1)

        m.eraseAll()
        XCTAssertEqual(m.getAllSubscriptions().count, 0)
    }
}
