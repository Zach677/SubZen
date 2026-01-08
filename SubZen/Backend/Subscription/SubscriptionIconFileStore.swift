//
//  SubscriptionIconFileStore.swift
//  SubZen
//
//  Created by Codex on 2026/1/7.
//

import Foundation

struct SubscriptionIconFileStore {
    private let fileManager: FileManager
    private let iconsDirectoryURL: URL

    init(
        iconsDirectoryURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.iconsDirectoryURL = iconsDirectoryURL
            ?? fileManager
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("SubscriptionIcons", isDirectory: true)
    }

    func iconURL(for subscriptionID: UUID) -> URL {
        iconsDirectoryURL
            .appendingPathComponent(subscriptionID.uuidString, isDirectory: false)
            .appendingPathExtension("png")
    }

    func iconExists(for subscriptionID: UUID) -> Bool {
        fileManager.fileExists(atPath: iconURL(for: subscriptionID).path)
    }

    func loadIconData(for subscriptionID: UUID) throws -> Data? {
        let url = iconURL(for: subscriptionID)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    func saveIconData(_ data: Data, for subscriptionID: UUID) throws {
        try ensureIconsDirectoryExists()
        let url = iconURL(for: subscriptionID)
        try data.write(to: url, options: .atomic)
    }

    func removeIcon(for subscriptionID: UUID) throws {
        let url = iconURL(for: subscriptionID)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    func removeAllIcons() throws {
        guard fileManager.fileExists(atPath: iconsDirectoryURL.path) else { return }
        try fileManager.removeItem(at: iconsDirectoryURL)
    }

    private func ensureIconsDirectoryExists() throws {
        guard !fileManager.fileExists(atPath: iconsDirectoryURL.path) else { return }
        try fileManager.createDirectory(
            at: iconsDirectoryURL,
            withIntermediateDirectories: true
        )
    }
}

