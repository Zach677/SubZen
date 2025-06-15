//
//  ExchangeRateService.swift
//  SubZen
//
//  Created by Star on 2025/6/15.
//

import Foundation

@MainActor
class ExchangeRateService: ObservableObject {
  static let shared = ExchangeRateService()

  @Published var isLoading = false

  private init() {}

  /// 获取汇率数据
  func fetchExchangeRates(baseCurrency: String = ExchangeRateConfig.defaultBaseCurrency)
    async throws -> [String: Decimal]
  {
    isLoading = true
    defer { isLoading = false }

    let urlString: String
    if ExchangeRateConfig.useFreeAPI {
      // 使用免费API
      urlString = "\(ExchangeRateConfig.freeBaseURL)/latest/\(baseCurrency)"
    } else {
      // 使用付费API
      urlString =
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

      return exchangeRateResponse.actualRates
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

    return amount  // 找不到汇率时返回原值
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
      return "Invalid API URL"
    case .invalidResponse:
      return "Invalid response from server"
    case .httpError(let code):
      return "HTTP error with code: \(code)"
    case .apiError(let message):
      return message
    case .decodingError:
      return "Failed to decode API response"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    }
  }
}
