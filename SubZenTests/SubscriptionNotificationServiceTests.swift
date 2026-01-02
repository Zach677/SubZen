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
        XCTAssertEqual(identifiers.first, "\(identifier.uuidString).expiry.1days")
        XCTAssertFalse(identifiers.contains("\(identifier.uuidString).expiry.7days"))
    }
}

final class MockNotificationCenter: NotificationCenterManaging {
    var authorizationStatusValue: UNAuthorizationStatus = .authorized
    var pendingRequests: [UNNotificationRequest] = []

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusValue
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        pendingRequests
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        pendingRequests.removeAll { identifiers.contains($0.identifier) }
    }

    func add(_ request: UNNotificationRequest) async throws {
        pendingRequests.removeAll { $0.identifier == request.identifier }
        pendingRequests.append(request)
    }
}
