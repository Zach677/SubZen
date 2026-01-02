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
    private let currencyIconView = UIImageView.makeSettingIconView(systemName: "dollarsign.arrow.circlepath")

    private let currencyTitleLabel = UILabel.makeSettingTitleLabel(text: String(localized: "Currency") + " : ")

    private let currencyNameLabel = UILabel().with {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .label
        $0.textAlignment = .right
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private let privacyRow = UIControl()
    private let privacyIconView = UIImageView.makeSettingIconView(systemName: "lock.shield")

    private let privacyTitleLabel = UILabel.makeSettingTitleLabel(text: String(localized: "Privacy Policy"))

    private let privacyChevronView = UIImageView.makeChevronView()

    private let exportRow = UIControl()
    private let exportIconView = UIImageView.makeSettingIconView(systemName: "square.and.arrow.up")

    private let exportTitleLabel = UILabel.makeSettingTitleLabel(text: String(localized: "Export Subscriptions"))

    private let exportChevronView = UIImageView.makeChevronView()

    private let importRow = UIControl()
    private let importIconView = UIImageView.makeSettingIconView(systemName: "square.and.arrow.down")

    private let importTitleLabel = UILabel.makeSettingTitleLabel(text: String(localized: "Import Subscriptions"))

    private let importChevronView = UIImageView.makeChevronView()

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

        let currencyStack = makeSettingRowStack(with: [currencyIconView, currencyTitleLabel, UIView(), currencyNameLabel])
        configureSettingRow(currencyRow, with: currencyStack)

        let privacyStack = makeSettingRowStack(with: [privacyIconView, privacyTitleLabel, UIView(), privacyChevronView])
        configureSettingRow(privacyRow, with: privacyStack)

        let exportStack = makeSettingRowStack(with: [exportIconView, exportTitleLabel, UIView(), exportChevronView])
        configureSettingRow(exportRow, with: exportStack)

        let importStack = makeSettingRowStack(with: [importIconView, importTitleLabel, UIView(), importChevronView])
        configureSettingRow(importRow, with: importStack)

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

    private func configureSettingRow(_ row: UIControl, with stack: UIStackView) {
        stack.isUserInteractionEnabled = false
        row.layer.cornerRadius = 12
        row.layer.cornerCurve = .continuous
        row.backgroundColor = UIColor.accent.withAlphaComponent(0.4)
        row.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeSettingRowStack(with arrangedSubviews: [UIView]) -> UIStackView {
        UIStackView(arrangedSubviews: arrangedSubviews).with {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 12
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = .init(top: 12, left: 16, bottom: 12, right: 16)
        }
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
