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

    func presentSubscriptionEditor(for _: Subscription? = nil) {
        let editorController = SubscriptionEditorController()
        // editorController.delegate = self
        
        present(editorController, animated: true)
    }

    func deleteSubscription(_ subscription: Subscription) {
        let alert = UIAlertController(
            title: "Delete Subscription",
            message: "Are you sure you want to delete \(subscription.name)?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDeleteSubscription(subscription)
        })

        present(alert, animated: true)
    }

    private func performDeleteSubscription(_ subscription: Subscription) {
        subscriptionManager.deleteSubscription(identifier: subscription.id)
        loadSubscriptions()
    }
}

// extension SubscriptionController: SubscriptionEditorDelegate {
// 		func subscriptionEditor(_ editor: SubscriptionEditorController, didSaveSubscription subscription: Subscription) {
// 				loadSubscriptions()
// 		}
//
// 		func subscriptionEditor(_ editor: SubscriptionEditorController, didUpdateSubscription subscription: Subscription) {
// 				loadSubscriptions()
// 		}
// }
