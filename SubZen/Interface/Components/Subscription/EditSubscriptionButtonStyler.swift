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
}

enum EditSubscriptionSelectionStyler {
    struct Palette {
        let selectedBackgroundColor: UIColor
        let unselectedBackgroundColor: UIColor
        let selectedForegroundColor: UIColor
        let unselectedForegroundColor: UIColor
    }

    static func palette(reduceTransparencyActive: Bool) -> Palette {
        let accent = UIColor.accent
        let selectedBackgroundAlpha: CGFloat = reduceTransparencyActive ? 0.3 : 0.22
        let unselectedBackgroundAlpha: CGFloat = reduceTransparencyActive ? 1.0 : 0.7

        return Palette(
            selectedBackgroundColor: accent.withAlphaComponent(selectedBackgroundAlpha),
            unselectedBackgroundColor: UIColor.secondarySystemBackground.withAlphaComponent(unselectedBackgroundAlpha),
            selectedForegroundColor: .label,
            unselectedForegroundColor: .secondaryLabel
        )
    }

    static func configureSegmentedControl(_ segmentedControl: UISegmentedControl, cornerRadius: CGFloat) {
        segmentedControl.layer.cornerRadius = cornerRadius
        segmentedControl.layer.cornerCurve = .continuous
        segmentedControl.layer.masksToBounds = true
        segmentedControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 15, weight: .regular),
        ], for: .normal)
        segmentedControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
        ], for: .selected)
    }

    static func applySegmentedStyle(
        to segmentedControl: UISegmentedControl,
        reduceTransparencyActive: Bool
    ) {
        let palette = palette(reduceTransparencyActive: reduceTransparencyActive)
        segmentedControl.selectedSegmentTintColor = palette.selectedBackgroundColor
        segmentedControl.backgroundColor = palette.unselectedBackgroundColor
        segmentedControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 15, weight: .regular),
            .foregroundColor: palette.unselectedForegroundColor,
        ], for: .normal)
        segmentedControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: palette.selectedForegroundColor,
        ], for: .selected)
    }
}
