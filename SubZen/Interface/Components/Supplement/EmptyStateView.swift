//
//  EmptyStateView.swift
//  SubZen
//
//  Created by Star on 2025/8/10.
//

import UIKit

class EmptyStateView: UIView {
    let containerView = UIView()

    let iconImageView = UIImageView(image: UIImage(systemName: "creditcard")).with {
        $0.tintColor = .secondaryLabel
        $0.contentMode = .scaleAspectFit
    }

    let titleLabel = UILabel().with {
        $0.text = "No Subscriptions"
        $0.font = .systemFont(ofSize: 22, weight: .medium)
        $0.textColor = .label
        $0.textAlignment = .center
    }

    let subtitleLabel = UILabel().with {
        $0.text = "Add your first subscription to get started"
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }

    lazy var stackView = UIStackView(arrangedSubviews: [iconImageView, titleLabel, subtitleLabel]).with {
        $0.axis = .vertical
        $0.spacing = 16
        $0.alignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func setupViews() {
        addSubview(containerView)
        containerView.addSubview(stackView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(88)
        }
    }
}
