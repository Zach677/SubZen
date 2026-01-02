//
//  UIImageView+Factory.swift
//  SubZen
//

import UIKit

extension UIImageView {
    /// Creates a chevron image view configured for settings rows
    static func makeChevronView() -> UIImageView {
        UIImageView(image: UIImage(systemName: "chevron.right")).with {
            $0.tintColor = .tertiaryLabel
            $0.contentMode = .scaleAspectFit
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }

    /// Creates an icon image view configured for settings rows
    static func makeSettingIconView(systemName: String) -> UIImageView {
        UIImageView(image: UIImage(systemName: systemName)).with {
            $0.tintColor = .secondaryLabel
            $0.contentMode = .scaleAspectFit
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }
}
