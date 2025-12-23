//
//  CurrencyRateService.swift
//  SubZen
//
//  Created by Star on 2025/11/25.
//

import Foundation

// MARK: - CurrencyRateService

/// Fetches and caches fiat currency exchange rates using the public Frankfurter (ECB) endpoint.
/// Rates are pulled once per base currency and cached for 24 hours to keep the main UI offline-friendly.
final class CurrencyRateService {
    private let session: URLSession
    private let cache: CurrencyRateCaching
    private let cacheTTL: TimeInterval

    init(
        session: URLSession = .shared,
        cache: CurrencyRateCaching = CurrencyRateCache(),
        cacheTTL: TimeInterval = 24 * 60 * 60
    ) {
        self.session = session
        self.cache = cache
        self.cacheTTL = cacheTTL
    }

    func latestSnapshot(for baseCurrencyCode: String, forceRefresh: Bool = false) async throws -> CurrencyRateSnapshot {
        let normalizedBase = baseCurrencyCode.uppercased()

        if !forceRefresh, let cached = cache.cachedSnapshot(for: normalizedBase), !cached.isExpired(ttl: cacheTTL) {
            return cached
        }

        do {
            let fresh = try await fetchSnapshot(base: normalizedBase)
            cache.save(snapshot: fresh)
            return fresh
        } catch {
            // Try cached snapshot first (may be expired but still usable)
            if let cached = cache.cachedSnapshot(for: normalizedBase) {
                return cached
            }
            // Fall back to backup snapshot (last successfully fetched rates)
            if let backup = cache.backupSnapshot(for: normalizedBase) {
                return backup
            }
            throw error
        }
    }

    private func fetchSnapshot(base: String) async throws -> CurrencyRateSnapshot {
        guard base.count == 3 else {
            throw CurrencyRateServiceError.unsupportedBase
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.frankfurter.app"
        components.path = "/latest"
        components.queryItems = [
            URLQueryItem(name: "from", value: base),
        ]

        guard let url = components.url else {
            throw CurrencyRateServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CurrencyRateServiceError.invalidResponse
        }

        guard 200 ... 299 ~= httpResponse.statusCode else {
            throw CurrencyRateServiceError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.frankfurterDateFormatter)

        let payload = try decoder.decode(FrankfurterResponse.self, from: data)
        return CurrencyRateSnapshot(
            base: payload.base.uppercased(),
            rates: payload.rates.mapValues { $0 },
            sourceDate: payload.date,
            fetchedAt: Date()
        )
    }
}

// MARK: - Snapshot

struct CurrencyRateSnapshot: Codable {
    let base: String
    let rates: [String: Decimal]
    let sourceDate: Date
    let fetchedAt: Date

    func rate(for code: String) -> Decimal? {
        rates[code.uppercased()]
    }

    func isExpired(ttl: TimeInterval) -> Bool {
        fetchedAt.addingTimeInterval(ttl) < Date()
    }

    /// Frankfurter returns rates in the direction: 1 `base` = rate `quote`.
    /// Cross-currency conversion (source != base && target != base) is done in a single step
    /// to minimize floating-point error accumulation.
    func convert(amount: Decimal, from sourceCode: String, to targetCode: String) -> Decimal? {
        let source = sourceCode.uppercased()
        let target = targetCode.uppercased()

        if source == target { return amount }

        if source == base {
            guard let targetRate = rate(for: target) else { return nil }
            return amount * targetRate
        }

        if target == base {
            guard let sourceRate = rate(for: source), sourceRate != 0 else { return nil }
            return amount / sourceRate
        }

        // Cross-currency: combine rates in a single operation to reduce rounding error.
        // source -> base -> target: amount / sourceRate * targetRate
        guard let sourceRate = rate(for: source), sourceRate != 0,
              let targetRate = rate(for: target)
        else { return nil }

        return amount * targetRate / sourceRate
    }
}

// MARK: - Cache

protocol CurrencyRateCaching {
    func cachedSnapshot(for base: String) -> CurrencyRateSnapshot?
    func backupSnapshot(for base: String) -> CurrencyRateSnapshot?
    func save(snapshot: CurrencyRateSnapshot)
}

final class CurrencyRateCache: CurrencyRateCaching {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(label: "io.subzen.currencyRateCache", qos: .utility)

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func cachedSnapshot(for base: String) -> CurrencyRateSnapshot? {
        queue.sync {
            guard let data = userDefaults.data(forKey: key(for: base)) else { return nil }
            return try? decoder.decode(CurrencyRateSnapshot.self, from: data)
        }
    }

    func backupSnapshot(for base: String) -> CurrencyRateSnapshot? {
        queue.sync {
            guard let data = userDefaults.data(forKey: backupKey(for: base)) else { return nil }
            return try? decoder.decode(CurrencyRateSnapshot.self, from: data)
        }
    }

    func save(snapshot: CurrencyRateSnapshot) {
        queue.async { [encoder, userDefaults] in
            guard let data = try? encoder.encode(snapshot) else { return }
            let base = snapshot.base
            userDefaults.set(data, forKey: self.key(for: base))
            // Also save as backup for offline fallback
            userDefaults.set(data, forKey: self.backupKey(for: base))
        }
    }

    private func key(for base: String) -> String {
        "currencyRates.snapshot.\(base.uppercased())"
    }

    private func backupKey(for base: String) -> String {
        "currencyRates.backup.\(base.uppercased())"
    }
}

// MARK: - Response + Errors

private struct FrankfurterResponse: Decodable {
    let base: String
    let date: Date
    let rates: [String: Decimal]
}

enum CurrencyRateServiceError: LocalizedError {
    case unsupportedBase
    case invalidURL
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedBase:
            String(localized: "Unsupported base currency")
        case .invalidURL:
            String(localized: "Failed to build rates URL")
        case .invalidResponse:
            String(localized: "Unexpected response when loading rates")
        case let .httpError(code):
            String(localized: "Failed to load rates (HTTP \(code))")
        }
    }
}

private extension DateFormatter {
    static let frankfurterDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
