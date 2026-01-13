//
//  SubscriptionIconRemoteService.swift
//  SubZen
//
//  Created by Codex on 2026/1/7.
//

import Foundation
import ImageIO
import UIKit
import WebKit

enum SubscriptionIconRemoteServiceError: LocalizedError {
    case invalidURL
    case unsupportedScheme
    case requestFailed(statusCode: Int)
    case invalidResponse
    case imageTooLarge(maxBytes: Int)
    case appStoreLookupNoResults
    case appStoreArtworkMissing

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "Please enter a valid URL.")
        case .unsupportedScheme:
            return String(localized: "Only https URLs are supported.")
        case let .requestFailed(statusCode):
            let key: String.LocalizationValue = "Request failed with status code \(Int64(statusCode))."
            return String(localized: key)
        case .invalidResponse:
            return String(localized: "The server returned an invalid response.")
        case let .imageTooLarge(maxBytes):
            let key: String.LocalizationValue = "The image is too large (max \(Int64(maxBytes)) bytes)."
            return String(localized: key)
        case .appStoreLookupNoResults:
            return String(localized: "No App Store results found for that app id.")
        case .appStoreArtworkMissing:
            return String(localized: "No App Store artwork URL was returned.")
        }
    }
}

final class SubscriptionIconRemoteService {
    private enum Constants {
        static let defaultMaxBytes = 10 * 1024 * 1024
        static let defaultManifestMaxBytes = 1024 * 1024
        static let defaultAppStoreSearchLimit = 25
        static let svgRasterizeSize: CGFloat = 256
    }

    private let urlSession: URLSession
    private let svgRasterizer: SubscriptionIconSVGRasterizing

    init(
        urlSession: URLSession? = nil,
        svgRasterizer: SubscriptionIconSVGRasterizing = WebKitSubscriptionIconSVGRasterizer()
    ) {
        self.svgRasterizer = svgRasterizer
        if let urlSession {
            self.urlSession = urlSession
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.urlCache = nil
            configuration.waitsForConnectivity = false
            self.urlSession = URLSession(configuration: configuration)
        }
    }

    func fetchImageData(from url: URL, maxBytes: Int = Constants.defaultMaxBytes) async throws -> Data {
        let (data, _) = try await fetchData(from: url, maxBytes: maxBytes)
        return data
    }

    func fetchIconData(from url: URL, maxBytes: Int = Constants.defaultMaxBytes) async throws -> Data {
        do {
            let (data, response) = try await fetchData(from: url, maxBytes: maxBytes)
            let finalURL = response.url ?? url

            if isImageResponse(response, for: finalURL) || looksLikeImageData(data) {
                if let dimensions = imageDimensions(from: data) {
                    if shouldTreatDirectImageAsIcon(finalURL, dimensions: dimensions) {
                        return data
                    }
                }
            }

            let discovery = await discoverIconURLs(in: data, pageURL: finalURL)
            for candidateURL in discovery.iconURLs {
                if let candidateData = try? await fetchValidatedImageData(from: candidateURL, maxBytes: maxBytes, requireSquareLike: true) {
                    return candidateData
                }
            }

            for candidateURL in discovery.metaURLs {
                if let candidateData = try? await fetchValidatedImageData(from: candidateURL, maxBytes: maxBytes, requireSquareLike: false) {
                    return candidateData
                }
            }

            throw SubscriptionIconRemoteServiceError.invalidResponse
        } catch SubscriptionIconRemoteServiceError.unsupportedScheme {
            throw SubscriptionIconRemoteServiceError.unsupportedScheme
        } catch SubscriptionIconRemoteServiceError.invalidURL {
            throw SubscriptionIconRemoteServiceError.invalidURL
        } catch {
            for fallbackURL in fallbackIconURLs(for: url) {
                if let data = try? await fetchValidatedImageData(from: fallbackURL, maxBytes: maxBytes, requireSquareLike: true) {
                    return data
                }
            }
            throw error
        }
    }

    func fetchAppStoreArtworkURL(appID: Int) async throws -> URL {
        guard var components = URLComponents(string: "https://itunes.apple.com/lookup") else {
            throw SubscriptionIconRemoteServiceError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "id", value: String(appID)),
        ]

