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

				contentStack.addArrangedSubview(titleLabel)
				contentStack.addArrangedSubview(currencyRow)
				contentStack.addArrangedSubview(resetSection)
				
				currencyRow.addTarget(self, action: #selector(handleCurrencyTapped), for: .touchUpInside)
				currencyRow.snp.makeConstraints { make in
						make.height.greaterThanOrEqualTo(44)
				}
				
				resetButton.snp.makeConstraints { make in
						make.height.equalTo(52)
				}

				#if DEBUG
						debugNotificationButton.addTarget(self, action: #selector(handleDebugNotificationTapped), for: .touchUpInside)
						contentStack.addArrangedSubview(debugNotificationButton)
				#endif
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
