//
//  NewSubButton.swift
//  SubZen
//
//  Created by Star on 2025/8/13.
//

import UIKit

protocol NewSubButtonDelegate: AnyObject {
    func newSubButtonTapped(_ button: NewSubButton)
}

class NewSubButton: UIButton {
    weak var delegate: NewSubButtonDelegate?

    private static let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)

    init(
        systemImageName: String,
        accessibilityLabel: String
    ) {
        super.init(frame: .zero)
        setImage(UIImage(systemName: systemImageName, withConfiguration: Self.symbolConfiguration), for: .normal)
        self.accessibilityLabel = accessibilityLabel
        tintColor = .label
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    convenience init() {
        self.init(
            systemImageName: "plus",
            accessibilityLabel: String(localized: "New Subscription")
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    @objc private func buttonTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform.identity
            }
        }
        delegate?.newSubButtonTapped(self)
    }
}
