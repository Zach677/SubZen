@testable import SubZen
import XCTest

final class SettingsResetServiceTests: XCTestCase {
    private var defaultsGuards: [UserDefaultsGuard] = []

    private let exchangeRateKey = "ExchangeRateCache"
    private let baseCurrencyKey = "BaseCurrency"
    private let notificationKey = "HasRequestedNotificationPermission"
    private let subscriptionsKey = "subscriptions"

    override func setUp() {
        super.setUp()
        defaultsGuards = [
            UserDefaultsGuard(key: exchangeRateKey),
            UserDefaultsGuard(key: baseCurrencyKey),
            UserDefaultsGuard(key: notificationKey),
            UserDefaultsGuard(key: subscriptionsKey),
        ]
        SubscriptionManager.shared.subscriptions.removeAll()
        NotificationPermissionService.shared.hasRequestedPermission = false
    }

    override func tearDown() {
        SubscriptionManager.shared.subscriptions.removeAll()
        CurrencyTotalService.shared.setBaseCurrency(ExchangeRateConfig.defaultBaseCurrency)
        NotificationPermissionService.shared.hasRequestedPermission = false
        defaultsGuards.removeAll()
        super.tearDown()
    }

    func testFullResetClearsAllStateAndPostsNotification() throws {
        let defaults = UserDefaults.standard

        // Seed persistent state
        defaults.set(Data([0x01]), forKey: exchangeRateKey)
        CurrencyTotalService.shared.setBaseCurrency("JPY")
        defaults.set(true, forKey: notificationKey)
        NotificationPermissionService.shared.hasRequestedPermission = true

        let manager = SubscriptionManager.shared
        let subscription = try manager.createSubscription(
            name: "Netflix",
            price: 12.34,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSince1970: 0),
            currencyCode: "USD"
        )
        XCTAssertNotNil(subscription.id)

        let observer = NotificationObserver()
        let exp = observer.expect(name: .settingsDidReset)

        let completionExpectation = expectation(description: "Reset completion")

        SettingsResetService.shared.resetAll(scope: .full) { result in
            if case let .failure(error) = result {
                XCTFail("Unexpected reset failure: \(error)")
            }
            completionExpectation.fulfill()
        }

        wait(for: [exp, completionExpectation], timeout: 2.0)

        XCTAssertNil(defaults.data(forKey: exchangeRateKey))
        XCTAssertNil(defaults.string(forKey: baseCurrencyKey))
        XCTAssertNil(defaults.data(forKey: subscriptionsKey))
        XCTAssertEqual(CurrencyTotalService.shared.baseCurrency, ExchangeRateConfig.defaultBaseCurrency)
        XCTAssertFalse(NotificationPermissionService.shared.hasRequestedPermission)
        XCTAssertTrue(manager.getAllSubscriptions().isEmpty)
    }

    func testSettingsOnlyScopePreservesSubscriptions() throws {
        let defaults = UserDefaults.standard

        defaults.set(Data([0x02]), forKey: exchangeRateKey)
        CurrencyTotalService.shared.setBaseCurrency("EUR")
        defaults.set(true, forKey: notificationKey)
        NotificationPermissionService.shared.hasRequestedPermission = true

        let manager = SubscriptionManager.shared
        manager.subscriptions.removeAll()
        let subscription = try manager.createSubscription(
            name: "Spotify",
            price: 9.99,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSince1970: 10),
            currencyCode: "USD"
        )

        let observer = NotificationObserver()
        let exp = observer.expect(name: .settingsDidReset)

        SettingsResetService.shared.resetAll(scope: .settingsOnly)

        wait(for: [exp], timeout: 1.0)

        XCTAssertNil(defaults.data(forKey: exchangeRateKey))
        XCTAssertNil(defaults.string(forKey: baseCurrencyKey))
        XCTAssertFalse(NotificationPermissionService.shared.hasRequestedPermission)
        XCTAssertEqual(manager.getAllSubscriptions().count, 1)
        XCTAssertEqual(manager.subscription(identifier: subscription.id)?.name, "Spotify")
        XCTAssertNotNil(defaults.data(forKey: subscriptionsKey))
    }
}
