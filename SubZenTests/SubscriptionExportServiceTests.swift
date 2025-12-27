@testable import SubZen
import XCTest

final class SubscriptionExportServiceTests: XCTestCase {
    private var exportService: SubscriptionExportService!
    private var testSubscriptions: [Subscription]!
    private var fileManager: FileManager!

    override func setUp() {
        super.setUp()
        fileManager = .default
        testSubscriptions = []
    }

    override func tearDown() {
        exportService = nil
        testSubscriptions = nil
        super.tearDown()
    }

    func testExportEmptySubscriptionList() throws {
        exportService = SubscriptionExportService(subscriptionProvider: { [] })

        let fileURL = try exportService.exportToJSON()
        XCTAssertTrue(fileManager.fileExists(atPath: fileURL.path))

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(SubscriptionExportData.self, from: data)

        XCTAssertEqual(exportData.version, SubscriptionExportData.currentVersion)
        XCTAssertTrue(exportData.subscriptions.isEmpty)

        exportService.cleanupExportFile(at: fileURL)
        XCTAssertFalse(fileManager.fileExists(atPath: fileURL.path))
    }

    func testExportWithSubscriptions() throws {
        let subscription1 = try Subscription(
            name: "Netflix",
            price: 15.99,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSince1970: 1_700_000_000),
            currencyCode: "USD",
            reminderIntervals: [1, 7]
        )

        let subscription2 = try Subscription(
            name: "Spotify",
            price: 9.99,
            cycle: .monthly,
            lastBillingDate: Date(timeIntervalSince1970: 1_700_000_000),
            currencyCode: "USD",
            reminderIntervals: []
        )

        testSubscriptions = [subscription1, subscription2]
        exportService = SubscriptionExportService(subscriptionProvider: { [weak self] in
            self?.testSubscriptions ?? []
        })

        let fileURL = try exportService.exportToJSON()
        XCTAssertTrue(fileManager.fileExists(atPath: fileURL.path))

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(SubscriptionExportData.self, from: data)

        XCTAssertEqual(exportData.version, SubscriptionExportData.currentVersion)
        XCTAssertEqual(exportData.subscriptions.count, 2)

        let exportedNetflix = exportData.subscriptions.first { $0.name == "Netflix" }
        XCTAssertNotNil(exportedNetflix)
        XCTAssertEqual(exportedNetflix?.price, 15.99)
        XCTAssertEqual(exportedNetflix?.cycle, .monthly)
        XCTAssertEqual(exportedNetflix?.currencyCode, "USD")
        XCTAssertEqual(exportedNetflix?.reminderIntervals, [1, 7])

        exportService.cleanupExportFile(at: fileURL)
    }

    func testExportFileNameFormat() throws {
        exportService = SubscriptionExportService(subscriptionProvider: { [] })

        let fileURL = try exportService.exportToJSON()
        let fileName = fileURL.lastPathComponent

        XCTAssertTrue(fileName.hasPrefix("SubZen-Subscriptions-"))
        XCTAssertTrue(fileName.hasSuffix(".json"))

        exportService.cleanupExportFile(at: fileURL)
    }

    func testExportedAtTimestamp() throws {
        exportService = SubscriptionExportService(subscriptionProvider: { [] })

        let beforeExport = Date()
        let fileURL = try exportService.exportToJSON()
        let afterExport = Date()

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(SubscriptionExportData.self, from: data)

        // Allow 1 second tolerance for timing differences
        XCTAssertGreaterThanOrEqual(exportData.exportedAt.timeIntervalSince1970, beforeExport.timeIntervalSince1970 - 1)
        XCTAssertLessThanOrEqual(exportData.exportedAt.timeIntervalSince1970, afterExport.timeIntervalSince1970 + 1)

        exportService.cleanupExportFile(at: fileURL)
    }

    func testCleanupNonExistentFile() {
        exportService = SubscriptionExportService(subscriptionProvider: { [] })

        let nonExistentURL = fileManager.temporaryDirectory.appendingPathComponent("non-existent-file.json")
        exportService.cleanupExportFile(at: nonExistentURL)
    }
}
