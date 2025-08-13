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
        priceLabel.text = subscription.formattedPrice
        daysLabel.text = "\(subscription.remainingDays) days left"
    }

    let titleLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        $0.textColor = UIColor.label
    }

    let priceLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = UIColor.secondaryLabel
        $0.textAlignment = .right
    }

    let daysLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = UIColor.systemBlue
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

        backgroundColor = UIColor.secondarySystemGroupedBackground
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
