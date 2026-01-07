//
//  SubscriptionListRowView.swift
//  SubZen
//
//  Created by Star on 2025/7/26.
//

import SnapKit
import UIKit

class SubscriptionListRowView: UIView {
    // MARK: - Expiration Progress Gradient

    private let progressGradientLayer = CAGradientLayer()
    private var currentProgress: Double = 0

    private let iconImageView = UIImageView().with {
        $0.contentMode = .scaleAspectFill
        $0.image = UIImage.subZenAppIconPlaceholder
        $0.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)
        $0.layer.cornerRadius = 10
        $0.layer.cornerCurve = .continuous
        $0.layer.masksToBounds = true
    }

    private var iconTask: Task<Void, Never>?
    private var currentSubscriptionID: UUID?

    func configure(with subscription: Subscription, iconStore: SubscriptionIconStore?) {
        currentSubscriptionID = subscription.id
        iconTask?.cancel()
        iconImageView.image = UIImage.subZenAppIconPlaceholder
        iconImageView.contentMode = .scaleAspectFill

        if let iconStore {
            let subscriptionID = subscription.id
            iconTask = Task { [weak self] in
                let image = await iconStore.icon(for: subscriptionID)
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    guard self.currentSubscriptionID == subscriptionID else { return }
                    guard let image else { return }
                    self.iconImageView.image = image
                    self.iconImageView.contentMode = .scaleAspectFill
                }
            }
        }

        titleLabel.text = subscription.name
        let code = subscription.currencyCode.uppercased()
        let currency = CurrencyList.currency(for: code)
        let decimals = currency?.decimalDigits ?? 2
        let symbol = CurrencyList.displaySymbol(for: code)
        let cycleDisplayUnit = subscription.cycle.displayUnit

        // For custom cycles with value > 1, show "/ 2 months" instead of "/ months"
        let cycleDisplay = if case let .custom(value, _) = subscription.cycle, value > 1 {
            " / \(value) \(cycleDisplayUnit)"
        } else {
            " / \(cycleDisplayUnit)"
        }

        let amount = SubscriptionListRowView.amountFormatter(for: decimals)
            .string(from: subscription.price as NSDecimalNumber) ?? "\(subscription.price)"

        let color = priceLabel.textColor ?? .secondaryLabel
        let priceFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let metaFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let prefixAttributes: [NSAttributedString.Key: Any] = [
            .font: metaFont,
            .foregroundColor: color.withAlphaComponent(0.7),
        ]

        // Avoid redundant display when symbol already contains the currency code prefix
        // e.g., for CNY with symbol "CN¥", display "CNY ¥" instead of "CNY CN¥"
        let displayText: String
        if symbol.hasPrefix(code) || symbol.hasPrefix(code.prefix(2)) {
            // Symbol contains code prefix (e.g., "CN¥"), show code + cleaned symbol
            let cleanedSymbol = symbol.trimmingCharacters(in: CharacterSet.letters)
            displayText = "\(code) \(cleanedSymbol) "
        } else {
            // Normal case: code and symbol are distinct
            displayText = "\(code) \(symbol) "
        }

        let attributed = NSMutableAttributedString(
            string: displayText,
            attributes: prefixAttributes
        )
        attributed.append(
            NSAttributedString(
                string: amount,
                attributes: [
                    .font: priceFont,
                    .foregroundColor: color,
                ]
            )
        )
        attributed.append(
            NSAttributedString(
                string: cycleDisplay,
                attributes: [
                    .font: metaFont,
                    .foregroundColor: color.withAlphaComponent(0.7),
                ]
            )
        )

        priceLabel.attributedText = attributed
        let accessibilityCycleDisplay: String
        if case let .custom(value, _) = subscription.cycle, value > 1 {
            let quantity = Int64(value)
            let key: String.LocalizationValue = "\(quantity) \(cycleDisplayUnit)"
            accessibilityCycleDisplay = String(localized: key)
        } else {
            accessibilityCycleDisplay = cycleDisplayUnit
        }

        let accessibilityKey: String.LocalizationValue = "\(code) \(symbol) \(amount) per \(accessibilityCycleDisplay)"
        let accessibilityAmountDescription = String(localized: accessibilityKey)
        priceLabel.accessibilityLabel = accessibilityAmountDescription

        if subscription.isLifetime {
            daysLabel.text = String(localized: "Lifetime")
            daysLabel.textColor = .secondaryLabel
        } else {
            let remainingDays = subscription.remainingDays
            let daysLeftKey: String.LocalizationValue = "\(Int64(remainingDays)) days left"
            daysLabel.text = String(localized: daysLeftKey)
            if remainingDays == 0 {
                daysLabel.text = String(localized: "Today!")
                daysLabel.textColor = .systemRed.withAlphaComponent(0.8)
            } else {
                daysLabel.textColor = .systemBlue.withAlphaComponent(0.7)
            }
        }

        // Update expiration progress gradient with animation
        let targetProgress = subscription.expirationProgress
        animateProgress(to: targetProgress)
    }

    private static var formatterCache: [Int: NumberFormatter] = [:]

    private static func amountFormatter(for decimalDigits: Int) -> NumberFormatter {
        if let cached = formatterCache[decimalDigits] {
            return cached
        }
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalDigits
        formatter.maximumFractionDigits = decimalDigits
        formatterCache[decimalDigits] = formatter
        return formatter
    }

    let titleLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .label
        $0.numberOfLines = 2
        $0.lineBreakMode = .byTruncatingTail
        $0.allowsDefaultTighteningForTruncation = true
        $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    let priceLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .right
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingHead
        $0.allowsDefaultTighteningForTruncation = true
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    let daysLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .systemBlue.withAlphaComponent(0.7)
        $0.textAlignment = .right
    }

    lazy var rightStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .trailing
        $0.distribution = .fill
        $0.addArrangedSubview(priceLabel)
        $0.addArrangedSubview(daysLabel)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    init() {
        super.init(frame: .zero)

        backgroundColor = .accent.withAlphaComponent(0.1)
        layer.cornerRadius = 12
        layer.masksToBounds = true

        // Setup progress gradient layer (left to right fill)
        progressGradientLayer.colors = [
            UIColor.accent.withAlphaComponent(0.35).cgColor,
            UIColor.accent.withAlphaComponent(0.15).cgColor,
        ]
        progressGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        progressGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        progressGradientLayer.cornerRadius = 12
        layer.insertSublayer(progressGradientLayer, at: 0)
        updateGradientLocations(progress: 0)

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(rightStackView)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(14)
            make.size.equalTo(38)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(rightStackView.snp.leading).offset(-6)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }

        rightStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-12)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(6)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressGradientLayer.frame = bounds
        CATransaction.commit()
    }

    // MARK: - Progress Gradient Helpers

    private func updateGradientLocations(progress: Double) {
        // Gradient fills from left (0) to progress point, then fades to transparent
        let fillEnd = max(0.001, min(0.999, progress))
        progressGradientLayer.locations = [0, NSNumber(value: fillEnd)]

        // Adjust opacity: more progress = more visible gradient
        let baseAlpha = 0.15 + (progress * 0.25)
        progressGradientLayer.colors = [
            UIColor.accent.withAlphaComponent(baseAlpha + 0.15).cgColor,
            UIColor.accent.withAlphaComponent(baseAlpha * 0.3).cgColor,
        ]
    }

    private func animateProgress(to targetProgress: Double) {
        guard abs(targetProgress - currentProgress) > 0.01 else {
            updateGradientLocations(progress: targetProgress)
            currentProgress = targetProgress
            return
        }

        currentProgress = targetProgress

        // Animate the gradient fill
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0, NSNumber(value: 0.001)]
        animation.toValue = [0, NSNumber(value: max(0.001, targetProgress))]
        animation.duration = 0.6
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        progressGradientLayer.add(animation, forKey: "progressAnimation")

        // Update to final state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.progressGradientLayer.removeAnimation(forKey: "progressAnimation")
            self?.updateGradientLocations(progress: targetProgress)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
