//
//  SubscriptionController+Actions.swift
//  SubZen
//
//  Created by Star on 2025/7/15.
//

import UIKit

extension SubscriptionController {
    @objc func addSubscriptionTapped() {
        presentSubscriptionEditor()
    }

    func presentSubscriptionEditor(for subscription: Subscription? = nil) {
        let editorController = SubscriptionEditorController(subscription: subscription)
        present(editorController, animated: true)
    }

    func deleteSubscription(_ subscription: Subscription) {
        let alert = UIAlertController(
            title: String(localized: "subscriptions.delete.alert.title"),
            message: String(localized: "subscriptions.delete.alert.message"),
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: String(localized: "common.cancel"),
                style: .cancel
            )
        )
        alert.addAction(
            UIAlertAction(
                title: String(localized: "common.delete"),
                style: .destructive
            ) { [weak self] _ in
                self?.performDeleteSubscription(subscription)
            }
        )

        present(alert, animated: true)
    }

    private func performDeleteSubscription(_ subscription: Subscription) {
        subscriptionManager.deleteSubscription(identifier: subscription.id)
        loadSubscriptions()
    }
}
