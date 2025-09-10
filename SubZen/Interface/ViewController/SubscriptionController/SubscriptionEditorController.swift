//
//  SubscriptionEditorController.swift
//  SubZen
//
//  Created by Star on 2025/7/20.
//

import SnapKit
import UIKit

class SubscriptionEditorController: UIViewController {
    private let cycles = BillingCycle.allCases
    private let editSubscriptionView = EditSubscriptionView()
    private let subscriptionManager = SubscriptionManager.shared
    private let editSubscription: Subscription?

    init(subscription: Subscription? = nil) {
        editSubscription = subscription
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        view.addSubview(editSubscriptionView)
        editSubscriptionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        if let usedSubscription = editSubscription {
            editSubscriptionView.nameTextField.text = usedSubscription.name
            editSubscriptionView.priceTextField.text = NSDecimalNumber(decimal: usedSubscription.price).stringValue
            editSubscriptionView.datePicker.date = usedSubscription.lastBillingDate
            editSubscriptionView.cycleSegmentedControl.selectedSegmentIndex = cycles.firstIndex(of: usedSubscription.cycle) ?? 2
        }
        editSubscriptionView.onSaveTapped = { [weak self] in
            self?.handleSave()
        }
    }

    private func selectedCycle() -> BillingCycle {
        let ix = editSubscriptionView.cycleSegmentedControl.selectedSegmentIndex
        return (0 ..< cycles.count).contains(ix) ? cycles[ix] : .monthly
    }

    private func handleSave() {
        let cycle = selectedCycle()
        view.endEditing(true)

        let name = (editSubscriptionView.nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let date = editSubscriptionView.datePicker.date

        guard !name.isEmpty else {
            showAlert("Please enter a valid name.")
            return
        }
        guard let price = parsePrice(editSubscriptionView.priceTextField.text) else {
            showAlert("Please enter a valid price.")
            return
        }

        do {
            if let editing = editSubscription {
                subscriptionManager.subscriptionEdit(identifier: editing.id) { usedSubscription in
                    usedSubscription.name = name
                    usedSubscription.price = price
                    usedSubscription.lastBillingDate = date
                    usedSubscription.cycle = cycle
                }
            } else {
                _ = try subscriptionManager.createSubscription(name: name, price: price, cycle: cycle, lastBillingDate: date, currencyCode: "USD")
            }
            dismiss(animated: true)
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    private func parsePrice(_ text: String?) -> Decimal? {
        guard let text, !text.isEmpty else {
            return nil
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        if let number = formatter.number(from: text) { return number.decimalValue }
        return Decimal(string: text)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
