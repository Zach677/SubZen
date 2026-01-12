@testable import SubZen
import XCTest

final class SubscriptionImportServiceTests: XCTestCase {
    private var importService: SubscriptionImportService!
    private var defaultsGuard: UserDefaultsGuard!
    private let key = "subscriptions"
    private var tempFileURL: URL?

    override func setUp() {
        super.setUp()
        defaultsGuard = UserDefaultsGuard(key: key)
        defaultsGuard.clear()
        SubscriptionManager.shared.eraseAll()
        importService = SubscriptionImportService()
    }

    override func tearDown() {
        SubscriptionManager.shared.eraseAll()
        defaultsGuard = nil
        importService = nil
        if let url = tempFileURL {
            try? FileManager.default.removeItem(at: url)
            tempFileURL = nil
        }
        super.tearDown()
    }

    private func createTempFile(with content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test-import-\(UUID().uuidString).json")
        try content.write(to: url, atomically: true, encoding: .utf8)
        tempFileURL = url
        return url
    }

    func testImportEmptySubscriptionListThrowsError() throws {
        let json = """
        {
            "version": 1,
            "exportedAt": "2025-01-15T10:00:00Z",
            "subscriptions": []
        }
        """
        let fileURL = try createTempFile(with: json)

        XCTAssertThrowsError(try importService.importFromJSON(fileURL: fileURL, mode: .replace)) { error in
            guard let importError = error as? SubscriptionImportError else {
                XCTFail("Expected SubscriptionImportError")
                return
            }
            if case .noSubscriptionsToImport = importError {
                // Expected
            } else {
                XCTFail("Expected noSubscriptionsToImport error")
            }
        }
    }

    func testImportReplaceModeSuccess() throws {
        // Create existing subscription
        _ = try SubscriptionManager.shared.createSubscription(
            name: "Existing",
            price: 5.99,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSince1970: 1_700_000_000),
            currencyCode: "USD"
        )
        XCTAssertEqual(SubscriptionManager.shared.allSubscriptions().count, 1)

        let json = """
        {
            "version": 1,
            "exportedAt": "2025-01-15T10:00:00Z",
            "subscriptions": [
                {
                    "id": "12345678-1234-1234-1234-123456789012",
                    "name": "Netflix",
                    "price": 15.99,
                    "cycle": "Monthly",
                    "lastBillingDate": "2025-01-01T00:00:00Z",
                    "currencyCode": "USD",
                    "reminderIntervals": [1, 7]
                }
            ]
        }
        """
        let fileURL = try createTempFile(with: json)

        let result = try importService.importFromJSON(fileURL: fileURL, mode: .replace)

        XCTAssertEqual(result.imported, 1)
        XCTAssertEqual(result.skipped, 0)
        XCTAssertEqual(result.total, 1)

