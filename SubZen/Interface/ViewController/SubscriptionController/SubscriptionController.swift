//
//  SubscriptionController.swift
//  SubZen
//
//  Created by Star on 2025/7/17.
//

import SnapKit
import UIKit

protocol SubscriptionControllerSettingDelegate: AnyObject {
		func subscriptionControllerDidRequestSettings(_ controller: SubscriptionController)
}

class SubscriptionController: UIViewController {
    private let subscriptionListView = SubscriptionListView()
    let subscriptionManager = SubscriptionManager.shared
		weak var settingDelegate: SubscriptionControllerSettingDelegate?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        subscriptionListView.delegate = self

        view.addSubview(subscriptionListView)

        subscriptionListView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        // Observe creation and update events to keep list fresh
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionsChanged),
            name: .newSubCreated,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionsChanged),
            name: .subscriptionUpdated,
            object: nil
        )
        loadSubscriptions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSubscriptions()
    }

    func loadSubscriptions() {
        let subscriptions = subscriptionManager.getAllSubscriptions()
        subscriptionListView.updateSubscriptions(subscriptions)
    }

    @objc private func handleSubscriptionsChanged() {
        loadSubscriptions()
    }
}

extension SubscriptionController: SubscriptionListViewDelegate {
		func subscriptionListViewDidRequestSettings(_ listview: SubscriptionListView) {
				settingDelegate?.subscriptionControllerDidRequestSettings(self)
		}
		
		func subscriptionListViewDidTapAddButton() {
				addSubscriptionTapped()
		}
		
		func subscriptionListViewDidSelectSubscription(_ subscription: Subscription) {
				presentSubscriptionEditor(for: subscription)
		}
}
