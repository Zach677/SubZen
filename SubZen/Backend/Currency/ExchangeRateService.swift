//
//  ExchangeRateService.swift
//  SubZen
//
//  Created by Star on 2025/6/15.
//

import Foundation

class ExchangeRateService: ObservableObject {
    static let shared = ExchangeRateService()

    @Published var isLoading = false

    // MARK: - Cache Properties

    private var memoryCache: [String: ExchangeRateCache] = [:]
    private let cacheKey = "ExchangeRateCache"

    private init() {
        loadCacheFromDisk()
    }

    /// 获取汇率数据（带缓存）
    func fetchExchangeRates(baseCurrency: String = ExchangeRateConfig.defaultBaseCurrency)
        async throws -> [String: Decimal]
    {
        // 检查内存缓存
        if let cachedData = memoryCache[baseCurrency], !cachedData.isExpired {
            print("使用内存缓存的汇率数据 - 基准货币: \(baseCurrency)")
            return cachedData.rates
        }

        // 从网络获取新数据
        return try await fetchAndCacheExchangeRates(baseCurrency: baseCurrency)
    }

    /// 强制刷新汇率数据
    func refreshExchangeRates(baseCurrency: String = ExchangeRateConfig.defaultBaseCurrency)
        async throws -> [String: Decimal]
    {
        try await fetchAndCacheExchangeRates(baseCurrency: baseCurrency)
    }

    /// 从网络获取汇率数据并缓存
    private func fetchAndCacheExchangeRates(baseCurrency: String) async throws -> [String: Decimal] {
        isLoading = true
        defer { isLoading = false }

        let urlString = if ExchangeRateConfig.useFreeAPI {
            // 使用免费API
            "\(ExchangeRateConfig.freeBaseURL)/latest/\(baseCurrency)"
        } else {
            // 使用付费API
            "\(ExchangeRateConfig.baseURL)/\(ExchangeRateConfig.apiKey)/latest/\(baseCurrency)"
        }

        guard let url = URL(string: urlString) else {
            throw ExchangeRateServiceError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ExchangeRateServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw ExchangeRateServiceError.httpError(httpResponse.statusCode)
            }

            let exchangeRateResponse = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)

            guard exchangeRateResponse.isSuccess else {
                throw ExchangeRateServiceError.apiError("API request failed")
            }

            let rates = exchangeRateResponse.actualRates

            // 缓存数据
            cacheExchangeRates(rates: rates, baseCurrency: baseCurrency)

            print("从网络获取并缓存汇率数据 - 基准货币: \(baseCurrency)")
            return rates
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            // 打印原始JSON以便调试
            if let data = try? await URLSession.shared.data(from: url).0,
               let jsonString = String(data: data, encoding: .utf8)
            {
                print("Raw JSON response: \(jsonString)")
            }
            throw ExchangeRateServiceError.decodingError
        } catch {
            throw ExchangeRateServiceError.networkError(error)
        }
    }

    /// 转换金额
    func convertAmount(_ amount: Decimal, from: String, to: String, rates: [String: Decimal])
        -> Decimal
    {
        if from == to { return amount }

        // 如果rates是以某个基准货币为基础，需要计算交叉汇率
        if let toRate = rates[to] {
            if let fromRate = rates[from] {
                // 交叉汇率计算
                return amount * (toRate / fromRate)
            } else {
                // from是基准货币
                return amount * toRate
            }
        }

        return amount // 找不到汇率时返回原值
    }

    // MARK: - Cache Management

    /// 缓存汇率数据
    private func cacheExchangeRates(rates: [String: Decimal], baseCurrency: String) {
        let now = Date()
        let expirationDate = now.addingTimeInterval(ExchangeRateConfig.cacheExpirationTime)

        let cache = ExchangeRateCache(
            rates: rates,
            baseCurrency: baseCurrency,
            timestamp: now,
            expirationDate: expirationDate
        )

        // 存储到内存缓存
        memoryCache[baseCurrency] = cache

        // 持久化到磁盘
        saveCacheToDisk()
    }

    /// 清除指定货币的缓存
    func clearCache(for baseCurrency: String? = nil) {
        if let baseCurrency {
            memoryCache.removeValue(forKey: baseCurrency)
        } else {
            memoryCache.removeAll()
        }
        saveCacheToDisk()
    }

    /// 检查缓存是否存在且有效
    func isCacheValid(for baseCurrency: String) -> Bool {
        guard let cache = memoryCache[baseCurrency] else { return false }
        return !cache.isExpired
    }

    /// 获取缓存的时间戳
    func getCacheTimestamp(for baseCurrency: String) -> Date? {
        memoryCache[baseCurrency]?.timestamp
    }

    /// 获取所有缓存的基准货币
    var cachedBaseCurrencies: [String] {
        Array(memoryCache.keys)
    }

    /// 获取缓存状态描述
    func getCacheStatusDescription(for baseCurrency: String) -> String {
        guard let cache = memoryCache[baseCurrency] else {
            return "无缓存数据"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        let timeString = formatter.string(from: cache.timestamp)

        if cache.isExpired {
            return "缓存已过期 (更新于: \(timeString))"
        } else {
            let remainingTime = cache.expirationDate.timeIntervalSinceNow
            let minutes = Int(remainingTime / 60)
            return "缓存有效 (更新于: \(timeString), 剩余: \(minutes)分钟)"
        }
    }

    // MARK: - Disk Cache Persistence

    /// 保存缓存到磁盘
    private func saveCacheToDisk() {
        if memoryCache.isEmpty {
            UserDefaults.standard.removeObject(forKey: cacheKey)
            return
        }

        do {
            let data = try JSONEncoder().encode(Array(memoryCache.values))
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            print("保存汇率缓存失败: \(error)")
        }
    }

    /// 从磁盘加载缓存
    private func loadCacheFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return }

        do {
            let caches = try JSONDecoder().decode([ExchangeRateCache].self, from: data)

            // 只加载未过期的缓存
            for cache in caches {
                if !cache.isExpired {
                    memoryCache[cache.baseCurrency] = cache
                }
            }

            print("从磁盘加载了 \(memoryCache.count) 个有效的汇率缓存")
        } catch {
            print("加载汇率缓存失败: \(error)")
            // 清除损坏的缓存数据
            UserDefaults.standard.removeObject(forKey: cacheKey)
        }
    }
}

enum ExchangeRateServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid API URL"
        case .invalidResponse:
            "Invalid response from server"
        case let .httpError(code):
            "HTTP error with code: \(code)"
        case let .apiError(message):
            message
        case .decodingError:
            "Failed to decode API response"
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        }
    }
}
