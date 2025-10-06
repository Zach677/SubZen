//
//  SubscriptionListRowView.swift
//  SubZen
//
//  Created by Star on 2025/7/26.
//

import SnapKit
import UIKit

class SubscriptionListRowView: UIView {
    func configure(with subscription: Subscription) {
        titleLabel.text = subscription.name
        let code = subscription.currencyCode.uppercased()
        let currency = CurrencyList.getCurrency(byCode: code)
        let decimals = currency?.decimalDigits ?? 2
        let symbol = CurrencyList.displaySymbol(for: code)
        let cycleDisplayUnit = subscription.cycle.displayUnit

        let amount = SubscriptionListRowView.amountFormatter(for: decimals)
            .string(from: subscription.price as NSDecimalNumber) ?? "\(subscription.price)"

        let color = priceLabel.textColor ?? .secondaryLabel
        let priceFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let metaFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let prefixAttributes: [NSAttributedString.Key: Any] = [
            .font: metaFont,
            .foregroundColor: color.withAlphaComponent(0.7),
        ]

        let attributed = NSMutableAttributedString(
            string: "\(code) \(symbol) ",
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
                string: " / \(cycleDisplayUnit)",
                attributes: [
                    .font: metaFont,
                    .foregroundColor: color.withAlphaComponent(0.7),
                ]
            )
        )

        priceLabel.attributedText = attributed
        let accessibilityAmountDescription = String(localized: "\(code) \(symbol) \(amount) per \(cycleDisplayUnit)")
        priceLabel.accessibilityLabel = accessibilityAmountDescription

        let remainingDays = subscription.remainingDays
        daysLabel.text = String(localized: "\(remainingDays) days left")
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
        $0.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        $0.textColor = .label
    }

    let priceLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .right
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
    }

    init() {
        super.init(frame: .zero)

        backgroundColor = .accent.withAlphaComponent(0.1)
        layer.cornerRadius = 12
        layer.masksToBounds = true

        addSubview(titleLabel)
        addSubview(rightStackView)

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(rightStackView.snp.leading).offset(-8)
        }

        rightStackView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview().offset(12)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
