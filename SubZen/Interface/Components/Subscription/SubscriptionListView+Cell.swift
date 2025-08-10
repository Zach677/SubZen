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

        private let cardView = SubscriptionCardView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupUI()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        private func setupUI() {
            selectionStyle = .none
            backgroundColor = .clear

            contentView.addSubview(cardView)
            cardView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
            }
        }

        func configure(with subscription: Subscription) {
            cardView.configure(with: subscription)
        }

        override func setHighlighted(_ highlighted: Bool, animated: Bool) {
            super.setHighlighted(highlighted, animated: animated)

            UIView.animate(withDuration: 0.1) {
                self.cardView.transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
                self.cardView.alpha = highlighted ? 0.8 : 1.0
            }
        }
    }
}