        guard let url = components.url else {
            throw SubscriptionIconRemoteServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SubscriptionIconRemoteServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SubscriptionIconRemoteServiceError.requestFailed(statusCode: http.statusCode)
        }

        let lookup: AppStoreLookupResponse
        do {
            lookup = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
        } catch {
            throw SubscriptionIconRemoteServiceError.invalidResponse
        }

        guard let first = lookup.results.first else {
            throw SubscriptionIconRemoteServiceError.appStoreLookupNoResults
        }

        if let url = first.artworkUrl512 ?? first.artworkUrl100 ?? first.artworkUrl60 {
            return url
        }

        throw SubscriptionIconRemoteServiceError.appStoreArtworkMissing
    }

    func searchAppStoreApps(
        term: String,
        limit: Int = Constants.defaultAppStoreSearchLimit
    ) async throws -> [AppStoreSearchResult] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        guard var components = URLComponents(string: "https://itunes.apple.com/search") else {
            throw SubscriptionIconRemoteServiceError.invalidURL
        }

        let countryCode = Locale.current.region?.identifier.lowercased()
        var queryItems = [
            URLQueryItem(name: "term", value: trimmed),
            URLQueryItem(name: "entity", value: "software"),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        if let countryCode {
            queryItems.append(URLQueryItem(name: "country", value: countryCode))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw SubscriptionIconRemoteServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SubscriptionIconRemoteServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SubscriptionIconRemoteServiceError.requestFailed(statusCode: http.statusCode)
        }

        let search: AppStoreSearchResponse
        do {
            search = try JSONDecoder().decode(AppStoreSearchResponse.self, from: data)
        } catch {
            throw SubscriptionIconRemoteServiceError.invalidResponse
        }
        return search.results
    }

    private func fetchData(from url: URL, maxBytes: Int) async throws -> (Data, HTTPURLResponse) {
        guard url.scheme?.lowercased() == "https" else {
            throw SubscriptionIconRemoteServiceError.unsupportedScheme
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SubscriptionIconRemoteServiceError.invalidResponse
        }
        guard let finalURL = http.url else {
            throw SubscriptionIconRemoteServiceError.invalidResponse
        }
        guard finalURL.scheme?.lowercased() == "https" else {
            throw SubscriptionIconRemoteServiceError.unsupportedScheme
        }
        guard (200...299).contains(http.statusCode) else {
            throw SubscriptionIconRemoteServiceError.requestFailed(statusCode: http.statusCode)
        }
        guard data.count <= maxBytes else {
            throw SubscriptionIconRemoteServiceError.imageTooLarge(maxBytes: maxBytes)
        }
        return (data, http)
    }

    private struct IconURLDiscovery {
        let iconURLs: [URL]
        let metaURLs: [URL]
    }

    private func discoverIconURLs(in htmlData: Data, pageURL: URL) async -> IconURLDiscovery {
        let html = String(decoding: htmlData, as: UTF8.self)
        let parsed = parseIconCandidates(in: html, pageURL: pageURL)

        var iconURLs: [URL] = []
        var metaURLs: [URL] = []
        var seen = Set<URL>()

        for candidate in parsed.iconCandidates.sorted(by: IconCandidate.isBetter(_:_:)) {
            if seen.insert(candidate.url).inserted {
                iconURLs.append(candidate.url)
            }
        }

        if let manifestURL = parsed.manifestURL,
           let manifestURLs = try? await discoverManifestIconURLs(from: manifestURL, maxBytes: Constants.defaultManifestMaxBytes)
        {
            for url in manifestURLs {
                if seen.insert(url).inserted {
                    iconURLs.append(url)
                }
            }
        }

        for url in fallbackIconURLs(for: pageURL) {
            if seen.insert(url).inserted {
                iconURLs.append(url)
            }
        }

        for url in parsed.metaImageURLs {
            if seen.insert(url).inserted {
                metaURLs.append(url)
            }
        }

        return IconURLDiscovery(iconURLs: iconURLs, metaURLs: metaURLs)
    }

    private func discoverManifestIconURLs(from manifestURL: URL, maxBytes: Int) async throws -> [URL] {
        let (data, _) = try await fetchData(from: manifestURL, maxBytes: maxBytes)

        let manifest: WebManifest
        do {
            manifest = try JSONDecoder().decode(WebManifest.self, from: data)
        } catch {
            return []
        }

        let candidates = manifest.icons?.compactMap { icon -> IconCandidate? in
            let src = icon.src.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !src.isEmpty else { return nil }
            guard let resolved = resolveIconURL(from: src, baseURL: manifestURL) else { return nil }

            return IconCandidate(
                url: resolved,
                kind: .icon,
                pixelArea: IconCandidate.parseLargestPixelArea(from: icon.sizes),
                formatPriority: IconCandidate.formatPriority(for: resolved)
            )
        } ?? []

        return candidates
            .sorted(by: IconCandidate.isBetter(_:_:))
            .map(\.url)
    }

    private func parseIconCandidates(in html: String, pageURL: URL) -> ParsedIconCandidates {
        let tags = Self.linkTags(in: html)
        let metaTags = Self.metaTags(in: html)

        var iconCandidates: [IconCandidate] = []
        var manifestURL: URL?
        var metaImageURLs: [URL] = []

        for tag in tags {
            guard let relValue = Self.attributeValue(named: "rel", in: tag) else { continue }
            guard let hrefValue = Self.attributeValue(named: "href", in: tag) else { continue }

            let relTokens = Set(
                relValue
                    .lowercased()
                    .split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" || $0 == "\r" })
                    .map(String.init)
            )

            if relTokens.contains("manifest") {
                manifestURL = resolveIconURL(from: hrefValue, baseURL: pageURL)
                continue
            }

            guard let kind = IconCandidate.Kind(kindForRelTokens: relTokens) else { continue }
            guard let resolved = resolveIconURL(from: hrefValue, baseURL: pageURL) else { continue }

            let sizesValue = Self.attributeValue(named: "sizes", in: tag)
            iconCandidates.append(
                IconCandidate(
                    url: resolved,
                    kind: kind,
                    pixelArea: IconCandidate.parseLargestPixelArea(from: sizesValue),
                    formatPriority: IconCandidate.formatPriority(for: resolved)
                )
            )
        }

        for tag in metaTags {
            guard let contentValue = Self.attributeValue(named: "content", in: tag) else { continue }
            guard let keyValue = (Self.attributeValue(named: "property", in: tag) ?? Self.attributeValue(named: "name", in: tag))?.lowercased() else {
                continue
            }

            if keyValue == "og:image" || keyValue == "og:image:url" || keyValue == "twitter:image" || keyValue == "msapplication-tileimage" {
                guard let resolved = resolveIconURL(from: contentValue, baseURL: pageURL) else { continue }
                metaImageURLs.append(resolved)
            }
        }

        return ParsedIconCandidates(
            iconCandidates: iconCandidates,
            manifestURL: manifestURL,
            metaImageURLs: metaImageURLs
        )
    }

    private func resolveIconURL(from href: String, baseURL: URL) -> URL? {
        let trimmed = href.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !trimmed.lowercased().hasPrefix("data:") else { return nil }

        let resolved: URL?
        if trimmed.hasPrefix("//") {
            let scheme = baseURL.scheme ?? "https"
            resolved = URL(string: "\(scheme):\(trimmed)")
        } else {
            resolved = URL(string: trimmed, relativeTo: baseURL)?.absoluteURL
        }

        guard let resolved else { return nil }
        return ensureHTTPS(resolved, relativeTo: baseURL)
    }

    private func ensureHTTPS(_ url: URL, relativeTo baseURL: URL) -> URL? {
        guard let scheme = url.scheme?.lowercased() else { return nil }
        if scheme == "https" {
            return url
        }

        if scheme == "http", baseURL.scheme?.lowercased() == "https", url.host == baseURL.host {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
            components.scheme = "https"
            return components.url
        }

        return nil
    }

    private func fallbackIconURLs(for url: URL) -> [URL] {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return [] }
        components.path = ""
        components.query = nil
        components.fragment = nil

        guard let origin = components.url else { return [] }

        return [
            origin.appendingPathComponent("favicon.ico"),
            origin.appendingPathComponent("favicon.svg"),
            origin.appendingPathComponent("favicon.png"),
            origin.appendingPathComponent("favicon-32x32.png"),
            origin.appendingPathComponent("favicon-16x16.png"),
            origin.appendingPathComponent("apple-touch-icon.png"),
            origin.appendingPathComponent("apple-touch-icon-precomposed.png"),
            origin.appendingPathComponent("android-chrome-512x512.png"),
            origin.appendingPathComponent("android-chrome-192x192.png"),
        ]
    }

    private func isImageResponse(_ response: HTTPURLResponse, for url: URL) -> Bool {
        if let mimeType = response.mimeType?.lowercased() {
            if mimeType == "image/svg+xml" {
                return false
            }
            if mimeType.hasPrefix("image/") {
                return true
            }
            if mimeType.contains("html") {
                return false
            }
        }

        return IconCandidate.formatPriority(for: url) > 0
    }

    private func fetchValidatedImageData(from url: URL, maxBytes: Int, requireSquareLike: Bool = false) async throws -> Data {
        let (data, response) = try await fetchData(from: url, maxBytes: maxBytes)
        let finalURL = response.url ?? url

        if looksLikeSVGResponse(response, for: finalURL, data: data) {
            let pngData = try await svgRasterizer.rasterize(
                svgData: data,
                baseURL: finalURL,
                size: Constants.svgRasterizeSize
            )
            guard let dimensions = imageDimensions(from: pngData) else {
                throw SubscriptionIconRemoteServiceError.invalidResponse
            }
            if requireSquareLike, !isSquareLike(dimensions) {
                throw SubscriptionIconRemoteServiceError.invalidResponse
            }
            return pngData
        }

        guard isImageResponse(response, for: finalURL) || looksLikeImageData(data) else {
            throw SubscriptionIconRemoteServiceError.invalidResponse
        }
        guard let dimensions = imageDimensions(from: data) else {
            throw SubscriptionIconRemoteServiceError.invalidResponse
        }
        if requireSquareLike, !isSquareLike(dimensions) {
            throw SubscriptionIconRemoteServiceError.invalidResponse
        }

        return data
    }

    private func looksLikeSVGResponse(_ response: HTTPURLResponse, for url: URL, data: Data) -> Bool {
        if response.mimeType?.lowercased() == "image/svg+xml" {
            return true
        }
        if url.pathExtension.lowercased() == "svg" {
            return true
        }
        return looksLikeSVGData(data)
    }

    private func looksLikeSVGData(_ data: Data) -> Bool {
        let prefix = String(decoding: data.prefix(1024), as: UTF8.self).lowercased()
        return prefix.contains("<svg")
    }

    private func shouldTreatDirectImageAsIcon(_ url: URL, dimensions: ImageDimensions) -> Bool {
        let pathExtension = url.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pathExtension.isEmpty {
            return true
        }

        if url.path == "/", !isSquareLike(dimensions) {
            return false
        }

        return true
    }

    private struct ImageDimensions {
        let width: Int
        let height: Int
    }

    private func imageDimensions(from data: Data) -> ImageDimensions? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        guard CGImageSourceGetCount(source) > 0 else {
            return nil
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }

        let widthValue = properties[kCGImagePropertyPixelWidth]
        let heightValue = properties[kCGImagePropertyPixelHeight]

        guard let width = (widthValue as? NSNumber)?.intValue ?? widthValue as? Int else {
            return nil
        }
        guard let height = (heightValue as? NSNumber)?.intValue ?? heightValue as? Int else {
            return nil
        }

        return ImageDimensions(width: width, height: height)
    }

    private func isSquareLike(_ dimensions: ImageDimensions) -> Bool {
        let diff = abs(dimensions.width - dimensions.height)
        let tolerance = max(2, Int(Double(min(dimensions.width, dimensions.height)) * 0.05))
        return diff <= tolerance
    }

    private func looksLikeImageData(_ data: Data) -> Bool {
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            return true
        }
        if data.starts(with: [0xFF, 0xD8, 0xFF]) {
            return true
        }
        if data.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            return true
        }
        if data.starts(with: [0x00, 0x00, 0x01, 0x00]) {
            return true
        }
        if data.starts(with: [0x42, 0x4D]) {
            return true
        }
        if data.count >= 12, data.starts(with: [0x52, 0x49, 0x46, 0x46]) {
            let signature = [data[8], data[9], data[10], data[11]]
            return signature == [0x57, 0x45, 0x42, 0x50]
        }
        return false
    }

    private static func linkTags(in html: String) -> [String] {
        let pattern = "(?is)<link\\b[^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(html.startIndex..., in: html)
        return regex
            .matches(in: html, range: range)
            .compactMap { match -> String? in
                guard let tagRange = Range(match.range, in: html) else { return nil }
                return String(html[tagRange])
            }
    }

    private static func metaTags(in html: String) -> [String] {
        let pattern = "(?is)<meta\\b[^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(html.startIndex..., in: html)
        return regex
            .matches(in: html, range: range)
            .compactMap { match -> String? in
                guard let tagRange = Range(match.range, in: html) else { return nil }
                return String(html[tagRange])
            }
    }

    private static func attributeValue(named name: String, in tag: String) -> String? {
        let escapedName = NSRegularExpression.escapedPattern(for: name)
        let pattern = "(?is)\\b\(escapedName)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s>]+))"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(tag.startIndex..., in: tag)
        guard let match = regex.firstMatch(in: tag, range: range) else { return nil }

        for index in 1...3 {
            let matchRange = match.range(at: index)
            guard matchRange.location != NSNotFound else { continue }
            guard let range = Range(matchRange, in: tag) else { continue }
            return String(tag[range])
        }

        return nil
    }
}

