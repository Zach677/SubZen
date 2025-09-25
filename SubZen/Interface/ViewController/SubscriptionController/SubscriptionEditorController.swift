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
    private var selectedCurrency: Currency

    init(subscription: Subscription? = nil) {
        editSubscription = subscription
        if let subscription,
           let currency = CurrencyList.getCurrency(byCode: subscription.currencyCode)
        {
            selectedCurrency = currency
        } else if let baseCurrency = CurrencyList.getCurrency(byCode: CurrencyTotalService.shared.baseCurrency) {
            selectedCurrency = baseCurrency
        } else if let fallback = CurrencyList.allCurrencies.first {
            selectedCurrency = fallback
        } else {
            selectedCurrency = Currency(code: "USD", numeric: "840", name: "US Dollar", symbol: "$", decimalDigits: 2)
        }
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
        editSubscriptionView.updateSelectedCurrencyDisplay(with: selectedCurrency)
        editSubscriptionView.onSaveTapped = { [weak self] in
            self?.handleSave()
        }
        editSubscriptionView.onCurrencyTapped = { [weak self] in
            self?.presentCurrencyPicker()
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
                subscriptionManager.subscriptionEdit(identifier: editing.id) { [weak self] usedSubscription in
                    guard let self else { return }
                    usedSubscription.name = name
                    usedSubscription.price = price
                    usedSubscription.lastBillingDate = date
                    usedSubscription.cycle = cycle
                    usedSubscription.currencyCode = selectedCurrency.code
                }
            } else {
                _ = try subscriptionManager.createSubscription(
                    name: name,
                    price: price,
                    cycle: cycle,
                    lastBillingDate: date,
                    currencyCode: selectedCurrency.code
                )
            }
            dismiss(animated: true)
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    private func presentCurrencyPicker() {
        let picker = CurrencyPickerController(currencies: CurrencyList.allCurrencies, selectedCode: selectedCurrency.code)
        picker.onSelectCurrency = { [weak self] currency in
            self?.selectedCurrency = currency
            self?.editSubscriptionView.updateSelectedCurrencyDisplay(with: currency)
        }

        let navigationController = UINavigationController(rootViewController: picker)
        navigationController.modalPresentationStyle = .pageSheet

        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }

        present(navigationController, animated: true)
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
