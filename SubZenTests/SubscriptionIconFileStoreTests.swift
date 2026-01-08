@testable import SubZen
import XCTest

final class SubscriptionIconFileStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("subzen-icon-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        super.tearDown()
    }

    func testSaveLoadRemoveFlow() throws {
        let store = SubscriptionIconFileStore(iconsDirectoryURL: tempDirectory)
        let id = UUID()
        let payload = Data([0, 1, 2, 3, 4])

        XCTAssertFalse(store.iconExists(for: id))
        XCTAssertNil(try store.loadIconData(for: id))

        try store.saveIconData(payload, for: id)
        XCTAssertTrue(store.iconExists(for: id))
        XCTAssertEqual(try store.loadIconData(for: id), payload)

        try store.removeIcon(for: id)
        XCTAssertFalse(store.iconExists(for: id))
        XCTAssertNil(try store.loadIconData(for: id))
    }

    func testRemoveAllIconsIsSafe() throws {
        let store = SubscriptionIconFileStore(iconsDirectoryURL: tempDirectory)
        try store.removeAllIcons()
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.path))
    }
}