private struct AppStoreLookupResponse: Decodable {
    let results: [AppStoreLookupResult]
}

private struct AppStoreLookupResult: Decodable {
    let artworkUrl60: URL?
    let artworkUrl100: URL?
    let artworkUrl512: URL?
}

struct AppStoreSearchResult: Decodable, Hashable {
    let appID: Int
    let name: String
    let sellerName: String?
    let artworkURL60: URL?
    let artworkURL100: URL?
    let artworkURL512: URL?

    var preferredArtworkURL: URL? {
        artworkURL512 ?? artworkURL100 ?? artworkURL60
    }

    var listArtworkURL: URL? {
        artworkURL100 ?? artworkURL60 ?? artworkURL512
    }

    private enum CodingKeys: String, CodingKey {
        case appID = "trackId"
        case name = "trackName"
        case sellerName
        case artworkURL60 = "artworkUrl60"
        case artworkURL100 = "artworkUrl100"
        case artworkURL512 = "artworkUrl512"
    }
}

private struct AppStoreSearchResponse: Decodable {
    let results: [AppStoreSearchResult]
}

private struct WebManifest: Decodable {
    let icons: [WebManifestIcon]?
}

private struct WebManifestIcon: Decodable {
    let src: String
    let sizes: String?
    let type: String?
}

