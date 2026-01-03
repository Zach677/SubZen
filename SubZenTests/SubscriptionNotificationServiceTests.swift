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

        let staleContent = UNMutableNotificationContent()
        staleContent.title = "Stale"
        let staleTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let staleRequest = UNNotificationRequest(
            identifier: "\(identifier.uuidString).expiry.7days",
            content: staleContent,
            trigger: staleTrigger
        )
        mockCenter.pendingRequests = [staleRequest]

        let service = SubscriptionNotificationService(notificationCenter: mockCenter)
        try await service.scheduleNotifications(for: subscription)

        let identifiers = await mockCenter.pendingNotificationRequests().map(\.identifier)
        XCTAssertEqual(identifiers.count, 1)
        let nextBillingDate = subscription.nextBillingDate()
        let billingKey = billingDateIdentifierKey(from: nextBillingDate)
        XCTAssertEqual(identifiers.first, "\(identifier.uuidString).expiry.1days.\(billingKey)")
        XCTAssertFalse(identifiers.contains("\(identifier.uuidString).expiry.7days"))
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

        let nextBillingDate = subscription.nextBillingDate()
        let billingKey = billingDateIdentifierKey(from: nextBillingDate)

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

        let service = SubscriptionNotificationService(notificationCenter: mockCenter)
        try await service.scheduleNotifications(for: subscription)

        let deliveredIdentifiers = await mockCenter.deliveredNotifications().map(\.request.identifier)
        XCTAssertFalse(deliveredIdentifiers.contains("\(identifier.uuidString).expiry.1days.19990101"))
        XCTAssertTrue(deliveredIdentifiers.contains("\(identifier.uuidString).expiry.3days.\(billingKey)"))
    }

    private func billingDateIdentifierKey(from billingDate: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: billingDate)

        guard
            let year = components.year,
            let month = components.month,
            let day = components.day
        else {
            return String(Int(billingDate.timeIntervalSince1970))
        }

        return String(format: "%04d%02d%02d", year, month, day)
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
