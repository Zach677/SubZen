import SnapKit
import UIKit

final class FloatingSaveBarView: UIView {
    private let contentView = UIView()
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    let saveButton = UIButton(type: .system)

    private let containerLayoutMargins: NSDirectionalEdgeInsets
    private let buttonContentInsets: NSDirectionalEdgeInsets
    private let cornerRadius: CGFloat
    private let minimumButtonHeight: CGFloat
    private var reduceTransparencyActive = UIAccessibility.isReduceTransparencyEnabled

    init(
        containerLayoutMargins: NSDirectionalEdgeInsets,
        buttonContentInsets: NSDirectionalEdgeInsets,
        cornerRadius: CGFloat,
        minimumButtonHeight: CGFloat
    ) {
        self.containerLayoutMargins = containerLayoutMargins
        self.buttonContentInsets = buttonContentInsets
        self.cornerRadius = cornerRadius
        self.minimumButtonHeight = minimumButtonHeight
        super.init(frame: .zero)
        configureView()
        buildHierarchy()
        setupConstraints()
    }

    private func configureView() {
        clipsToBounds = false
        layer.masksToBounds = false

        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner,
        ]
        contentView.directionalLayoutMargins = containerLayoutMargins

        backgroundView.clipsToBounds = true
        backgroundView.layer.cornerRadius = cornerRadius
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner,
        ]
        backgroundView.isUserInteractionEnabled = false
        backgroundView.isHidden = true

        saveButton.accessibilityTraits.insert(.button)
    }

    private func buildHierarchy() {
        addSubview(contentView)
        contentView.addSubview(backgroundView)
        contentView.addSubview(saveButton)
    }

    private func setupConstraints() {
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(contentView.layoutMarginsGuide.snp.top)
            make.leading.equalTo(contentView.layoutMarginsGuide.snp.leading)
            make.trailing.equalTo(contentView.layoutMarginsGuide.snp.trailing)
            make.bottom.equalTo(contentView.layoutMarginsGuide.snp.bottom).priority(.high)
            make.height.greaterThanOrEqualTo(minimumButtonHeight).priority(.high)
        }
    }

    func updateAppearance(
        reduceTransparencyActive newValue: Bool,
        title: String
    ) {
        reduceTransparencyActive = newValue

        if reduceTransparencyActive {
            let fallbackColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)
            backgroundView.isHidden = false
            backgroundView.effect = nil
            backgroundView.backgroundColor = fallbackColor
            backgroundView.contentView.backgroundColor = fallbackColor
            contentView.backgroundColor = fallbackColor
        } else {
            backgroundView.isHidden = true
            backgroundView.effect = nil
            backgroundView.backgroundColor = .clear
            backgroundView.contentView.backgroundColor = .clear
            contentView.backgroundColor = .clear
        }

        EditSubscriptionButtonStyler.applySaveButtonStyle(
            to: saveButton,
            title: title,
            reduceTransparencyActive: reduceTransparencyActive,
            contentInsets: buttonContentInsets
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
