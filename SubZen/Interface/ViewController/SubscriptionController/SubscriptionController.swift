//
//  SubscriptionController.swift
//  SubZen
//
//  Created by Star on 2025/7/17.
//

import UIKit
import SnapKit

class SubscriptionController: UIViewController {
    private let subscriptionListView = SubscriptionListView()
		internal let subscriptionManager = SubscriptionManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
				setupNavigationBar()
				loadSubscriptions()
    }
		
		override func viewWillAppear(_ animated: Bool) {
				super.viewWillAppear(animated)
				loadSubscriptions()
		}

    private func setupUI() {
				view.backgroundColor = .systemGroupedBackground
				
				subscriptionListView.delegate = self
				
        view.addSubview(subscriptionListView)

        subscriptionListView.snp.makeConstraints { make in
						make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
		
		private func setupNavigationBar() {
				title = "Subscriptions"
				navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSubscriptionTapped))
		}
		
		internal func loadSubscriptions() {
				let subscriptions = subscriptionManager.getAllSubscriptions()
				subscriptionListView.updateSubscriptions(subscriptions)
		}
}

extension SubscriptionController: SubscriptionListViewDelegate {
		func subscriptionListViewDidSelectSubscription(_ subscription: Subscription) {
				presentSubscriptionEditor(for: subscription)
		}
}
