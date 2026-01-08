@testable import SubZen
import Foundation
import XCTest

final class SubscriptionIconRemoteServiceTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.requestHandler = nil
    }

    func testSearchAppStoreApps_decodesResults() async throws {
        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

            XCTAssertEqual(components.host, "itunes.apple.com")
            XCTAssertEqual(components.path, "/search")

            let items = components.queryItems ?? []
            let byName = Dictionary(uniqueKeysWithValues: items.compactMap { item in
                guard let value = item.value else { return nil }
                return (item.name, value)
            })
            XCTAssertEqual(byName["term"], "Test App")
            XCTAssertEqual(byName["entity"], "software")
            XCTAssertEqual(byName["limit"], "3")

            let json = """
            {
              "resultCount": 2,
              "results": [
                {
                  "trackId": 123,
                  "trackName": "App One",
                  "sellerName": "Example Seller",
                  "artworkUrl60": "https://example.com/60.png",
                  "artworkUrl100": "https://example.com/100.png",
                  "artworkUrl512": "https://example.com/512.png"
                },
                {
                  "trackId": 456,
                  "trackName": "App Two",
                  "sellerName": "Another Seller",
                  "artworkUrl100": "https://example.com/100b.png"
                }
              ]
            }
            """
            let data = try XCTUnwrap(json.data(using: .utf8))
            let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
            return (response, data)
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let service = SubscriptionIconRemoteService(urlSession: session)
        let results = try await service.searchAppStoreApps(term: "Test App", limit: 3)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].appID, 123)
        XCTAssertEqual(results[0].name, "App One")
        XCTAssertEqual(results[0].sellerName, "Example Seller")
        XCTAssertEqual(results[0].preferredArtworkURL?.absoluteString, "https://example.com/512.png")

        XCTAssertEqual(results[1].appID, 456)
        XCTAssertEqual(results[1].name, "App Two")
        XCTAssertEqual(results[1].sellerName, "Another Seller")
        XCTAssertEqual(results[1].preferredArtworkURL?.absoluteString, "https://example.com/100b.png")
    }
}

private final class URLProtocolStub: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)
    static var requestHandler: Handler?

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

