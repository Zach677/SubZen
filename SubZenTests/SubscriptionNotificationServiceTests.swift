@testable import SubZen
import UserNotifications
import XCTest

final class SubscriptionNotificationServiceTests: XCTestCase {
    func testSchedulingRemovesExistingRequestsForSubscription() async throws {
        let mockCenter = MockNotificationCenter()
        var subscription = try Subscription(
            name: "Test",
            price: 9.99,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSinceNow: -7 * 24 * 60 * 60),
            currencyCode: "USD",
            reminderIntervals: [1]
        )

        let identifier = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        subscription.id = identifier

        let legacyStaleIdentifier = "\(identifier.uuidString).expiry.7days"
        let previousCycleStaleIdentifier = "\(identifier.uuidString).expiry.7days.19990101"

        let staleContent = UNMutableNotificationContent()
        staleContent.title = "Stale"
        let staleTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let legacyStaleRequest = UNNotificationRequest(
            identifier: legacyStaleIdentifier,
            content: staleContent,
            trigger: staleTrigger
        )
        let previousCycleStaleRequest = UNNotificationRequest(
            identifier: previousCycleStaleIdentifier,
            content: staleContent,
            trigger: staleTrigger
        )
        mockCenter.pendingRequests = [legacyStaleRequest, previousCycleStaleRequest]

        let service = SubscriptionNotificationService(notificationCenter: mockCenter)
        try await service.scheduleNotifications(for: subscription)

        let identifiers = await mockCenter.pendingNotificationRequests().map(\.identifier)
        XCTAssertEqual(identifiers.count, 1)
        XCTAssertTrue(identifiers.first?.hasPrefix("\(identifier.uuidString).expiry.1days.") == true)
        XCTAssertFalse(identifiers.contains(legacyStaleIdentifier))
        XCTAssertFalse(identifiers.contains(previousCycleStaleIdentifier))
    }

    func testSchedulingRemovesDeliveredNotificationsFromPreviousBillingCycles() async throws {
        let mockCenter = MockNotificationCenter()
        var subscription = try Subscription(
            name: "Test",
            price: 9.99,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSinceNow: -7 * 24 * 60 * 60),
            currencyCode: "USD",
            reminderIntervals: [1]
        )

        let identifier = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        subscription.id = identifier

        let service = SubscriptionNotificationService(notificationCenter: mockCenter)
        try await service.scheduleNotifications(for: subscription)

        let scheduledIdentifier = await mockCenter.pendingNotificationRequests().first?.identifier
        let billingKey = scheduledIdentifier?.split(separator: ".").last.map(String.init)

        guard let billingKey else {
            XCTFail("Expected a scheduled notification request identifier.")
            return
        }

        let oldCycleRequest = UNNotificationRequest(
            identifier: "\(identifier.uuidString).expiry.1days.19990101",
            content: UNMutableNotificationContent(),
            trigger: nil
        )

        let currentCycleRequest = UNNotificationRequest(
            identifier: "\(identifier.uuidString).expiry.3days.\(billingKey)",
            content: UNMutableNotificationContent(),
            trigger: nil
        )

        mockCenter.delivered = [
            DeliveredNotificationSnapshot(request: oldCycleRequest, deliveryDate: Date(timeIntervalSinceNow: -2 * 24 * 60 * 60)),
            DeliveredNotificationSnapshot(request: currentCycleRequest, deliveryDate: Date(timeIntervalSinceNow: -2 * 24 * 60 * 60)),
        ]

        try await service.scheduleNotifications(for: subscription)

        let deliveredIdentifiers = await mockCenter.deliveredNotifications().map(\.request.identifier)
        XCTAssertFalse(deliveredIdentifiers.contains("\(identifier.uuidString).expiry.1days.19990101"))
        XCTAssertTrue(deliveredIdentifiers.contains("\(identifier.uuidString).expiry.3days.\(billingKey)"))
    }
}

final class MockNotificationCenter: NotificationCenterManaging {
    var authorizationStatusValue: UNAuthorizationStatus = .authorized
    var pendingRequests: [UNNotificationRequest] = []
    var delivered: [DeliveredNotificationSnapshot] = []

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusValue
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        pendingRequests
    }

    func deliveredNotifications() async -> [DeliveredNotificationSnapshot] {
        delivered
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        pendingRequests.removeAll { identifiers.contains($0.identifier) }
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        delivered.removeAll { identifiers.contains($0.request.identifier) }
    }

    func add(_ request: UNNotificationRequest) async throws {
        pendingRequests.removeAll { $0.identifier == request.identifier }
        pendingRequests.append(request)
    }
}
