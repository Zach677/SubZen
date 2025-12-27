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
    func settingViewDidTapDefaultCurrency(_ view: SettingView)
    func settingViewDidTapExportSubscriptions(_ view: SettingView)
    func settingViewDidTapImportSubscriptions(_ view: SettingView)
    func settingViewDidTapPrivacyPolicy(_ view: SettingView)

    #if DEBUG
        func settingViewDidTapDebugNotification(_ view: SettingView)
    #endif
}

class SettingView: UIView {
    weak var delegate: SettingViewDelegate?

    private let contentStack = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 24
        $0.alignment = .fill
    }

    private let titleLabel = UILabel().with {
        $0.text = String(localized: "Setting")
        $0.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    private let currencyRow = UIControl()
    private let currencyIconView = UIImageView(image: UIImage(systemName: "dollarsign.arrow.circlepath")).with {
        $0.tintColor = .secondaryLabel
        $0.contentMode = .scaleAspectFit
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private let currencyTitleLabel = UILabel().with {
        $0.text = String(localized: "Currency") + " : "
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
    }

    private let currencyNameLabel = UILabel().with {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .label
        $0.textAlignment = .right
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private let privacyRow = UIControl()
    private let privacyIconView = UIImageView(image: UIImage(systemName: "lock.shield")).with {
        $0.tintColor = .secondaryLabel
        $0.contentMode = .scaleAspectFit
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private let privacyTitleLabel = UILabel().with {
        $0.text = String(localized: "Privacy Policy")
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
    }

    private let privacyChevronView = UIImageView(image: UIImage(systemName: "chevron.right")).with {
        $0.tintColor = .tertiaryLabel
        $0.contentMode = .scaleAspectFit
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private let exportRow = UIControl()
    private let exportIconView = UIImageView(image: UIImage(systemName: "square.and.arrow.up")).with {
        $0.tintColor = .secondaryLabel
        $0.contentMode = .scaleAspectFit
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private let exportTitleLabel = UILabel().with {
        $0.text = String(localized: "Export Subscriptions")
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
    }

    private let exportChevronView = UIImageView(image: UIImage(systemName: "chevron.right")).with {
        $0.tintColor = .tertiaryLabel
        $0.contentMode = .scaleAspectFit
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private let importRow = UIControl()
    private let importIconView = UIImageView(image: UIImage(systemName: "square.and.arrow.down")).with {
        $0.tintColor = .secondaryLabel
        $0.contentMode = .scaleAspectFit
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private let importTitleLabel = UILabel().with {
        $0.text = String(localized: "Import Subscriptions")
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
    }

    private let importChevronView = UIImageView(image: UIImage(systemName: "chevron.right")).with {
        $0.tintColor = .tertiaryLabel
        $0.contentMode = .scaleAspectFit
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private lazy var resetButton = UIButton().with { button in
        let title = String(localized: "Reset All Data")
        let insets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)

        if #available(iOS 26.0, *), !UIAccessibility.isReduceMotionEnabled {
            var config = UIButton.Configuration.prominentGlass()
            config.title = title
            config.contentInsets = insets
            config.cornerStyle = .large
            config.buttonSize = .large
            config.baseForegroundColor = .white
            config.background.backgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
            button.configuration = config
        } else {
            var config = UIButton.Configuration.borderedProminent()
            config.title = title
            config.cornerStyle = .large
            config.baseBackgroundColor = .white
            config.buttonSize = .large
            config.contentInsets = insets
            config.baseBackgroundColor = .systemRed
            button.configuration = config
        }

        button.addTarget(self, action: #selector(handleResetTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "reset_all_data_button"
    }

    private let warningLabel = UILabel().with {
        $0.text = String(localized: "This action cannot be undone.")
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .tertiaryLabel
        $0.numberOfLines = 0
    }

    private let versionLabel = UILabel().with {
        $0.text = AppVersion.displayString
        $0.font = .preferredFont(forTextStyle: .caption2)
        $0.textColor = .tertiaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 1
    }

    private let buildTimeLabel = UILabel().with {
        $0.text = BuildInfo.buildTime
        $0.font = .preferredFont(forTextStyle: .caption2).monospaced
        $0.textColor = .tertiaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 1
    }

    private let commitLabel = UILabel().with {
        let commitID = BuildInfo.commitID
        $0.text = commitID.isEmpty ? "N/A" : commitID
        $0.font = .preferredFont(forTextStyle: .caption2).monospaced
        $0.textColor = .tertiaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 1
    }

    private lazy var versionFooterStack = UIStackView(arrangedSubviews: [
        versionLabel,
        buildTimeLabel,
        commitLabel,
    ]).with {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 4
    }

    #if DEBUG
        private lazy var debugNotificationButton = UIButton(type: .system).with {
            $0.setTitle(
                String(localized: "Send Debug Renewal Notifications"),
                for: .normal
            )
            $0.setTitleColor(.systemOrange, for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            $0.contentHorizontalAlignment = .leading
        }
    #endif

    init() {
        super.init(frame: .zero)
        backgroundColor = .background
        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(32)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.lessThanOrEqualTo(safeAreaLayoutGuide.snp.bottom).offset(-32)
        }

        let resetSection = UIStackView(arrangedSubviews: [resetButton, warningLabel]).with {
            $0.axis = .vertical
            $0.spacing = 8
            $0.alignment = .fill
        }

        let currencyStack = UIStackView(arrangedSubviews: [currencyIconView, currencyTitleLabel, UIView(), currencyNameLabel]).with {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 12
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = .init(top: 12, left: 16, bottom: 12, right: 16)
        }
        currencyStack.isUserInteractionEnabled = false
        currencyRow.layer.cornerRadius = 12
        currencyRow.layer.cornerCurve = .continuous
        currencyRow.backgroundColor = UIColor.accent.withAlphaComponent(0.4)

        currencyRow.addSubview(currencyStack)
        currencyStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let privacyStack = UIStackView(arrangedSubviews: [privacyIconView, privacyTitleLabel, UIView(), privacyChevronView]).with {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 12
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = .init(top: 12, left: 16, bottom: 12, right: 16)
        }
        privacyStack.isUserInteractionEnabled = false
        privacyRow.layer.cornerRadius = 12
        privacyRow.layer.cornerCurve = .continuous
        privacyRow.backgroundColor = UIColor.accent.withAlphaComponent(0.4)

        privacyRow.addSubview(privacyStack)
        privacyStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let exportStack = UIStackView(arrangedSubviews: [exportIconView, exportTitleLabel, UIView(), exportChevronView]).with {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 12
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = .init(top: 12, left: 16, bottom: 12, right: 16)
        }
        exportStack.isUserInteractionEnabled = false
        exportRow.layer.cornerRadius = 12
        exportRow.layer.cornerCurve = .continuous
        exportRow.backgroundColor = UIColor.accent.withAlphaComponent(0.4)

        exportRow.addSubview(exportStack)
        exportStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let importStack = UIStackView(arrangedSubviews: [importIconView, importTitleLabel, UIView(), importChevronView]).with {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 12
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = .init(top: 12, left: 16, bottom: 12, right: 16)
        }
        importStack.isUserInteractionEnabled = false
        importRow.layer.cornerRadius = 12
        importRow.layer.cornerCurve = .continuous
        importRow.backgroundColor = UIColor.accent.withAlphaComponent(0.4)

        importRow.addSubview(importStack)
        importStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(currencyRow)
        contentStack.addArrangedSubview(exportRow)
        contentStack.addArrangedSubview(importRow)
        contentStack.addArrangedSubview(privacyRow)
        contentStack.addArrangedSubview(resetSection)

        currencyRow.addTarget(self, action: #selector(handleCurrencyTapped), for: .touchUpInside)
        currencyRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }

        privacyRow.addTarget(self, action: #selector(handlePrivacyTapped), for: .touchUpInside)
        privacyRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }

        exportRow.addTarget(self, action: #selector(handleExportTapped), for: .touchUpInside)
        exportRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }

        importRow.addTarget(self, action: #selector(handleImportTapped), for: .touchUpInside)
        importRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }

        resetButton.snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        #if DEBUG
            debugNotificationButton.addTarget(self, action: #selector(handleDebugNotificationTapped), for: .touchUpInside)
            contentStack.addArrangedSubview(debugNotificationButton)
        #endif

        contentStack.addArrangedSubview(UIView()) // Spacer
        contentStack.addArrangedSubview(versionFooterStack)
    }

    func setResetEnabled(_ enabled: Bool) {
        resetButton.isEnabled = enabled
        UIView.animate(withDuration: 0.2) {
            self.resetButton.alpha = enabled ? 1.0 : 0.6
        }
    }

    func setDefaultCurrency(_ currency: Currency) {
        currencyNameLabel.text = currency.name
    }

    @objc private func handleCurrencyTapped() {
        delegate?.settingViewDidTapDefaultCurrency(self)
    }

    @objc private func handlePrivacyTapped() {
        delegate?.settingViewDidTapPrivacyPolicy(self)
    }

    @objc private func handleExportTapped() {
        delegate?.settingViewDidTapExportSubscriptions(self)
    }

    @objc private func handleImportTapped() {
        delegate?.settingViewDidTapImportSubscriptions(self)
    }

    @objc private func handleResetTapped() {
        delegate?.settingViewDidTapReset(self)
    }

    #if DEBUG
        @objc private func handleDebugNotificationTapped() {
            delegate?.settingViewDidTapDebugNotification(self)
        }
    #endif

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
