import UIKit

enum EditSubscriptionButtonStyler {
    static func saveButtonConfiguration(
        title: String,
        reduceTransparencyActive: Bool,
        contentInsets: NSDirectionalEdgeInsets
    ) -> UIButton.Configuration {
        if #available(iOS 26.0, *), !reduceTransparencyActive {
            var configuration = UIButton.Configuration.prominentGlass()
            configuration.title = title
            configuration.buttonSize = .large
            configuration.contentInsets = contentInsets
            configuration.baseForegroundColor = .label
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attributes = incoming
                attributes.font = .systemFont(ofSize: 17, weight: .semibold)
                return attributes
            }
            return configuration
        } else {
            var configuration = UIButton.Configuration.borderedProminent()
            configuration.title = title
            configuration.buttonSize = .large
            configuration.contentInsets = contentInsets
            configuration.baseBackgroundColor = .systemBlue
            configuration.baseForegroundColor = .white
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attributes = incoming
                attributes.font = .systemFont(ofSize: 17, weight: .semibold)
                return attributes
            }
            return configuration
        }
    }

    static func applySaveButtonStyle(
        to button: UIButton,
        title: String,
        reduceTransparencyActive: Bool,
        contentInsets: NSDirectionalEdgeInsets
    ) {
        button.configuration = saveButtonConfiguration(
            title: title,
            reduceTransparencyActive: reduceTransparencyActive,
            contentInsets: contentInsets
        )
        button.tintColor = .accent.withAlphaComponent(0.7)
    }

    static func makeCurrencyButtonBaseConfiguration(
        contentInsets: NSDirectionalEdgeInsets
    ) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Select"
        configuration.cornerStyle = .large
        configuration.contentInsets = contentInsets
        configuration.titleAlignment = .leading
        configuration.baseForegroundColor = .label
        configuration.baseBackgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
        configuration.background.strokeColor = UIColor.separator.withAlphaComponent(0.25)
        configuration.background.strokeWidth = 1
        configuration.background.visualEffect = UIBlurEffect(style: .systemChromeMaterial)
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        configuration.image = UIImage(systemName: "chevron.down")
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var attributes = incoming
            attributes.font = .systemFont(ofSize: 15, weight: .medium)
            return attributes
        }
        return configuration
    }

    static func applyCurrencyButtonStyle(
        to button: UIButton,
        reduceTransparencyActive: Bool,
        contentInsets: NSDirectionalEdgeInsets
    ) {
        var configuration = button.configuration ?? makeCurrencyButtonBaseConfiguration(contentInsets: contentInsets)

        configuration.baseForegroundColor = .label
        configuration.background.strokeColor = UIColor.separator.withAlphaComponent(reduceTransparencyActive ? 0.5 : 0.25)

        if reduceTransparencyActive {
            configuration.baseBackgroundColor = UIColor.secondarySystemBackground
            var background = configuration.background
            background.visualEffect = nil
            background.backgroundColor = UIColor.secondarySystemBackground
            configuration.background = background
        } else {
            configuration.baseBackgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
            var background = configuration.background
            background.visualEffect = UIBlurEffect(style: .systemChromeMaterial)
            background.backgroundColor = configuration.baseBackgroundColor
            configuration.background = background
        }

        button.configuration = configuration
        button.tintColor = .secondaryLabel
    }

    static func reminderChipConfiguration(
        for days: Int,
        isSelected: Bool,
        reduceTransparencyActive: Bool,
        contentInsets: NSDirectionalEdgeInsets,
        cornerRadius: CGFloat
    ) -> UIButton.Configuration {
        let title = "\(days) day\(days == 1 ? "" : "s")"

        if #available(iOS 26.0, *), !reduceTransparencyActive {
            var configuration = UIButton.Configuration.glass()
            configuration.cornerStyle = .capsule
            configuration.contentInsets = contentInsets
            configuration.title = title
            configuration.baseForegroundColor = isSelected ? .label : .secondaryLabel

            var background = configuration.background
            background.cornerRadius = cornerRadius
            background.backgroundColor = isSelected ? UIColor.accent.withAlphaComponent(0.2) : UIColor.clear
            background.strokeColor = UIColor.accent.withAlphaComponent(isSelected ? 0.4 : 0.18)
            background.strokeWidth = isSelected ? 1.5 : 1
            configuration.background = background
            return configuration
        } else {
            var configuration = UIButton.Configuration.tinted()
            configuration.cornerStyle = .capsule
            configuration.contentInsets = contentInsets
            configuration.title = title
            configuration.baseForegroundColor = isSelected ? .white : .label
            configuration.baseBackgroundColor = isSelected ? UIColor.accent : UIColor.secondarySystemBackground.withAlphaComponent(0.92)

            var background = configuration.background
            background.cornerRadius = cornerRadius
            background.backgroundColor = configuration.baseBackgroundColor
            background.strokeColor = UIColor.accent.withAlphaComponent(isSelected ? 0.4 : 0.16)
            background.strokeWidth = isSelected ? 1.5 : 1
            configuration.background = background
            return configuration
        }
    }
}
