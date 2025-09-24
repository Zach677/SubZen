//
//  EditSubscriptionView.swift
//  SubZen
//
//  Created by Star on 2025/8/14.
//

import SnapKit
import UIKit

class EditSubscriptionView: UIView {
    let nameLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = "Subscription Name"
    }

    let nameTextField = UITextField().with {
        $0.borderStyle = .roundedRect
        $0.placeholder = "Enter subscription name"
        $0.clearButtonMode = .whileEditing
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    let priceLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = "Price"
    }

    let priceTextField = UITextField().with {
        $0.borderStyle = .roundedRect
        $0.placeholder = "Enter price"
        $0.keyboardType = .decimalPad
        $0.clearButtonMode = .whileEditing
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    let currencyButton = UIButton(type: .system).with {
        $0.setTitle("Select", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.separator.cgColor
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    let cycleLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = "Cycle"
    }

    let cycleSegmentedControl = UISegmentedControl(items: BillingCycle.allCases.map(\.rawValue))

    let dateLabel = UILabel().with {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.text = "Last Billing Date"
    }

    let datePicker = UIDatePicker().with {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .compact
        $0.maximumDate = Date()
    }

    let saveButton = UIButton(type: .system).with {
        $0.setTitle("Save", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
        $0.contentHorizontalAlignment = .leading
    }

    lazy var nameStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 8
        $0.addArrangedSubview(nameLabel)
        $0.addArrangedSubview(nameTextField)
    }

    lazy var priceInputStackView = UIStackView().with {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .fill
        $0.distribution = .fill
        $0.addArrangedSubview(priceTextField)
        $0.addArrangedSubview(currencyButton)
    }

    lazy var priceStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 8
        $0.addArrangedSubview(priceLabel)
        $0.addArrangedSubview(priceInputStackView)
    }

    lazy var cycleStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 8
        $0.addArrangedSubview(cycleLabel)
        $0.addArrangedSubview(cycleSegmentedControl)
    }

    lazy var dateStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 8
        $0.alignment = .leading
        $0.addArrangedSubview(dateLabel)
        $0.addArrangedSubview(datePicker)
    }

    lazy var mainStackView = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 20
        $0.alignment = .fill
        $0.distribution = .fill
        $0.addArrangedSubview(nameStackView)
        $0.addArrangedSubview(priceStackView)
        $0.addArrangedSubview(cycleStackView)
        $0.addArrangedSubview(dateStackView)
        $0.addArrangedSubview(saveButton)
    }

    init() {
        super.init(frame: .zero)

        addSubview(mainStackView)

        mainStackView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide).offset(24)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.lessThanOrEqualTo(self.safeAreaLayoutGuide).inset(24)
        }

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        currencyButton.addTarget(self, action: #selector(currencyTapped), for: .touchUpInside)

        priceTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        priceTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    var onSaveTapped: (() -> Void)?
    var onCurrencyTapped: (() -> Void)?

    @objc private func saveTapped() {
        onSaveTapped?()
    }

    @objc private func currencyTapped() {
        onCurrencyTapped?()
    }

    func updateSelectedCurrencyDisplay(with currency: Currency) {
        let code = currency.code
        let symbol = CurrencyList.displaySymbol(for: code)
        let title = "\(currency.name) \(symbol) \(code)"
        currencyButton.setTitle(title, for: .normal)
        currencyButton.accessibilityLabel = "Selected currency: \(currency.name) \(code)"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
