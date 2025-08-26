//
//  EditSubscrptionView.swift
//  SubZen
//
//  Created by Star on 2025/8/14.
//

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
		
		lazy var nameStackView = UIStackView().with {
				$0.axis = .vertical
				$0.spacing = 8
				$0.addArrangedSubview(nameLabel)
				$0.addArrangedSubview(nameTextField)
		}
		
		lazy var priceStackView = UIStackView().with {
				$0.axis = .vertical
				$0.spacing = 8
				$0.addArrangedSubview(priceLabel)
				$0.addArrangedSubview(priceTextField)
		}
		
		lazy var dateStackView = UIStackView().with {
				$0.axis = .vertical
				$0.spacing = 8
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
				$0.addArrangedSubview(dateStackView)
		}
		
		init() {
				super.init(frame: .zero)
				
				addSubview(mainStackView)
				
				mainStackView.snp.makeConstraints { make in
						make.top.equalTo(self.safeAreaLayoutGuide).offset(24)
						make.leading.equalToSuperview().offset(16)
						make.bottom.lessThanOrEqualTo(self.safeAreaLayoutGuide).offset(24)
				}
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) {
				fatalError()
		}
}
				
			
