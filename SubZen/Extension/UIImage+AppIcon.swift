//
//  UIImage+AppIcon.swift
//  SubZen
//
//  Created by Codex on 2026/1/7.
//

import UIKit

extension UIImage {
    static var subZenAppIconPlaceholder: UIImage {
        cachedAppIconPlaceholder
    }

    private static let cachedAppIconPlaceholder: UIImage = {
        if let iconName = primaryAppIconName(),
           let image = UIImage(named: iconName)
        {
            return image
        }

        if let iconName = primaryAppIconAssetName(),
           let image = UIImage(named: iconName)
        {
            return image
        }

        return UIImage(systemName: "app.fill")!
    }()

    private static func primaryAppIconName() -> String? {
        let info = Bundle.main.infoDictionary ?? [:]

        let iconDictionaries: [[String: Any]] = [
            info["CFBundleIcons"] as? [String: Any],
            info["CFBundleIcons~ipad"] as? [String: Any],
        ].compactMap { $0 }

        for icons in iconDictionaries {
            guard let primary = icons["CFBundlePrimaryIcon"] as? [String: Any] else { continue }
            if let iconFiles = primary["CFBundleIconFiles"] as? [String], let last = iconFiles.last {
                return last
            }
        }

        return nil
    }

    private static func primaryAppIconAssetName() -> String? {
        let info = Bundle.main.infoDictionary ?? [:]

        let iconDictionaries: [[String: Any]] = [
            info["CFBundleIcons"] as? [String: Any],
            info["CFBundleIcons~ipad"] as? [String: Any],
        ].compactMap { $0 }

        for icons in iconDictionaries {
            guard let primary = icons["CFBundlePrimaryIcon"] as? [String: Any] else { continue }
            if let assetName = primary["CFBundleIconName"] as? String {
                return assetName
            }
        }

        return nil
    }
}

