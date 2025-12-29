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
        navigationController?.pushViewController(editorController, animated: true)
    }

    func deleteSubscription(_ subscription: Subscription) {
        let alert = UIAlertController(
            title: String(localized: "Delete Subscription"),
            message: String(localized: "Are you sure you want to delete \(subscription.name)?"),
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: String(localized: "Cancel"),
                style: .cancel
            )
        )
        alert.addAction(
            UIAlertAction(
                title: String(localized: "Delete"),
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