        // Old subscription should be gone, only new one exists
        let subscriptions = SubscriptionManager.shared.allSubscriptions()
        XCTAssertEqual(subscriptions.count, 1)
        XCTAssertEqual(subscriptions.first?.name, "Netflix")
    }

    func testImportMergeModeSkipsDuplicates() throws {
        // Create existing subscription
        _ = try SubscriptionManager.shared.createSubscription(
            name: "Netflix",
            price: 15.99,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSince1970: 1_700_000_000),
            currencyCode: "USD"
        )

        let json = """
        {
            "version": 1,
            "exportedAt": "2025-01-15T10:00:00Z",
            "subscriptions": [
                {
                    "id": "12345678-1234-1234-1234-123456789012",
                    "name": "Netflix",
                    "price": 15.99,
                    "cycle": "Monthly",
                    "lastBillingDate": "2025-01-01T00:00:00Z",
                    "currencyCode": "USD",
                    "reminderIntervals": []
                },
                {
                    "id": "87654321-4321-4321-4321-210987654321",
                    "name": "Spotify",
                    "price": 9.99,
                    "cycle": "Monthly",
                    "lastBillingDate": "2025-01-01T00:00:00Z",
                    "currencyCode": "USD",
                    "reminderIntervals": []
                }
            ]
        }
        """
        let fileURL = try createTempFile(with: json)

        let result = try importService.importFromJSON(fileURL: fileURL, mode: .merge)

        XCTAssertEqual(result.imported, 1)
        XCTAssertEqual(result.skipped, 1)
        XCTAssertEqual(result.total, 2)

        let subscriptions = SubscriptionManager.shared.allSubscriptions()
        XCTAssertEqual(subscriptions.count, 2)
    }

    func testImportInvalidJSONThrowsError() throws {
        let json = "{ invalid json }"
        let fileURL = try createTempFile(with: json)

        XCTAssertThrowsError(try importService.importFromJSON(fileURL: fileURL, mode: .replace)) { error in
            guard let importError = error as? SubscriptionImportError else {
                XCTFail("Expected SubscriptionImportError")
                return
            }
            if case .decodingFailed = importError {
                // Expected
            } else {
                XCTFail("Expected decodingFailed error")
            }
        }
    }

    func testImportUnsupportedVersionThrowsError() throws {
        let json = """
        {
            "version": 999,
            "exportedAt": "2025-01-15T10:00:00Z",
            "subscriptions": []
        }
        """
        let fileURL = try createTempFile(with: json)

        XCTAssertThrowsError(try importService.previewImport(fileURL: fileURL)) { error in
            guard let importError = error as? SubscriptionImportError else {
                XCTFail("Expected SubscriptionImportError")
                return
            }
            if case let .unsupportedVersion(version) = importError {
                XCTAssertEqual(version, 999)
            } else {
                XCTFail("Expected unsupportedVersion error")
            }
        }
    }

    func testImportNonExistentFileThrowsError() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("non-existent-file.json")

        XCTAssertThrowsError(try importService.importFromJSON(fileURL: fileURL, mode: .replace)) { error in
            guard let importError = error as? SubscriptionImportError else {
                XCTFail("Expected SubscriptionImportError")
                return
            }
            if case .fileReadFailed = importError {
                // Expected
            } else {
                XCTFail("Expected fileReadFailed error")
            }
        }
    }

    func testPreviewImport() throws {
        let json = """
        {
            "version": 1,
            "exportedAt": "2025-01-15T10:00:00Z",
            "subscriptions": [
                {
                    "id": "12345678-1234-1234-1234-123456789012",
                    "name": "Netflix",
                    "price": 15.99,
                    "cycle": "Monthly",
                    "lastBillingDate": "2025-01-01T00:00:00Z",
                    "currencyCode": "USD",
                    "reminderIntervals": []
                }
            ]
        }
        """
        let fileURL = try createTempFile(with: json)

        let exportData = try importService.previewImport(fileURL: fileURL)

        XCTAssertEqual(exportData.version, 1)
        XCTAssertEqual(exportData.subscriptions.count, 1)
        XCTAssertEqual(exportData.subscriptions.first?.name, "Netflix")

        // Preview should not modify data
        XCTAssertEqual(SubscriptionManager.shared.allSubscriptions().count, 0)
    }

    func testImportWithIconsRestoresIconFiles() throws {
        let iconsDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("subzen-import-icons-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: iconsDirectory) }

        let iconFileStore = SubscriptionIconFileStore(iconsDirectoryURL: iconsDirectory)
        importService = SubscriptionImportService(iconFileStore: iconFileStore)

        let exportSubscription = try Subscription(
            name: "Netflix",
            price: 15.99,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSince1970: 1_700_000_000),
            currencyCode: "USD",
            reminderIntervals: []
        )
        exportSubscription.id = UUID()

        let iconPayload = Data([9, 8, 7, 6, 5])
        let exportData = SubscriptionExportData(
            version: SubscriptionExportData.currentVersion,
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            subscriptions: [exportSubscription],
            icons: [SubscriptionIconExport(subscriptionID: exportSubscription.id, pngData: iconPayload)]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-import-\(UUID().uuidString).json")
        tempFileURL = fileURL
        try encoder.encode(exportData).write(to: fileURL, options: .atomic)

        let result = try importService.importFromJSON(fileURL: fileURL, mode: .replace)
        XCTAssertEqual(result.imported, 1)
        XCTAssertEqual(result.skipped, 0)

        guard let created = SubscriptionManager.shared.allSubscriptions().first else {
            XCTFail("Expected imported subscription")
            return
        }

        XCTAssertTrue(iconFileStore.iconExists(for: created.id))
        XCTAssertEqual(try iconFileStore.loadIconData(for: created.id), iconPayload)
    }
}