private struct ParsedIconCandidates {
    let iconCandidates: [IconCandidate]
    let manifestURL: URL?
    let metaImageURLs: [URL]
}

private struct IconCandidate {
    enum Kind: Int {
        case icon
        case shortcutIcon
        case appleTouchIcon

        init?(kindForRelTokens tokens: Set<String>) {
            if tokens.contains("mask-icon") {
                return nil
            }
            if tokens.contains("apple-touch-icon") || tokens.contains("apple-touch-icon-precomposed") {
                self = .appleTouchIcon
                return
            }
            if tokens.contains("icon") {
                self = tokens.contains("shortcut") ? .shortcutIcon : .icon
                return
            }
            return nil
        }
    }

    let url: URL
    let kind: Kind
    let pixelArea: Int
    let formatPriority: Int

    static func isBetter(_ lhs: IconCandidate, _ rhs: IconCandidate) -> Bool {
        if lhs.kind.rawValue != rhs.kind.rawValue {
            return lhs.kind.rawValue > rhs.kind.rawValue
        }
        if lhs.pixelArea != rhs.pixelArea {
            return lhs.pixelArea > rhs.pixelArea
        }
        return lhs.formatPriority > rhs.formatPriority
    }

    static func parseLargestPixelArea(from sizes: String?) -> Int {
        let trimmed = (sizes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        return trimmed
            .split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" || $0 == "\r" })
            .compactMap { token -> Int? in
                let parts = token.split(separator: "x", maxSplits: 1).compactMap { Int($0) }
                guard parts.count == 2 else { return nil }
                return parts[0] * parts[1]
            }
            .max() ?? 0
    }

    static func formatPriority(for url: URL) -> Int {
        switch url.pathExtension.lowercased() {
        case "png", "webp":
            3
        case "jpg", "jpeg":
            2
        case "gif", "ico":
            1
        default:
            0
        }
    }
}

protocol SubscriptionIconSVGRasterizing {
    @MainActor
    func rasterize(svgData: Data, baseURL: URL, size: CGFloat) async throws -> Data
}

struct WebKitSubscriptionIconSVGRasterizer: SubscriptionIconSVGRasterizing {
    @MainActor
    func rasterize(svgData: Data, baseURL: URL, size: CGFloat) async throws -> Data {
        let rasterizer = WebKitSVGRasterizationTask()
        return try await rasterizer.rasterize(svgData: svgData, baseURL: baseURL, size: size)
    }
}

@MainActor
private final class WebKitSVGRasterizationTask: NSObject {
    private var continuation: CheckedContinuation<Data, Error>?
    private var webView: WKWebView?
    private var timeoutTask: Task<Void, Never>?

