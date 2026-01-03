@testable import SubZen
import XCTest

final class SubscriptionNotificationServiceTests: XCTestCase {
    func testWasAlreadyDeliveredMatchesIdentifierAndDate() {
        let identifier = "subscription.expiry.1"
        let notificationDate = Date(timeIntervalSince1970: 1000)
        let delivered = [
            SubscriptionNotificationService.DeliveredNotificationSnapshot(
                identifier: identifier,
                date: notificationDate
            ),
        ]

        XCTAssertTrue(
            SubscriptionNotificationService.wasAlreadyDelivered(
                identifier: identifier,
                scheduledDate: notificationDate,
                deliveredNotifications: delivered
            )
        )
    }

    func testWasAlreadyDeliveredIgnoresOldDeliveriesFromPreviousCycle() {
        let identifier = "subscription.expiry.1"
        let notificationDate = Date(timeIntervalSince1970: 1000)
        let delivered = [
            SubscriptionNotificationService.DeliveredNotificationSnapshot(
                identifier: identifier,
                date: notificationDate.addingTimeInterval(-2)
            ),
        ]

        XCTAssertFalse(
            SubscriptionNotificationService.wasAlreadyDelivered(
                identifier: identifier,
                scheduledDate: notificationDate,
                deliveredNotifications: delivered
            )
        )
    }

    func testWasAlreadyDeliveredRequiresIdentifierMatch() {
        let notificationDate = Date(timeIntervalSince1970: 1000)
        let delivered = [
            SubscriptionNotificationService.DeliveredNotificationSnapshot(
                identifier: "other",
                date: notificationDate
            ),
        ]

        XCTAssertFalse(
            SubscriptionNotificationService.wasAlreadyDelivered(
                identifier: "expected",
                scheduledDate: notificationDate,
                deliveredNotifications: delivered
            )
        )
    }
}
