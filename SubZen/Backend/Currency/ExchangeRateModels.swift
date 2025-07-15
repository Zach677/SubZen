//
//  ExchangeRateModels.swift
//  SubZen
//
//  Created by Star on 2025/6/15.
//

import Foundation

// MARK: - Exchange Rate API Response Models

struct ExchangeRateResponse: Codable {
    let result: String?
    let baseCode: String?
    let conversionRates: [String: Decimal]?

    // 支持免费API格式
    let base: String?
    let rates: [String: Decimal]?
    let date: String?

    enum CodingKeys: String, CodingKey {
        case result
        case baseCode = "base_code"
        case conversionRates = "conversion_rates"
        case base
        case rates
        case date
    }

    // 统一的访问方法
    var actualBase: String {
        baseCode ?? base ?? "USD"
    }

    var actualRates: [String: Decimal] {
        conversionRates ?? rates ?? [:]
    }

    var isSuccess: Bool {
        result == "success" || result == nil // 免费API可能没有result字段
    }
}

// MARK: - Pair Conversion Response (配对转换)

struct PairConversionResponse: Codable {
    let result: String
    let documentation: String
    let termsOfUse: String
    let timeLastUpdateUnix: Int
    let timeLastUpdateUtc: String
    let timeNextUpdateUnix: Int
    let timeNextUpdateUtc: String
    let baseCode: String
    let targetCode: String
    let conversionRate: Decimal
    let conversionResult: Decimal?

    enum CodingKeys: String, CodingKey {
        case result
        case documentation
        case termsOfUse = "terms_of_use"
        case timeLastUpdateUnix = "time_last_update_unix"
        case timeLastUpdateUtc = "time_last_update_utc"
        case timeNextUpdateUnix = "time_next_update_unix"
        case timeNextUpdateUtc = "time_next_update_utc"
        case baseCode = "base_code"
        case targetCode = "target_code"
        case conversionRate = "conversion_rate"
        case conversionResult = "conversion_result"
    }
}

// MARK: - Historical Data Response

struct HistoricalRateResponse: Codable {
    let result: String
    let documentation: String
    let termsOfUse: String
    let year: Int
    let month: Int
    let day: Int
    let baseCode: String
    let conversionRates: [String: Decimal]

    enum CodingKeys: String, CodingKey {
        case result
        case documentation
        case termsOfUse = "terms_of_use"
        case year
        case month
        case day
        case baseCode = "base_code"
        case conversionRates = "conversion_rates"
    }
}

// MARK: - Error Response

struct ExchangeRateErrorResponse: Codable {
    let result: String
    let errorType: String

    enum CodingKeys: String, CodingKey {
        case result
        case errorType = "error-type"
    }
}

// MARK: - Exchange Rate Service Configuration

enum ExchangeRateConfig {
    static let baseURL = "https://v6.exchangerate-api.com/v6"
    static let freeBaseURL = "https://api.exchangerate-api.com/v4" // 免费API端点
    static let apiKey = "YOUR_API_KEY_HERE" // 替换为你的API密钥
    static let defaultBaseCurrency = "USD"
    static let useFreeAPI = true // 设置为true使用免费API
    static let cacheExpirationTime: TimeInterval = 3600 // 1小时缓存

    // API端点
    enum Endpoint {
        case latest(baseCurrency: String)
        case pair(from: String, to: String, amount: Decimal? = nil)
        case historical(baseCurrency: String, year: Int, month: Int, day: Int)

        var path: String {
            switch self {
            case let .latest(baseCurrency):
                "/latest/\(baseCurrency)"
            case let .pair(from, to, amount):
                if let amount {
                    "/pair/\(from)/\(to)/\(amount)"
                } else {
                    "/pair/\(from)/\(to)"
                }
            case let .historical(baseCurrency, year, month, day):
                "/history/\(baseCurrency)/\(year)/\(month)/\(day)"
            }
        }

        var fullURL: String {
            "\(ExchangeRateConfig.baseURL)/\(ExchangeRateConfig.apiKey)\(path)"
        }
    }
}

// MARK: - Currency Conversion Result

struct CurrencyConversion {
    let originalAmount: Decimal
    let convertedAmount: Decimal
    let fromCurrency: String
    let toCurrency: String
    let exchangeRate: Decimal
    let timestamp: Date
}

// MARK: - Exchange Rate Cache

struct ExchangeRateCache: Codable {
    let rates: [String: Decimal]
    let baseCurrency: String
    let timestamp: Date
    let expirationDate: Date

    var isExpired: Bool {
        Date() > expirationDate
    }
}
