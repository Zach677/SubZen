//
//  SubscriptionExportService.swift
//  SubZen
//
//  Created by Star on 2025/12/27.
//

import Foundation

// MARK: - Export Data Structure

struct SubscriptionExportData: Codable {
    let version: Int
    let exportedAt: Date
    let subscriptions: [Subscription]

    static let currentVersion = 1
}

// MARK: - Export Error

enum SubscriptionExportError: LocalizedError {
    case encodingFailed(Error)
    case fileWriteFailed(Error)

    var errorDescription: String? {
        switch self {
        case let .encodingFailed(error):
            String(localized: "Failed to encode subscriptions: \(error.localizedDescription)")
        case let .fileWriteFailed(error):
            String(localized: "Failed to write export file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Export Service

final class SubscriptionExportService {
    private let subscriptionProvider: () -> [Subscription]
    private let fileManager: FileManager

    init(
        subscriptionProvider: @escaping () -> [Subscription] = { SubscriptionManager.shared.allSubscriptions() },
        fileManager: FileManager = .default
    ) {
        self.subscriptionProvider = subscriptionProvider
        self.fileManager = fileManager
    }

    /// Exports all subscriptions to a JSON file in the temporary directory.
    /// - Returns: URL of the exported file
    /// - Throws: `SubscriptionExportError` if export fails
    func exportToJSON() throws -> URL {
        let subscriptions = subscriptionProvider()
        let exportData = SubscriptionExportData(
            version: SubscriptionExportData.currentVersion,
            exportedAt: Date(),
            subscriptions: subscriptions
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData: Data
        do {
            jsonData = try encoder.encode(exportData)
        } catch {
            throw SubscriptionExportError.encodingFailed(error)
        }

        let fileName = generateFileName()
        let fileURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try jsonData.write(to: fileURL, options: .atomic)
        } catch {
            throw SubscriptionExportError.fileWriteFailed(error)
        }

        return fileURL
    }

    /// Cleans up a temporary export file after sharing is complete.
    /// - Parameter url: URL of the file to remove
    func cleanupExportFile(at url: URL) {
        try? fileManager.removeItem(at: url)
    }

    private func generateFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "SubZen-Subscriptions-\(dateString).json"
    }
}
