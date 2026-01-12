//
//  SubscriptionImportService.swift
//  SubZen
//
//  Created by Star on 2025/12/27.
//

import Foundation

// MARK: - Import Mode

enum ImportMode {
    case merge // Keep existing subscriptions, add new ones (skip duplicates)
    case replace // Clear all existing subscriptions before import
}

// MARK: - Import Result

struct ImportResult {
    let imported: Int
    let skipped: Int
    let total: Int
}

// MARK: - Import Error

enum SubscriptionImportError: LocalizedError {
    case fileReadFailed(Error)
    case decodingFailed(Error)
    case unsupportedVersion(Int)
    case noSubscriptionsToImport

    var errorDescription: String? {
        switch self {
        case let .fileReadFailed(error):
            let key: String.LocalizationValue = "Failed to read file: \(error.localizedDescription)"
            return String(localized: key)
        case let .decodingFailed(error):
            let key: String.LocalizationValue = "Failed to parse file: \(error.localizedDescription)"
            return String(localized: key)
        case let .unsupportedVersion(version):
            let versionValue = Int64(version)
            let key: String.LocalizationValue = "Unsupported file version: \(versionValue)"
            return String(localized: key)
        case .noSubscriptionsToImport:
            return String(localized: "No subscriptions found in file")
        }
    }
}

// MARK: - Import Service

final class SubscriptionImportService {
    private let subscriptionManager: SubscriptionManager
    private let iconFileStore: SubscriptionIconFileStore

    init(
        subscriptionManager: SubscriptionManager = .shared,
        iconFileStore: SubscriptionIconFileStore = SubscriptionIconFileStore()
    ) {
        self.subscriptionManager = subscriptionManager
        self.iconFileStore = iconFileStore
    }

    /// Previews the import data without actually importing.
    /// - Parameter fileURL: URL of the JSON file to preview
    /// - Returns: The parsed export data for preview
    /// - Throws: `SubscriptionImportError` if parsing fails
    func previewImport(fileURL: URL) throws -> SubscriptionExportData {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw SubscriptionImportError.fileReadFailed(error)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData: SubscriptionExportData
        do {
            exportData = try decoder.decode(SubscriptionExportData.self, from: data)
        } catch {
            throw SubscriptionImportError.decodingFailed(error)
        }

        guard exportData.version <= SubscriptionExportData.currentVersion else {
            throw SubscriptionImportError.unsupportedVersion(exportData.version)
        }

        return exportData
    }

    /// Imports subscriptions from a JSON file.
    /// - Parameters:
    ///   - fileURL: URL of the JSON file to import
    ///   - mode: Import mode (merge or replace)
    /// - Returns: Import result with counts of imported and skipped subscriptions
    /// - Throws: `SubscriptionImportError` if import fails
    func importFromJSON(fileURL: URL, mode: ImportMode) throws -> ImportResult {
        let exportData = try previewImport(fileURL: fileURL)

        guard !exportData.subscriptions.isEmpty else {
            throw SubscriptionImportError.noSubscriptionsToImport
        }

        if mode == .replace {
            subscriptionManager.eraseAll()
        }

        var iconDataBySubscriptionID: [UUID: Data] = [:]
        if let icons = exportData.icons {
            for icon in icons {
                iconDataBySubscriptionID[icon.subscriptionID] = icon.pngData
            }
        }

        var imported = 0
        var skipped = 0
        let existingSubscriptions = subscriptionManager.allSubscriptions()

        for subscription in exportData.subscriptions {
            if mode == .merge, isDuplicate(subscription, in: existingSubscriptions) {
                skipped += 1
                continue
            }

            do {
                let created = try subscriptionManager.createSubscription(
                    name: subscription.name,
                    price: subscription.price,
                    cycle: subscription.cycle,
                    lastBillingDate: subscription.lastBillingDate,
                    endDate: subscription.endDate,
                    trialPeriod: subscription.trialPeriod,
                    currencyCode: subscription.currencyCode,
                    reminderIntervals: subscription.reminderIntervals
                )
                if let iconData = iconDataBySubscriptionID[subscription.id] {
                    try? iconFileStore.saveIconData(iconData, for: created.id)
                }
                imported += 1
            } catch {
                // Skip subscriptions that fail validation
                skipped += 1
            }
        }

        return ImportResult(
            imported: imported,
            skipped: skipped,
            total: exportData.subscriptions.count
        )
    }

    /// Checks if a subscription is a duplicate based on name, price, and cycle.
    private func isDuplicate(_ subscription: Subscription, in existing: [Subscription]) -> Bool {
        existing.contains { existing in
            existing.name == subscription.name &&
                existing.price == subscription.price &&
                existing.cycle == subscription.cycle
        }
    }
}
