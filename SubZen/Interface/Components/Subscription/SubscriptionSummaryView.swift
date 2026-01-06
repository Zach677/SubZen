//
//  SubscriptionSummaryView.swift
//  SubZen
//
//  Created by Star on 2025/10/8.
//

import GlyphixTextFx
import SnapKit
import UIKit

struct SubscriptionSummaryViewModel {
    let currency: Currency
    let total: Decimal
}

final class SubscriptionSummaryView: UIView {
    private let amountLabel = GlyphixTextLabel().with {
        $0.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        $0.textColor = .label
        $0.textAlignment = .center
        $0.isSmoothRenderingEnabled = true
    }

    private var lastTotal: Decimal?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        addSubview(amountLabel)
        amountLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func configure(with model: SubscriptionSummaryViewModel?) {
        guard let model else {
            isHidden = true
            lastTotal = nil
            return
        }

        isHidden = false
        if let lastTotal {
            amountLabel.countsDown = model.total < lastTotal
        }
        amountLabel.text = formattedAmount(for: model.currency, amount: model.total)
        lastTotal = model.total
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
