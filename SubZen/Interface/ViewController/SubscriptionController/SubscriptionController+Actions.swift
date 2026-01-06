//
//  SubscriptionController+Actions.swift
//  SubZen
//
//  Created by Star on 2025/7/15.
//

import UIKit

extension SubscriptionController {
    @objc func addSubscriptionTapped() {
        presentSubscriptionEditor(preferLifetimeForNewSubscription: currentFilter == .lifetime)
    }

    func presentSubscriptionEditor(
        for subscription: Subscription? = nil,
        preferLifetimeForNewSubscription: Bool = false
    ) {
        let editorController = SubscriptionEditorController(
            subscription: subscription,
            preferLifetimeForNewSubscription: preferLifetimeForNewSubscription
        )
        navigationController?.pushViewController(editorController, animated: true)
    }

    func deleteSubscription(_ subscription: Subscription) {
        let messageKey: String.LocalizationValue = "Are you sure you want to delete \(subscription.name)?"
        let alert = UIAlertController(
            title: String(localized: "Delete Subscription"),
            message: String(localized: messageKey),
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
