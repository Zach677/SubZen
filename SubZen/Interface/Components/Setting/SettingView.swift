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
        $0.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    private let resetButton = UIButton(type: .system).with {
        $0.tintColor = .white
        $0.layer.cornerRadius = 16
        $0.layer.cornerCurve = .continuous
        $0.layer.shadowColor = UIColor.systemRed.withAlphaComponent(0.35).cgColor
        $0.layer.shadowOpacity = 1
        $0.layer.shadowRadius = 12
        $0.layer.shadowOffset = CGSize(width: 0, height: 6)
        $0.adjustsImageWhenHighlighted = false

        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = .systemRed
            config.baseForegroundColor = .white
            config.cornerStyle = .large
            config.image = UIImage(systemName: "arrow.counterclockwise.circle.fill")
            config.imagePlacement = .leading
            config.imagePadding = 12
            config.attributedTitle = AttributedString("Reset", attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            ]))
            config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 20)
            $0.configuration = config
        } else {
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            $0.setImage(UIImage(systemName: "arrow.counterclockwise.circle.fill", withConfiguration: symbolConfig), for: .normal)
            $0.setTitle("Reset", for: .normal)
            $0.setTitleColor(.white, for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            $0.backgroundColor = .systemRed
            $0.contentEdgeInsets = UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24)
            $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 12)
        }
    }

    private let activityIndicator = UIActivityIndicatorView(style: .medium).with {
        $0.hidesWhenStopped = true
        $0.color = .white
    }

    private let subtitleLabel = UILabel().with {
        $0.text = "If you encoutner any issues, you can try to reset the app.This will remove all content and reset the entire database."
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

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

        let resetContainer = UIView()
        resetContainer.backgroundColor = .secondarySystemBackground
        resetContainer.layer.cornerRadius = 14

        resetContainer.addSubview(resetButton)
        resetButton.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
            make.height.greaterThanOrEqualTo(56)
        }

        if #available(iOS 15.0, *) {
            // Use UIButton.Configuration's activity indicator on modern systems.
        } else {
            resetButton.addSubview(activityIndicator)
            activityIndicator.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-16)
            }
        }

        resetButton.addTarget(self, action: #selector(handleResetTapped), for: .touchUpInside)

        contentStack.addArrangedSubview(resetContainer)

        let infoStack = UIStackView(arrangedSubviews: [subtitleLabel, separatorView, warningLabel]).with {
            $0.axis = .vertical
            $0.spacing = 12
            $0.alignment = .fill
        }

        separatorView.snp.makeConstraints { make in
            make.height.equalTo(1)
        }

        contentStack.addArrangedSubview(infoStack)
    }

    func setResetEnabled(_ enabled: Bool) {
        resetButton.isEnabled = enabled
        resetButton.layer.shadowOpacity = enabled ? 1.0 : 0.0

        if #available(iOS 15.0, *) {
            if var config = resetButton.configuration {
                config.baseBackgroundColor = enabled ? .systemRed : .systemRed.withAlphaComponent(0.65)
                config.baseForegroundColor = enabled ? .white : UIColor.white.withAlphaComponent(0.75)
                config.showsActivityIndicator = !enabled
                resetButton.configuration = config
            }
        } else {
            if enabled {
                activityIndicator.stopAnimating()
            } else {
                activityIndicator.startAnimating()
            }
        }

        UIView.animate(withDuration: 0.2) {
            self.resetButton.alpha = enabled ? 1.0 : 0.7
        }
    }

    @objc private func handleResetTapped() {
        delegate?.settingViewDidTapReset(self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
