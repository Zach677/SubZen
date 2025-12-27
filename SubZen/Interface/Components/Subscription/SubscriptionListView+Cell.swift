//
//  SubscriptionListView+Cell.swift
//  SubZen
//
//  Created by Star on 2025/8/10.
//

import UIKit

extension SubscriptionListView {
    class SubscriptionTableViewCell: UITableViewCell {
        static let reuseIdentifier = "SubscriptionListViewCell"

        private let cardView = SubscriptionListRowView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            backgroundColor = .clear

            contentView.addSubview(cardView)
            cardView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        func configure(with subscription: Subscription) {
            cardView.configure(with: subscription)
        }
    }
}
