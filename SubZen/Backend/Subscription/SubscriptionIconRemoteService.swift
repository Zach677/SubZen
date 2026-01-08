//
//  SubscriptionIconRemoteService.swift
//  SubZen
//
//  Created by Codex on 2026/1/7.
//

import Foundation

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
        static let defaultAppStoreSearchLimit = 25
    }

    private let urlSession: URLSession

    init(urlSession: URLSession? = nil) {
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
        guard (200...299).contains(http.statusCode) else {
            throw SubscriptionIconRemoteServiceError.requestFailed(statusCode: http.statusCode)
        }
        guard data.count <= maxBytes else {
            throw SubscriptionIconRemoteServiceError.imageTooLarge(maxBytes: maxBytes)
        }
        return data
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
