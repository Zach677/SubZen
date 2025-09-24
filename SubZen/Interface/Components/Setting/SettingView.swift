//
//  SettingView.swift
//  SubZen
//
//  Created by Star on 2025/9/10.
//

import SnapKit
import UIKit

protocol SettingViewDelegate: AnyObject {
    func settingViewDidTapReset(_ view: SettingView)
}

class SettingView: UIView {
    weak var delegate: SettingViewDelegate?

    private let contentStack = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 24
        $0.alignment = .fill
    }

    private let titleLabel = UILabel().with {
        $0.text = "Reset"
        $0.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    private let resetActionView = ResetActionControl()

    private let separatorView = UIView().with {
        $0.backgroundColor = .separator
        $0.layer.cornerRadius = 0.5
        $0.clipsToBounds = true
    }

    private let warningLabel = UILabel().with {
        $0.text = "This action cannot be undone."
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .tertiaryLabel
        $0.numberOfLines = 0
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = .background
        setupLayout()
    }

    private func setupLayout() {
        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(32)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.lessThanOrEqualTo(safeAreaLayoutGuide.snp.bottom).offset(-32)
        }

        contentStack.addArrangedSubview(titleLabel)

        resetActionView.addTarget(self, action: #selector(handleResetTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(resetActionView)
        contentStack.setCustomSpacing(18, after: resetActionView)

        let infoStack = UIStackView(arrangedSubviews: [separatorView, warningLabel]).with {
            $0.axis = .vertical
            $0.spacing = 12
            $0.alignment = .fill
        }

        separatorView.snp.makeConstraints { make in
            make.height.equalTo(1)
        }

        contentStack.addArrangedSubview(infoStack)

        resetActionView.updateEnabledState(true, animated: false)
    }

    func setResetEnabled(_ enabled: Bool) {
        resetActionView.updateEnabledState(enabled, animated: true)
    }

    @objc private func handleResetTapped() {
        delegate?.settingViewDidTapReset(self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}

private final class ResetActionControl: UIControl {
    private let highlightView = UIView()
    private let contentStack = UIStackView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let spacer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override var isHighlighted: Bool {
        didSet { updateHighlight(animated: true) }
    }

    func updateEnabledState(_ enabled: Bool, animated: Bool = true) {
        isEnabled = enabled
        let tintColor = enabled ? UIColor.systemBlue : UIColor.systemGray2
        iconView.tintColor = tintColor
        titleLabel.textColor = tintColor
        descriptionLabel.textColor = enabled ? .secondaryLabel : .tertiaryLabel

        if enabled {
            activityIndicator.stopAnimating()
        } else {
            activityIndicator.startAnimating()
        }
        activityIndicator.isHidden = enabled

        let apply = {
            self.alpha = enabled ? 1.0 : 0.6
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: apply)
        } else {
            apply()
        }

        if !enabled {
            updateHighlight(animated: false)
        }
    }

    private func setup() {
        isAccessibilityElement = true
        accessibilityTraits.insert(.button)
        accessibilityLabel = "Reset"
        accessibilityHint = "Resets the application and clears all data."

        layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        highlightView.backgroundColor = UIColor.secondarySystemFill
        highlightView.layer.cornerRadius = 14
        highlightView.layer.cornerCurve = .continuous
        highlightView.alpha = 0
        highlightView.isUserInteractionEnabled = false
        addSubview(highlightView)
        highlightView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 6
        contentStack.alignment = .fill
        contentStack.isUserInteractionEnabled = false
        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(layoutMarginsGuide.snp.top)
            make.leading.equalTo(layoutMarginsGuide.snp.leading)
            make.trailing.equalTo(layoutMarginsGuide.snp.trailing)
            make.bottom.equalTo(layoutMarginsGuide.snp.bottom)
        }

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iconView.image = UIImage(systemName: "arrow.counterclockwise", withConfiguration: symbolConfig)
        iconView.tintColor = .systemBlue
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .systemBlue
        titleLabel.text = "Reset"

        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemBlue
        activityIndicator.isHidden = true

        let headerStack = UIStackView(arrangedSubviews: [iconView, titleLabel, spacer, activityIndicator])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        activityIndicator.setContentHuggingPriority(.required, for: .horizontal)
        activityIndicator.setContentCompressionResistancePriority(.required, for: .horizontal)

        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = "If you encounter any issues, try resetting the app. This removes all content and resets the entire database."

        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(descriptionLabel)

        updateHighlight(animated: false)
    }

    private func updateHighlight(animated: Bool) {
        let active = isHighlighted && isEnabled
        let changes = {
            self.highlightView.alpha = active ? 1.0 : 0.0
        }

        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseInOut], animations: changes)
        } else {
            changes()
        }
    }
}
