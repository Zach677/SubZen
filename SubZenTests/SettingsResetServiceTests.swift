@testable import SubZen
import XCTest

final class SettingsResetServiceTests: XCTestCase {
    private var defaultsGuards: [UserDefaultsGuard] = []

    private let notificationKey = "HasRequestedNotificationPermission"
    private let subscriptionsKey = "subscriptions"

    override func setUp() {
        super.setUp()
        defaultsGuards = [
            UserDefaultsGuard(key: notificationKey),
            UserDefaultsGuard(key: subscriptionsKey),
        ]
        SubscriptionManager.shared.eraseAll()
        NotificationPermissionService.shared.hasRequestedPermission = false
    }

    override func tearDown() {
        SubscriptionManager.shared.eraseAll()
        NotificationPermissionService.shared.hasRequestedPermission = false
        defaultsGuards.removeAll()
        super.tearDown()
    }

    func testFullResetClearsAllStateAndPostsNotification() throws {
        let defaults = UserDefaults.standard

        // Seed persistent state
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

        XCTAssertNil(defaults.data(forKey: subscriptionsKey))
        XCTAssertFalse(NotificationPermissionService.shared.hasRequestedPermission)
        XCTAssertTrue(manager.getAllSubscriptions().isEmpty)
    }

    func testSettingsOnlyScopePreservesSubscriptions() throws {
        let defaults = UserDefaults.standard

        defaults.set(true, forKey: notificationKey)
        NotificationPermissionService.shared.hasRequestedPermission = true

        let manager = SubscriptionManager.shared
        manager.eraseAll()
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

        XCTAssertFalse(NotificationPermissionService.shared.hasRequestedPermission)
        XCTAssertEqual(manager.getAllSubscriptions().count, 1)
        XCTAssertEqual(manager.subscription(identifier: subscription.id)?.name, "Spotify")
        XCTAssertNotNil(defaults.data(forKey: subscriptionsKey))
    }
}
