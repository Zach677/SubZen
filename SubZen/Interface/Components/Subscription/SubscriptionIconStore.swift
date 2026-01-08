//
//  SubscriptionIconStore.swift
//  SubZen
//
//  Created by Codex on 2026/1/7.
//

import UIKit

enum SubscriptionIconStoreError: LocalizedError {
    case iconEncodingFailed

    var errorDescription: String? {
        switch self {
        case .iconEncodingFailed:
            String(localized: "Failed to encode icon image.")
        }
    }
}

final class SubscriptionIconStore {
    private enum Constants {
        static let targetIconSize: CGFloat = 256
    }

    private let fileStore: SubscriptionIconFileStore
    private let cache = NSCache<NSString, UIImage>()

    init(fileStore: SubscriptionIconFileStore = SubscriptionIconFileStore()) {
        self.fileStore = fileStore
    }

    func cachedIcon(for subscriptionID: UUID) -> UIImage? {
        cache.object(forKey: subscriptionID.uuidString as NSString)
    }

    func iconExists(for subscriptionID: UUID) -> Bool {
        if cachedIcon(for: subscriptionID) != nil {
            return true
        }
        return fileStore.iconExists(for: subscriptionID)
    }

    func icon(for subscriptionID: UUID) async -> UIImage? {
        let key = subscriptionID.uuidString as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        return await Task.detached(priority: .utility) { [fileStore, cache] in
            do {
                guard let data = try fileStore.loadIconData(for: subscriptionID),
                      let image = UIImage(data: data)
                else {
                    return nil
                }
                cache.setObject(image, forKey: key)
                return image
            } catch {
                return nil
            }
        }.value
    }

    func saveIcon(_ image: UIImage, for subscriptionID: UUID) async throws {
        let key = subscriptionID.uuidString as NSString
        let savedImage = try await Task.detached(priority: .utility) { [fileStore] in
            let normalized = image.normalizedSquareIcon(size: Constants.targetIconSize)
            guard let data = normalized.pngData() else {
                throw SubscriptionIconStoreError.iconEncodingFailed
            }
            try fileStore.saveIconData(data, for: subscriptionID)
            return normalized
        }.value

        cache.setObject(savedImage, forKey: key)
    }

    func removeIcon(for subscriptionID: UUID) throws {
        let key = subscriptionID.uuidString as NSString
        cache.removeObject(forKey: key)
        try fileStore.removeIcon(for: subscriptionID)
    }
}

extension UIImage {
    func normalizedSquareIcon(size: CGFloat) -> UIImage {
        let targetSize = CGSize(width: size, height: size)
        let format = UIGraphicsImageRendererFormat.default().with {
            $0.opaque = false
        }
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        return renderer.image { _ in
            let imageSize = self.size
            let scale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
            let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            let origin = CGPoint(
                x: (targetSize.width - scaledSize.width) / 2,
                y: (targetSize.height - scaledSize.height) / 2
            )
            self.draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }
}
