@testable import SubZen
import CoreGraphics
import Foundation
import XCTest

final class SubscriptionIconRemoteServiceTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.requestHandler = nil
    }

    func testFetchIconData_whenURLIsDirectImage_fetchesOnce() async throws {
        var requestedURLs: [URL] = []
        let iconURL = try XCTUnwrap(URL(string: "https://example.com/icon.png"))
        let iconData = try make1x1PNGData()

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            requestedURLs.append(url)

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "image/png"]
                )
            )
            return (response, iconData)
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let service = SubscriptionIconRemoteService(urlSession: session)
        let data = try await service.fetchIconData(from: iconURL)

        XCTAssertEqual(requestedURLs, [iconURL])
        XCTAssertEqual(data, iconData)
    }

    func testFetchIconData_whenHTMLContainsAppleTouchIcon_prefersLargest() async throws {
        var requestedURLs: [URL] = []
        let pageURL = try XCTUnwrap(URL(string: "https://example.com/pricing"))
        let expectedIconURL = try XCTUnwrap(URL(string: "https://example.com/icons/touch-180.png"))
        let expectedIconData = try make1x1PNGData()

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            requestedURLs.append(url)

            switch (url.host, url.path) {
            case ("example.com", "/pricing"):
                let html = """
                <html><head>
                  <link rel="icon" href="/favicon-32.png" sizes="32x32">
                  <link rel="apple-touch-icon" href="/icons/touch-180.png" sizes="180x180">
                </head></html>
                """
                let data = try XCTUnwrap(html.data(using: .utf8))
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "text/html; charset=utf-8"]
                    )
                )
                return (response, data)
            case ("example.com", "/icons/touch-180.png"):
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "image/png"]
                    )
                )
                return (response, expectedIconData)
            default:
                let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
                return (response, Data())
            }
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let service = SubscriptionIconRemoteService(urlSession: session)
        let data = try await service.fetchIconData(from: pageURL)

        XCTAssertEqual(requestedURLs, [pageURL, expectedIconURL])
        XCTAssertEqual(data, expectedIconData)
    }

    func testFetchIconData_whenNoIconLinks_fallsBackToFaviconDotIco() async throws {
        var requestedURLs: [URL] = []
        let pageURL = try XCTUnwrap(URL(string: "https://example.com/pricing"))
        let faviconURL = try XCTUnwrap(URL(string: "https://example.com/favicon.ico"))
        let faviconData = try make1x1PNGData()

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            requestedURLs.append(url)

            switch (url.host, url.path) {
            case ("example.com", "/pricing"):
                let html = "<html><head></head><body>hello</body></html>"
                let data = try XCTUnwrap(html.data(using: .utf8))
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "text/html"]
                    )
                )
                return (response, data)
            case ("example.com", "/favicon.ico"):
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "image/x-icon"]
                    )
                )
                return (response, faviconData)
            default:
                let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
                return (response, Data())
            }
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let service = SubscriptionIconRemoteService(urlSession: session)
        let data = try await service.fetchIconData(from: pageURL)

        XCTAssertEqual(requestedURLs, [pageURL, faviconURL])
        XCTAssertEqual(data, faviconData)
    }

    func testFetchIconData_whenManifestProvidesIcons_usesLargest() async throws {
        var requestedURLs: [URL] = []
        let pageURL = try XCTUnwrap(URL(string: "https://example.com/pricing"))
        let manifestURL = try XCTUnwrap(URL(string: "https://example.com/manifest.webmanifest"))
        let expectedIconURL = try XCTUnwrap(URL(string: "https://example.com/icons/icon-512.png"))
        let expectedIconData = try make1x1PNGData()

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            requestedURLs.append(url)

            switch (url.host, url.path) {
            case ("example.com", "/pricing"):
                let html = """
                <html><head>
                  <link rel="manifest" href="/manifest.webmanifest">
                </head></html>
                """
                let data = try XCTUnwrap(html.data(using: .utf8))
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "text/html"]
                    )
                )
                return (response, data)
            case ("example.com", "/manifest.webmanifest"):
                let json = """
                {
                  "icons": [
                    {
                      "src": "/icons/icon-192.png",
                      "sizes": "192x192",
                      "type": "image/png"
                    },
                    {
                      "src": "/icons/icon-512.png",
                      "sizes": "512x512",
                      "type": "image/png"
                    }
                  ]
                }
                """
                let data = try XCTUnwrap(json.data(using: .utf8))
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/manifest+json"]
                    )
                )
                return (response, data)
            case ("example.com", "/icons/icon-512.png"):
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "image/png"]
                    )
                )
                return (response, expectedIconData)
            default:
                let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
                return (response, Data())
            }
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let service = SubscriptionIconRemoteService(urlSession: session)
        let data = try await service.fetchIconData(from: pageURL)

        XCTAssertEqual(requestedURLs, [pageURL, manifestURL, expectedIconURL])
        XCTAssertEqual(data, expectedIconData)
    }

    func testFetchIconData_whenIconLinkIsSVG_usesRasterizer() async throws {
        var requestedURLs: [URL] = []
        let pageURL = try XCTUnwrap(URL(string: "https://example.com/"))
        let svgURL = try XCTUnwrap(URL(string: "https://example.com/favicon.svg"))
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
          <rect width="64" height="64" fill="#FF0000"/>
        </svg>
        """
        let svgData = try XCTUnwrap(svg.data(using: .utf8))
        let rasterizedData = try make1x1PNGData()

        let rasterizer = SVGRasterizerStub { receivedData, baseURL, size in
            XCTAssertEqual(receivedData, svgData)
            XCTAssertEqual(baseURL, svgURL)
            XCTAssertEqual(size, 256)
            return rasterizedData
        }

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            requestedURLs.append(url)

            switch (url.host, url.path) {
            case ("example.com", "/"):
                let html = """
                <html><head>
                  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
                </head></html>
                """
                let data = try XCTUnwrap(html.data(using: .utf8))
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "text/html; charset=utf-8"]
                    )
                )
                return (response, data)
            case ("example.com", "/favicon.svg"):
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "image/svg+xml"]
                    )
                )
                return (response, svgData)
            default:
                let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
                return (response, Data())
            }
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let service = SubscriptionIconRemoteService(urlSession: session, svgRasterizer: rasterizer)
        let data = try await service.fetchIconData(from: pageURL)

        XCTAssertEqual(requestedURLs, [pageURL, svgURL])
        XCTAssertEqual(data, rasterizedData)
    }

    func testFetchIconData_whenOpenGraphAndFaviconAvailable_prefersFavicon() async throws {
        var requestedURLs: [URL] = []
        let pageURL = try XCTUnwrap(URL(string: "https://example.com/"))
        let faviconURL = try XCTUnwrap(URL(string: "https://example.com/favicon.ico"))
        let faviconData = try make1x1PNGData()

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            requestedURLs.append(url)

            switch (url.host, url.path) {
            case ("example.com", "/"):
                let html = """
                <html><head>
                  <meta property="og:image" content="https://cdn.example.com/og.png">
                </head></html>
                """
                let data = try XCTUnwrap(html.data(using: .utf8))
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "text/html; charset=utf-8"]
                    )
                )
                return (response, data)
            case ("example.com", "/favicon.ico"):
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "image/x-icon"]
                    )
                )
                return (response, faviconData)
            default:
                let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
                return (response, Data())
            }
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let service = SubscriptionIconRemoteService(urlSession: session)
        let data = try await service.fetchIconData(from: pageURL)

        XCTAssertEqual(requestedURLs, [pageURL, faviconURL])
        XCTAssertEqual(data, faviconData)
    }

    func testFetchIconData_whenRootReturnsNonSquareImage_fallsBackToFavicon() async throws {
        var requestedURLs: [URL] = []
        let pageURL = try XCTUnwrap(URL(string: "https://example.com/"))
        let faviconURL = try XCTUnwrap(URL(string: "https://example.com/favicon.ico"))

        let homepageData = try make2x1PNGData()
        let faviconData = try make1x1PNGData()

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            requestedURLs.append(url)

            switch (url.host, url.path) {
            case ("example.com", "/"):
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "image/png"]
                    )
                )
                return (response, homepageData)
            case ("example.com", "/favicon.ico"):
                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "image/x-icon"]
                    )
                )
                return (response, faviconData)
            default:
                let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
                return (response, Data())
            }
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let service = SubscriptionIconRemoteService(urlSession: session)
        let data = try await service.fetchIconData(from: pageURL)

        XCTAssertEqual(requestedURLs, [pageURL, faviconURL])
        XCTAssertEqual(data, faviconData)
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

    private func make1x1PNGData() throws -> Data {
        let base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+XWfQAAAAASUVORK5CYII="
        return try XCTUnwrap(Data(base64Encoded: base64))
    }

    private func make2x1PNGData() throws -> Data {
        let base64 = "iVBORw0KGgoAAAANSUhEUgAAAAIAAAABCAYAAAD0In+KAAAAC0lEQVR4nGNggAIAAAkAAftSuKkAAAAASUVORK5CYII="
        return try XCTUnwrap(Data(base64Encoded: base64))
    }
}

private struct SVGRasterizerStub: SubscriptionIconSVGRasterizing {
    var handler: (Data, URL, CGFloat) throws -> Data

    @MainActor
    func rasterize(svgData: Data, baseURL: URL, size: CGFloat) async throws -> Data {
        try handler(svgData, baseURL, size)
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
