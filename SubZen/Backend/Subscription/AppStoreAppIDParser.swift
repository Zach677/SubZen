//
//  AppStoreAppIDParser.swift
//  SubZen
//
//  Created by Codex on 2026/1/7.
//

import Foundation

enum AppStoreAppIDParser {
    static func parseAppID(from input: String) -> Int? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let directID = Int(trimmed) {
            return directID
        }

        let pattern = "id(\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, options: [], range: range),
              match.numberOfRanges >= 2,
              let idRange = Range(match.range(at: 1), in: trimmed)
        else {
            return nil
        }

        return Int(trimmed[idRange])
    }
}

