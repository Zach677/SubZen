//
//  SubscriptionSummaryView.swift
//  SubZen
//
//  Created by Star on 2025/10/8.
//

import SnapKit
import UIKit

struct SubscriptionSummaryViewModel {
    let currency: Currency
    let total: Decimal
}

final class SubscriptionSummaryView: UIView {
    private let container = UIView().with {
        $0.backgroundColor = .accent.withAlphaComponent(0.12)
        $0.layer.cornerRadius = 14
        $0.layer.masksToBounds = true
    }

    private let titleLabel = UILabel().with {
        $0.text = String(localized: "Monthly Spend")
        $0.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        $0.textColor = .secondaryLabel
    }

    private let amountLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        $0.textColor = .label
        $0.adjustsFontForContentSizeCategory = true
    }

    private lazy var stack = UIStackView(arrangedSubviews: [titleLabel, amountLabel]).with {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .leading
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        addSubview(container)
        container.addSubview(stack)

        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview()
        }

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func configure(with model: SubscriptionSummaryViewModel?) {
        guard let model else {
            isHidden = true
            return
        }

        isHidden = false
        amountLabel.text = formattedAmount(for: model.currency, amount: model.total)
    }

    private func formattedAmount(for currency: Currency, amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.minimumFractionDigits = max(0, currency.decimalDigits)
        formatter.maximumFractionDigits = max(2, currency.decimalDigits)
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency.symbol) \(amount)"
    }
}
