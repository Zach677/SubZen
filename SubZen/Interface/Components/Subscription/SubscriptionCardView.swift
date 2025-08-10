//
//  SubscriptionCardView.swift
//  SubZen
//
//  Created by Star on 2025/7/26.
//

import SnapKit
import UIKit

class SubscriptionCardView: UIView {
		
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

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.secondarySystemGroupedBackground
        layer.cornerRadius = 12
        layer.masksToBounds = true

        addSubview(titleLabel)
        addSubview(priceLabel)
        addSubview(daysLabel)

        titleLabel.snp.makeConstraints { make in
						make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(priceLabel.snp.leading).offset(-8)
        }

        priceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-16)
        }

        daysLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(8)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(80)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
				fatalError()
    }
}
