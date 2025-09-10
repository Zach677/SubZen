import Foundation
import XCTest

/// Helper to wait for specific Notification.Name
final class NotificationObserver {
    private var token: NSObjectProtocol?

    func expect(name: Notification.Name, object: AnyObject? = nil, in center: NotificationCenter = .default) -> XCTestExpectation {
        let exp = XCTestExpectation(description: "Expect notification: \(name.rawValue)")
        token = center.addObserver(forName: name, object: object, queue: .main) { _ in
            exp.fulfill()
        }
        return exp
    }

    deinit {
        if let token { NotificationCenter.default.removeObserver(token) }
    }
}
