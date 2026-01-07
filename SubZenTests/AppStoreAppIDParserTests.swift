@testable import SubZen
import XCTest

final class AppStoreAppIDParserTests: XCTestCase {
    func testParseDirectID() {
        XCTAssertEqual(AppStoreAppIDParser.parseAppID(from: "389801252"), 389801252)
        XCTAssertEqual(AppStoreAppIDParser.parseAppID(from: "  123456789  "), 123456789)
    }

    func testParseFromAppStoreURL() {
        XCTAssertEqual(
            AppStoreAppIDParser.parseAppID(from: "https://apps.apple.com/us/app/instagram/id389801252"),
            389801252
        )
        XCTAssertEqual(
            AppStoreAppIDParser.parseAppID(from: "https://apps.apple.com/app/id123456789?mt=8"),
            123456789
        )
    }

    func testParseInvalidInputReturnsNil() {
        XCTAssertNil(AppStoreAppIDParser.parseAppID(from: ""))
        XCTAssertNil(AppStoreAppIDParser.parseAppID(from: "not-a-url"))
        XCTAssertNil(AppStoreAppIDParser.parseAppID(from: "https://apps.apple.com/us/app/some-app/"))
    }
}

