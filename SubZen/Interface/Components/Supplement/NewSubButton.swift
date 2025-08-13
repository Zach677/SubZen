//
//  NewSubButton.swift
//  SubZen
//
//  Created by Star on 2025/8/13.
//

import UIKit

protocol NewSubButtonDelegate: AnyObject {
    func newSubButtonTapped()
}

class NewSubButton: UIButton {
    weak var delegate: NewSubButtonDelegate?

    init() {
        super.init(frame: .zero)
        setImage(UIImage(systemName: "plus"), for: .normal)
        backgroundColor = .label
        tintColor = .systemBackground
        layer.cornerRadius = 25
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    private func setupActions() {
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform.identity
            }
        }
        delegate?.newSubButtonTapped()
    }
}
