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
            title: String(
                localized: "subscriptions.delete.alert.title",
                defaultValue: "Delete Subscription",
                comment: "Title for the delete subscription confirmation alert"
            ),
            message: String(
                localized: "subscriptions.delete.alert.message",
                defaultValue: "Are you sure you want to delete \(subscription.name)?",
                comment: "Message shown when asking the user to confirm subscription deletion"
            ),
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: String(
                    localized: "common.cancel",
                    defaultValue: "Cancel",
                    comment: "Title for the cancel button"
                ),
                style: .cancel
            )
        )
        alert.addAction(
            UIAlertAction(
                title: String(
                    localized: "common.delete",
                    defaultValue: "Delete",
                    comment: "Title for the destructive delete button"
                ),
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
