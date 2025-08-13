//
//  SubscriptionController.swift
//  SubZen
//
//  Created by Star on 2025/7/17.
//

import SnapKit
import UIKit

class SubscriptionController: UIViewController {
    private let subscriptionListView = SubscriptionListView()
    let subscriptionManager = SubscriptionManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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

    func loadSubscriptions() {
        let subscriptions = subscriptionManager.getAllSubscriptions()
        subscriptionListView.updateSubscriptions(subscriptions)
    }
}

extension SubscriptionController: SubscriptionListViewDelegate {
		func subscriptionListViewDidTapAddButton() {
				addSubscriptionTapped()
		}
		
    func subscriptionListViewDidSelectSubscription(_ subscription: Subscription) {
        presentSubscriptionEditor(for: subscription)
    }
}
