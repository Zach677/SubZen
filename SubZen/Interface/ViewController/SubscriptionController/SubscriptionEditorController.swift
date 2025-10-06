//
//  SubscriptionEditorController.swift
//  SubZen
//
//  Created by Star on 2025/7/20.
//

import SnapKit
import UIKit
import UserNotifications

class SubscriptionEditorController: UIViewController {
    private let cycles = BillingCycle.allCases
    private let editSubscriptionView = EditSubscriptionView()
    private let subscriptionManager = SubscriptionManager.shared
    private let editSubscription: Subscription?
    private let notificationPermissionService: NotificationPermissionService
    private var selectedCurrency: Currency

    init(
        subscription: Subscription? = nil,
        notificationPermissionService: NotificationPermissionService = .shared
    ) {
        self.notificationPermissionService = notificationPermissionService
        editSubscription = subscription
        if let subscription,
           let currency = CurrencyList.getCurrency(byCode: subscription.currencyCode)
        {
            selectedCurrency = currency
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
            editSubscriptionView.setReminderIntervals(usedSubscription.reminderIntervals)
        }
        editSubscriptionView.updateSelectedCurrencyDisplay(with: selectedCurrency)
        editSubscriptionView.onSaveTapped = { [weak self] in
            self?.handleSave()
        }
        editSubscriptionView.onCurrencyTapped = { [weak self] in
            self?.presentCurrencyPicker()
        }
        editSubscriptionView.onReminderSelectionChanged = { [weak self] interval in
            self?.handleReminderSelectionChanged(interval)
        }
        editSubscriptionView.onReminderWarningTapped = { [weak self] in
            self?.handleReminderWarningTapped()
        }

        updateReminderPermissionWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notificationPermissionService.checkCurrentPermissionStatus()

        Task { [weak self] in
            await Task.yield()
            await MainActor.run {
                self?.updateReminderPermissionWarning()
            }
        }
    }

    private func selectedCycle() -> BillingCycle {
        let ix = editSubscriptionView.cycleSegmentedControl.selectedSegmentIndex
        return (0 ..< cycles.count).contains(ix) ? cycles[ix] : .monthly
    }

    private func handleSave() {
        Task { [weak self] in
            await self?.performSave()
        }
    }

    @MainActor
    private func performSave() async {
        let cycle = selectedCycle()
        view.endEditing(true)

        let name = (editSubscriptionView.nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let date = editSubscriptionView.datePicker.date

        guard !name.isEmpty else {
            showAlert(
                String(localized: "Please enter a valid name.")
            )
            return
        }
        guard let price = parsePrice(editSubscriptionView.priceTextField.text) else {
            showAlert(
                String(localized: "Please enter a valid price.")
            )
            return
        }

        let reminderIntervals = editSubscriptionView.getReminderIntervals()

        if !reminderIntervals.isEmpty, notificationPermissionService.shouldRequestPermission() {
            await notificationPermissionService.requestNotificationPermission()
            updateReminderPermissionWarning()
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
                    usedSubscription.reminderIntervals = reminderIntervals
                }
            } else {
                _ = try subscriptionManager.createSubscription(
                    name: name,
                    price: price,
                    cycle: cycle,
                    lastBillingDate: date,
                    currencyCode: selectedCurrency.code,
                    reminderIntervals: reminderIntervals
                )
            }
            dismiss(animated: true)
        } catch {
            showAlert(error.localizedDescription)
        }

        updateReminderPermissionWarning()
    }

    @MainActor
    private func handleReminderSelectionChanged(_ interval: Int?) {
        updateReminderPermissionWarning()

        guard interval != nil else { return }
        guard notificationPermissionService.shouldRequestPermission() else { return }

        Task { [notificationPermissionService, weak self] in
            await notificationPermissionService.requestNotificationPermission()
            await MainActor.run {
                self?.updateReminderPermissionWarning()
            }
        }
    }

    @MainActor
    private func updateReminderPermissionWarning() {
        let allowedStatuses: Set<UNAuthorizationStatus> = [.authorized, .provisional, .ephemeral]
        let hasReminderSelection = !editSubscriptionView.getReminderIntervals().isEmpty
        let isAuthorized = allowedStatuses.contains(notificationPermissionService.permissionStatus)
        let shouldShowWarning = hasReminderSelection && notificationPermissionService.hasRequestedPermission && !isAuthorized

        if shouldShowWarning {
            let message: String
            switch notificationPermissionService.permissionStatus {
            case .denied:
                message = String(localized: "Notifications are turned off. Tap to open notification settings.")
            case .notDetermined:
                message = String(localized: "Enable notifications to receive reminders. Tap to open notification settings.")
            default:
                message = String(localized: "Enable notifications to receive reminders. Tap to open notification settings.")
            }
            editSubscriptionView.setReminderPermissionWarningMessage(message)
        }

        editSubscriptionView.setReminderPermissionWarningVisible(shouldShowWarning)
    }

    @MainActor
    private func handleReminderWarningTapped() {
        let application = UIApplication.shared

        if let notificationURL = URL(string: UIApplication.openNotificationSettingsURLString),
           application.canOpenURL(notificationURL)
        {
            application.open(notificationURL, options: [:]) { [weak self] success in
                guard !success else { return }
                self?.openAppSettingsFallback(using: application)
            }
            return
        }

        openAppSettingsFallback(using: application)
    }

    @MainActor
    private func openAppSettingsFallback(using application: UIApplication) {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString), application.canOpenURL(settingsURL) else {
            presentSettingsUnavailableAlert()
            return
        }

        application.open(settingsURL, options: [:]) { [weak self] success in
            guard !success else { return }
            self?.presentSettingsUnavailableAlert()
        }
    }

    @MainActor
    private func presentSettingsUnavailableAlert() {
        let alert = UIAlertController(
            title: String(localized: "Settings Unavailable"),
            message: String(localized: "Open Settings manually to enable notifications for SubZen."),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: String(localized: "OK"),
                style: .default
            )
        )
        present(alert, animated: true)
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
        let alert = UIAlertController(
            title: String(localized: "Error"),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: String(localized: "OK"),
                style: .default
            )
        )
        present(alert, animated: true)
    }
}
