//
//  SubscriptionExportService.swift
//  SubZen
//
//  Created by Star on 2025/12/27.
//

import Foundation

// MARK: - Export Data Structure

struct SubscriptionIconExport: Codable, Equatable {
    let subscriptionID: UUID
    let pngData: Data
}

struct SubscriptionExportData: Codable {
    let version: Int
    let exportedAt: Date
    let subscriptions: [Subscription]
    let icons: [SubscriptionIconExport]?

    static let currentVersion = 3
}

// MARK: - Export Error

enum SubscriptionExportError: LocalizedError {
    case encodingFailed(Error)
    case fileWriteFailed(Error)

    var errorDescription: String? {
        switch self {
        case let .encodingFailed(error):
            let key: String.LocalizationValue = "Failed to encode subscriptions: \(error.localizedDescription)"
            return String(localized: key)
        case let .fileWriteFailed(error):
            let key: String.LocalizationValue = "Failed to write export file: \(error.localizedDescription)"
            return String(localized: key)
        }
    }
}

// MARK: - Export Service

final class SubscriptionExportService {
    private let subscriptionProvider: () -> [Subscription]
    private let fileManager: FileManager
    private let iconFileStore: SubscriptionIconFileStore

    init(
        subscriptionProvider: @escaping () -> [Subscription] = { SubscriptionManager.shared.allSubscriptions() },
        fileManager: FileManager = .default,
        iconFileStore: SubscriptionIconFileStore = SubscriptionIconFileStore()
    ) {
        self.subscriptionProvider = subscriptionProvider
        self.fileManager = fileManager
        self.iconFileStore = iconFileStore
    }

    /// Exports all subscriptions to a JSON file in the temporary directory.
    /// - Returns: URL of the exported file
    /// - Throws: `SubscriptionExportError` if export fails
    func exportToJSON() throws -> URL {
        let subscriptions = subscriptionProvider()
        let icons = loadIcons(for: subscriptions)
        let exportData = SubscriptionExportData(
            version: SubscriptionExportData.currentVersion,
            exportedAt: Date(),
            subscriptions: subscriptions,
            icons: icons
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

    private func loadIcons(for subscriptions: [Subscription]) -> [SubscriptionIconExport]? {
        let icons = subscriptions.compactMap { subscription -> SubscriptionIconExport? in
            do {
                guard let data = try iconFileStore.loadIconData(for: subscription.id) else { return nil }
                return SubscriptionIconExport(subscriptionID: subscription.id, pngData: data)
            } catch {
                return nil
            }
        }

        return icons.isEmpty ? nil : icons
    }
}
