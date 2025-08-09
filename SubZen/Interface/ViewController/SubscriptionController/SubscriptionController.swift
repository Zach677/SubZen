//
//  SubscriptionController.swift
//  SubZen
//
//  Created by Star on 2025/7/17.
//

import UIKit

class SubscriptionController: UIViewController {
		private let subscriptionCard = SubscriptionCardView()
		
		override func viewDidLoad() {
				super.viewDidLoad()
				
				view.backgroundColor = UIColor.systemBackground
				
				setupUI()
		}
		
		private func setupUI() {
				view.addSubview(subscriptionCard)
				
				subscriptionCard.snp.makeConstraints { make in
						make.top.equalTo(view.safeAreaLayoutGuide).offset(100)
						make.leading.equalToSuperview().offset(20)
						make.trailing.equalToSuperview().offset(-20)
				}
		}

}