    func rasterize(svgData: Data, baseURL: URL, size: CGFloat) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let svg = String(decoding: svgData, as: UTF8.self)
            let html = """
            <!doctype html>
            <html>
              <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                  html, body { margin: 0; padding: 0; background: transparent; width: 100%; height: 100%; }
                  svg { width: 100%; height: 100%; }
                </style>
              </head>
              <body>
                \(svg)
              </body>
            </html>
            """

            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .nonPersistent()
            configuration.defaultWebpagePreferences.allowsContentJavaScript = false

            let webView = WKWebView(
                frame: CGRect(x: 0, y: 0, width: size, height: size),
                configuration: configuration
            )
            webView.navigationDelegate = self
            webView.isOpaque = false
            webView.backgroundColor = .clear
            webView.scrollView.backgroundColor = .clear
            webView.scrollView.isScrollEnabled = false
            self.webView = webView

            webView.loadHTMLString(html, baseURL: baseURL)

            timeoutTask?.cancel()
            timeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                self?.finish(.failure(SubscriptionIconRemoteServiceError.invalidResponse))
            }
        }
    }

    private func finish(_ result: Result<Data, Error>) {
        let continuation = continuation
        self.continuation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        webView?.navigationDelegate = nil
        webView = nil

        continuation?.resume(with: result)
    }
}

extension WebKitSVGRasterizationTask: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        let size = webView.bounds.size
        let configuration = WKSnapshotConfiguration()
        configuration.rect = CGRect(origin: .zero, size: size)
        configuration.snapshotWidth = NSNumber(value: Float(size.width))

        webView.takeSnapshot(with: configuration) { [weak self] image, error in
            guard let self else { return }
            guard error == nil else {
                self.finish(.failure(SubscriptionIconRemoteServiceError.invalidResponse))
                return
            }
            guard let image else {
                self.finish(.failure(SubscriptionIconRemoteServiceError.invalidResponse))
                return
            }
            guard let data = image.pngData() else {
                self.finish(.failure(SubscriptionIconRemoteServiceError.invalidResponse))
                return
            }
            self.finish(.success(data))
        }
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        finish(.failure(SubscriptionIconRemoteServiceError.invalidResponse))
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError _: Error) {
        finish(.failure(SubscriptionIconRemoteServiceError.invalidResponse))
    }
}
