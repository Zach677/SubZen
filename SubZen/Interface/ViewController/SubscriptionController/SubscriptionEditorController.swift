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
    private let editSubscriptionView = EditSubscriptionView()
    private let subscriptionManager = SubscriptionManager.shared
    private let editSubscription: Subscription?
    private let notificationPermissionService: NotificationPermissionService
    private let reminderPermissionPresenter: ReminderPermissionPresenter
    private let defaultCurrencyProvider: DefaultCurrencyProviding
    private var selectedCurrency: Currency
    private var selectedCycle: BillingCycle = .monthly

    init(
        subscription: Subscription? = nil,
        notificationPermissionService: NotificationPermissionService = .shared,
        reminderPermissionPresenter: ReminderPermissionPresenter? = nil,
        defaultCurrencyProvider: DefaultCurrencyProviding = DefaultCurrencyProvider()
    ) {
        self.notificationPermissionService = notificationPermissionService
        self.reminderPermissionPresenter = reminderPermissionPresenter ?? ReminderPermissionPresenter(notificationPermissionService: notificationPermissionService)
        editSubscription = subscription
        self.defaultCurrencyProvider = defaultCurrencyProvider
        selectedCurrency = subscription
            .flatMap { CurrencyList.currency(for: $0.currencyCode) }
            ?? defaultCurrencyProvider.loadDefaultCurrency()
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

        if let existingSubscription = editSubscription {
            editSubscriptionView.nameTextField.text = existingSubscription.name
            editSubscriptionView.priceTextField.text = NSDecimalNumber(decimal: existingSubscription.price).stringValue
            editSubscriptionView.datePicker.date = existingSubscription.lastBillingDate
            editSubscriptionView.setReminderIntervals(existingSubscription.reminderIntervals)

            selectedCycle = existingSubscription.cycle
            configureUIForCycle(existingSubscription.cycle, animated: false)
        } else {
            // Default to monthly for new subscription
            selectedCycle = .monthly
            editSubscriptionView.cycleSegmentedControl.selectedSegmentIndex = 1
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
        editSubscriptionView.onReminderBannerTapped = { [weak self] in
            self?.handleReminderBannerTapped()
        }
        editSubscriptionView.onCycleSegmentChanged = { [weak self] index in
            self?.handleCycleSegmentChanged(index)
        }
        editSubscriptionView.onCustomCycleChanged = { [weak self] value, unit in
            self?.handleCustomCycleChanged(value: value, unit: unit)
        }
        editSubscriptionView.onDateTapped = { [weak self] in
            self?.handleDateTapped()
        }

        updateLastBillingDisplay()
        updateNextBillingHint()
        updateReminderPermissionBanner()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notificationPermissionService.checkCurrentPermissionStatus()

        Task { [weak self] in
            await Task.yield()
            await MainActor.run {
                self?.updateReminderPermissionBanner()
            }
        }
    }

    private func configureUIForCycle(_ cycle: BillingCycle, animated: Bool) {
        let presets = BillingCycle.presetCases
        if let index = presets.firstIndex(of: cycle) {
            editSubscriptionView.cycleSegmentedControl.selectedSegmentIndex = index
            editSubscriptionView.setCustomPickerVisible(false, animated: animated)
        } else if case let .custom(value, unit) = cycle {
            editSubscriptionView.cycleSegmentedControl.selectedSegmentIndex = presets.count // Custom segment
            editSubscriptionView.customCyclePickerView.configure(value: value, unit: unit)
            editSubscriptionView.setCustomPickerVisible(true, animated: animated)
        }
    }

    private func handleCycleSegmentChanged(_ index: Int) {
        let presets = BillingCycle.presetCases
        if index < presets.count {
            selectedCycle = presets[index]
            editSubscriptionView.setCustomPickerVisible(false, animated: true)
        } else {
            // Custom selected - use current picker values
            let (value, unit) = editSubscriptionView.customCyclePickerView.currentSelection()
            selectedCycle = .custom(value: value, unit: unit)
            editSubscriptionView.setCustomPickerVisible(true, animated: true)
        }
        updateNextBillingHint()
    }

    private func handleCustomCycleChanged(value: Int, unit: CycleUnit) {
        selectedCycle = .custom(value: value, unit: unit)
        updateNextBillingHint()
    }

    private func handleSave() {
        Task { [weak self] in
            await self?.performSave()
        }
    }

    @MainActor
    private func performSave() async {
        let cycle = selectedCycle
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

        let reminderIntervals = editSubscriptionView.selectedReminderIntervals()

        if reminderPermissionPresenter.shouldRequestPermissionOnSelectionChange(hasReminderSelection: !reminderIntervals.isEmpty) {
            await notificationPermissionService.requestNotificationPermission()
        }

        do {
            if let editing = editSubscription {
                subscriptionManager.subscriptionEdit(identifier: editing.id) { [weak self] editingSubscription in
                    guard let self else { return }
                    editingSubscription.name = name
                    editingSubscription.price = price
                    editingSubscription.lastBillingDate = date
                    editingSubscription.cycle = cycle
                    editingSubscription.currencyCode = selectedCurrency.code
                    editingSubscription.reminderIntervals = reminderIntervals
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

        updateReminderPermissionBanner()
    }

    @MainActor
    private func handleReminderSelectionChanged(_ interval: Int?) {
        let hasSelection = interval != nil
        updateReminderPermissionBanner()

        guard reminderPermissionPresenter.shouldRequestPermissionOnSelectionChange(hasReminderSelection: hasSelection) else { return }

        Task { [notificationPermissionService, weak self] in
            await notificationPermissionService.requestNotificationPermission()
            await MainActor.run {
                self?.updateReminderPermissionBanner()
            }
        }
    }

    @MainActor
    private func updateReminderPermissionBanner() {
        let hasReminderSelection = !editSubscriptionView.selectedReminderIntervals().isEmpty
        let viewState = reminderPermissionPresenter.makeViewState(hasReminderSelection: hasReminderSelection)
        editSubscriptionView.updateReminderPermissionBanner(
            isVisible: viewState.isBannerVisible,
            message: viewState.message
        )
    }

    @MainActor
    private func handleReminderBannerTapped() {
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

    @objc private func datePickerChanged() {
        updateLastBillingDisplay()
        updateNextBillingHint()
    }

    private func updateLastBillingDisplay() {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let dateString = formatter.string(from: editSubscriptionView.datePicker.date)
        editSubscriptionView.updateLastBillingDisplay(dateString: dateString)
    }

    private func updateNextBillingHint() {
        let lastDate = editSubscriptionView.datePicker.date
        let cycle = selectedCycle

        // Calculate next billing date
        let calendar = Calendar.current
        var nextDate = lastDate

        // Start from last billing date and find next future billing date
        while nextDate <= Date() {
            guard let next = calendar.date(
                byAdding: cycle.calendarComponent,
                value: cycle.calendarValue,
                to: nextDate
            ) else { break }
            nextDate = next
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let dateString = formatter.string(from: nextDate)

        let fullText = String(localized: "Next billing date will be on \(dateString)")
        let range = (fullText as NSString).range(of: dateString)

        editSubscriptionView.updateNextBillingHint(hint: fullText, highlightRange: range)
    }

    private func handleDateTapped() {
        let pickerController = UIViewController()
        pickerController.view.backgroundColor = .systemBackground

        let picker = UIDatePicker().with {
            $0.datePickerMode = .date
            $0.preferredDatePickerStyle = .inline
            $0.date = editSubscriptionView.datePicker.date
            $0.maximumDate = Date()
        }

        pickerController.view.addSubview(picker)
        picker.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }

        picker.addTarget(self, action: #selector(inlineDatePickerChanged(_:)), for: .valueChanged)

        if let sheet = pickerController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(pickerController, animated: true)
    }

    @objc private func inlineDatePickerChanged(_ sender: UIDatePicker) {
        editSubscriptionView.datePicker.date = sender.date
        datePickerChanged()
    }
}
