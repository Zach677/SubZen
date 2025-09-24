//
//  CurrencyData.swift
//  SubZen
//
//  Created by Star on 2025/4/19.
//

import Foundation

struct Currency: Identifiable, Hashable, Decodable {
    let id: String
    let code: String
    let numeric: String?
    let name: String
    let symbol: String
    let decimalDigits: Int

    init(code: String, numeric: String?, name: String, symbol: String, decimalDigits: Int) {
        id = code
        self.code = code
        self.numeric = numeric
        self.name = name
        self.symbol = symbol
        self.decimalDigits = decimalDigits
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case numeric
        case name
        case symbol
        case decimalDigits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedCode = try container.decode(String.self, forKey: .code)
        code = decodedCode
        id = decodedCode
        numeric = try container.decodeIfPresent(String.self, forKey: .numeric)
        name = try container.decode(String.self, forKey: .name)
        symbol = try container.decode(String.self, forKey: .symbol)
        decimalDigits = try container.decode(Int.self, forKey: .decimalDigits)
    }
}

enum CurrencyList {
    private static let currencyFileName = "iso4217"
    private static let currencyFileExtension = "json"
    private static let currencyDirectoryName = "Currency"

    static let allCurrencies: [Currency] = loadCurrencies()
    static let supportedCurrencyCodes: Set<String> = Set(allCurrencies.map(\.code))

    static func getCurrency(byCode code: String) -> Currency? {
        let uppercasedCode = code.uppercased()
        return allCurrencies.first { $0.code == uppercasedCode }
    }

    static func getSymbol(for code: String) -> String {
        displaySymbol(for: code)
    }

    static func supports(code: String) -> Bool {
        supportedCurrencyCodes.contains(code.uppercased())
    }

    static func displaySymbol(for code: String) -> String {
        let normalized = code.uppercased()

        if let cached = displaySymbolCache[normalized] {
            return cached
        }

        if let currency = getCurrency(byCode: normalized),
           currency.symbol.caseInsensitiveCompare(normalized) != .orderedSame
        {
            displaySymbolCache[normalized] = currency.symbol
            return currency.symbol
        }

        if let localeSymbol = localeDerivedSymbol(for: normalized) {
            displaySymbolCache[normalized] = localeSymbol
            return localeSymbol
        }

        displaySymbolCache[normalized] = normalized
        return normalized
    }

    private static func loadCurrencies() -> [Currency] {
        guard let data = loadCurrenciesData() else {
            assertionFailure("Currency data file is missing.")
            return []
        }

        do {
            let currencies = try JSONDecoder().decode([Currency].self, from: data)
            return currencies
        } catch {
            assertionFailure("Failed to decode currency data: \(error)")
            return []
        }
    }

    private static func loadCurrenciesData() -> Data? {
        let bundleCandidates = [Bundle.main, Bundle(for: CurrencyBundleLocator.self)]
        for bundle in bundleCandidates {
            if let data = dataFromBundle(bundle) {
                return data
            }
        }

        let fallbackPaths = [
            "Resources/\(currencyDirectoryName)/\(currencyFileName).\(currencyFileExtension)",
            "SubZen/Resources/\(currencyDirectoryName)/\(currencyFileName).\(currencyFileExtension)",
        ]

        for relativePath in fallbackPaths {
            let url = URL(fileURLWithPath: relativePath, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
            if FileManager.default.fileExists(atPath: url.path),
               let data = try? Data(contentsOf: url)
            {
                return data
            }
        }

        return nil
    }

    private static func dataFromBundle(_ bundle: Bundle) -> Data? {
        let resourceCandidates: [URL?] = [
            bundle.url(forResource: currencyFileName, withExtension: currencyFileExtension, subdirectory: currencyDirectoryName),
            bundle.url(forResource: "\(currencyDirectoryName)/\(currencyFileName)", withExtension: currencyFileExtension),
            bundle.url(forResource: currencyFileName, withExtension: currencyFileExtension),
        ]

        let fileManager = FileManager.default
        for candidate in resourceCandidates {
            guard let url = candidate else { continue }
            if fileManager.fileExists(atPath: url.path),
               let data = try? Data(contentsOf: url)
            {
                return data
            }
        }

    #if DEBUG
        if let resourceURL = bundle.resourceURL {
            let debugURL = resourceURL
                .appendingPathComponent(currencyDirectoryName, isDirectory: true)
                .appendingPathComponent("\(currencyFileName).\(currencyFileExtension)")
            if fileManager.fileExists(atPath: debugURL.path),
               let data = try? Data(contentsOf: debugURL)
            {
                return data
            }
        }
    #endif

        return nil
    }

    private static func localeDerivedSymbol(for code: String) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code

        let preferredLocales = Locale.preferredLanguages.map(Locale.init(identifier:))
        for locale in preferredLocales {
            formatter.locale = locale
            if let symbol = formatter.currencySymbol,
               symbol.caseInsensitiveCompare(code) != .orderedSame
            {
                return symbol
            }
        }

        for identifier in Locale.availableIdentifiers {
            let locale = Locale(identifier: identifier)
            if locale.currencyCode?.uppercased() == code {
                formatter.locale = locale
                if let symbol = formatter.currencySymbol,
                   symbol.caseInsensitiveCompare(code) != .orderedSame
                {
                    return symbol
                }
            }
        }

        formatter.locale = Locale.current
        if let symbol = formatter.currencySymbol,
           symbol.caseInsensitiveCompare(code) != .orderedSame
        {
            return symbol
        }

        return nil
    }

    private static var displaySymbolCache: [String: String] = [:]
}

private final class CurrencyBundleLocator {}
