//
//  SubscriptionEditorController.swift
//  SubZen
//
//  Created by Star on 2025/7/20.
//

import PhotosUI
import SnapKit
import UniformTypeIdentifiers
import UIKit
import UserNotifications

class SubscriptionEditorController: UIViewController {
    private let editSubscriptionView = EditSubscriptionView()
    private let subscriptionManager = SubscriptionManager.shared
    private let editSubscription: Subscription?
    private let iconStore: SubscriptionIconStore
    private let iconRemoteService: SubscriptionIconRemoteService
    private let notificationPermissionService: NotificationPermissionService
    private let reminderPermissionPresenter: ReminderPermissionPresenter
    private let defaultCurrencyProvider: DefaultCurrencyProviding
    private let preferLifetimeForNewSubscription: Bool
    private var selectedCurrency: Currency
    private var selectedCycle: BillingCycle = .monthly
    private var selectedTrialPeriod: TrialPeriod?
    private var selectedEndDate: Date?
    private var isLifetimeSelected = false
    private var pendingIconImage: UIImage?

    init(
        subscription: Subscription? = nil,
        preferLifetimeForNewSubscription: Bool = false,
        iconStore: SubscriptionIconStore = SubscriptionIconStore(),
        iconRemoteService: SubscriptionIconRemoteService = SubscriptionIconRemoteService(),
        notificationPermissionService: NotificationPermissionService = .shared,
        reminderPermissionPresenter: ReminderPermissionPresenter? = nil,
        defaultCurrencyProvider: DefaultCurrencyProviding = DefaultCurrencyProvider()
    ) {
        self.iconStore = iconStore
        self.iconRemoteService = iconRemoteService
        self.notificationPermissionService = notificationPermissionService
        self.reminderPermissionPresenter = reminderPermissionPresenter ?? ReminderPermissionPresenter(notificationPermissionService: notificationPermissionService)
        editSubscription = subscription
        self.defaultCurrencyProvider = defaultCurrencyProvider
        self.preferLifetimeForNewSubscription = preferLifetimeForNewSubscription
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
            selectedEndDate = existingSubscription.endDate

            isLifetimeSelected = existingSubscription.isLifetime
            editSubscriptionView.billingTypeSegmentedControl.selectedSegmentIndex = isLifetimeSelected ? 1 : 0
            editSubscriptionView.setLifetimeModeEnabled(isLifetimeSelected, animated: false)

            if isLifetimeSelected {
                selectedEndDate = nil
            }

            if isLifetimeSelected {
                selectedCycle = .monthly
                editSubscriptionView.cycleSegmentedControl.selectedSegmentIndex = 1
                editSubscriptionView.setCustomPickerVisible(false, animated: false)
            } else {
                selectedCycle = existingSubscription.cycle
                configureUIForCycle(existingSubscription.cycle, animated: false)
            }

            selectedTrialPeriod = existingSubscription.trialPeriod
            if isLifetimeSelected {
                selectedTrialPeriod = nil
                editSubscriptionView.trialSegmentedControl.selectedSegmentIndex = 0
                editSubscriptionView.setCustomTrialPickerVisible(false, animated: false)
            } else {
                configureUIForTrial(existingSubscription.trialPeriod, animated: false)
            }
        } else {
            isLifetimeSelected = preferLifetimeForNewSubscription
            editSubscriptionView.billingTypeSegmentedControl.selectedSegmentIndex = isLifetimeSelected ? 1 : 0
            editSubscriptionView.setLifetimeModeEnabled(isLifetimeSelected, animated: false)

            // Default to monthly for new subscription
            selectedCycle = .monthly
            editSubscriptionView.cycleSegmentedControl.selectedSegmentIndex = 1

            selectedTrialPeriod = nil
            editSubscriptionView.trialSegmentedControl.selectedSegmentIndex = 0
            selectedEndDate = nil
        }

        let isEndDateEnabled = selectedEndDate != nil
        editSubscriptionView.endDateSwitch.isOn = isEndDateEnabled
        editSubscriptionView.setEndDateSelectionVisible(isEndDateEnabled, animated: false)
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
        editSubscriptionView.onBillingTypeSegmentChanged = { [weak self] index in
            self?.handleBillingTypeSegmentChanged(index)
        }
        editSubscriptionView.onCycleSegmentChanged = { [weak self] index in
            self?.handleCycleSegmentChanged(index)
        }
        editSubscriptionView.onCustomCycleChanged = { [weak self] value, unit in
            self?.handleCustomCycleChanged(value: value, unit: unit)
        }
        editSubscriptionView.onTrialSegmentChanged = { [weak self] index in
            self?.handleTrialSegmentChanged(index)
        }
        editSubscriptionView.onCustomTrialChanged = { [weak self] value, unit in
            self?.handleCustomTrialChanged(value: value, unit: unit)
        }
        editSubscriptionView.onDateTapped = { [weak self] in
            self?.handleDateTapped()
        }
        editSubscriptionView.onEndDateTapped = { [weak self] in
            self?.handleEndDateTapped()
        }
        editSubscriptionView.onEndDateSwitchChanged = { [weak self] isEnabled in
            self?.handleEndDateSwitchChanged(isEnabled)
        }

        title = editSubscription == nil ? String(localized: "New Subscription") : String(localized: "Edit Subscription")
        navigationItem.backButtonTitle = "<"

        updateIconMenu()
        loadExistingIconIfNeeded()
        updateLastBillingDisplay()
        updateTrialHint()
        updateNextBillingHint()
        updateReminderPermissionBanner()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Disable navigation bar animations to avoid layout update conflicts.
        navigationController?.setNavigationBarHidden(false, animated: false)
        notificationPermissionService.checkCurrentPermissionStatus()

        Task { [weak self] in
            await Task.yield()
            await MainActor.run {
                self?.updateReminderPermissionBanner()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only hide if we are popping back to the root (SubscriptionController)
        if isMovingFromParent || navigationController?.isBeingDismissed == true {
            navigationController?.setNavigationBarHidden(true, animated: animated)
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

    private func configureUIForTrial(_ trialPeriod: TrialPeriod?, animated: Bool) {
        let presets = TrialPeriod.presetCases

        guard let trialPeriod else {
            editSubscriptionView.trialSegmentedControl.selectedSegmentIndex = 0
            editSubscriptionView.setCustomTrialPickerVisible(false, animated: animated)
            return
        }

        if let index = presets.firstIndex(of: trialPeriod) {
            editSubscriptionView.trialSegmentedControl.selectedSegmentIndex = index + 1
            editSubscriptionView.setCustomTrialPickerVisible(false, animated: animated)
        } else {
            editSubscriptionView.trialSegmentedControl.selectedSegmentIndex = presets.count + 1 // Custom segment
            editSubscriptionView.customTrialPickerView.configure(value: trialPeriod.value, unit: trialPeriod.unit)
            editSubscriptionView.setCustomTrialPickerVisible(true, animated: animated)
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

    private func handleTrialSegmentChanged(_ index: Int) {
        let presets = TrialPeriod.presetCases

        if index == 0 {
            selectedTrialPeriod = nil
            editSubscriptionView.setCustomTrialPickerVisible(false, animated: true)
        } else if index <= presets.count {
            selectedTrialPeriod = presets[index - 1]
            editSubscriptionView.setCustomTrialPickerVisible(false, animated: true)
        } else {
            // Custom selected - use current picker values
            let (value, unit) = editSubscriptionView.customTrialPickerView.currentSelection()
            selectedTrialPeriod = TrialPeriod(value: value, unit: unit)
            editSubscriptionView.setCustomTrialPickerVisible(true, animated: true)
        }

        updateTrialHint()
        updateNextBillingHint()
    }

    private func handleCustomTrialChanged(value: Int, unit: CycleUnit) {
        selectedTrialPeriod = TrialPeriod(value: value, unit: unit)
        updateTrialHint()
        updateNextBillingHint()
    }

    private func handleBillingTypeSegmentChanged(_ index: Int) {
        isLifetimeSelected = index == 1
        editSubscriptionView.setLifetimeModeEnabled(isLifetimeSelected, animated: true)
        if isLifetimeSelected {
            selectedEndDate = nil
            editSubscriptionView.endDateSwitch.isOn = false
            editSubscriptionView.setEndDateSelectionVisible(false, animated: true)
        }
        updateTrialHint()
        updateNextBillingHint()
        updateReminderPermissionBanner()
    }

    private func handleEndDateSwitchChanged(_ isEnabled: Bool) {
        guard !isLifetimeSelected else {
            editSubscriptionView.endDateSwitch.isOn = false
            editSubscriptionView.setEndDateSelectionVisible(false, animated: true)
            selectedEndDate = nil
            updateNextBillingHint()
            return
        }

        if isEnabled {
            if selectedEndDate == nil {
                let lastDate = editSubscriptionView.datePicker.date
                selectedEndDate = calculateNextBillingBoundaryDate(lastBillingDate: lastDate)
            }
        } else {
            selectedEndDate = nil
        }

        editSubscriptionView.setEndDateSelectionVisible(isEnabled, animated: true)
        updateNextBillingHint()
    }

    private func handleSave() {
        Task { [weak self] in
            await self?.performSave()
        }
    }

    @MainActor
    private func performSave() async {
        let cycle: BillingCycle = isLifetimeSelected ? .lifetime : selectedCycle
        let trialPeriod: TrialPeriod? = isLifetimeSelected ? nil : selectedTrialPeriod
        if isLifetimeSelected {
            selectedEndDate = nil
        }
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

        let reminderIntervals = isLifetimeSelected ? [] : editSubscriptionView.selectedReminderIntervals()
        clampSelectedEndDateIfNeeded()
        let endDate = isLifetimeSelected ? nil : selectedEndDate

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
                    editingSubscription.trialPeriod = trialPeriod
                    editingSubscription.endDate = endDate
                    editingSubscription.currencyCode = selectedCurrency.code
                    editingSubscription.reminderIntervals = reminderIntervals
                }
            } else {
                let created = try subscriptionManager.createSubscription(
                    name: name,
                    price: price,
                    cycle: cycle,
                    lastBillingDate: date,
                    endDate: endDate,
                    trialPeriod: trialPeriod,
                    currencyCode: selectedCurrency.code,
                    reminderIntervals: reminderIntervals
                )

                if let pendingIconImage {
                    try? await iconStore.saveIcon(pendingIconImage, for: created.id)
                }
            }
            navigationController?.popViewController(animated: true)
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
        guard !isLifetimeSelected else {
            editSubscriptionView.updateReminderPermissionBanner(isVisible: false, message: nil)
            return
        }

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
        updateTrialHint()
        updateNextBillingHint()
    }

    private func updateLastBillingDisplay() {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let dateString = formatter.string(from: editSubscriptionView.datePicker.date)
        editSubscriptionView.updateLastBillingDisplay(dateString: dateString)
    }

    private func updateEndDateDisplay() {
        guard let endDate = selectedEndDate else {
            editSubscriptionView.updateEndDateDisplay(dateString: nil)
            return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let dateString = formatter.string(from: endDate)
        editSubscriptionView.updateEndDateDisplay(dateString: dateString)
    }

    private func clampSelectedEndDateIfNeeded() {
        guard !isLifetimeSelected else {
            selectedEndDate = nil
            updateEndDateDisplay()
            return
        }

        guard let selectedEndDate else {
            updateEndDateDisplay()
            return
        }

        let lastDate = editSubscriptionView.datePicker.date
        var clampedDate = selectedEndDate
        if clampedDate < lastDate {
            clampedDate = lastDate
        }

        self.selectedEndDate = clampedDate
        updateEndDateDisplay()
    }

    private func calculateNextBillingBoundaryDate(lastBillingDate: Date) -> Date {
        let cycle = selectedCycle

        let calendar = Calendar.current
        let now = Date()
        var nextDate: Date = if let trialPeriod = selectedTrialPeriod,
                                let trialEnd = trialPeriod.endDate(from: lastBillingDate, calendar: calendar)
        {
            trialEnd
        } else {
            calendar.date(
                byAdding: cycle.calendarComponent,
                value: cycle.calendarValue,
                to: lastBillingDate
            ) ?? lastBillingDate
        }

        while !calendar.isDate(nextDate, inSameDayAs: now), nextDate < now {
            guard let next = calendar.date(
                byAdding: cycle.calendarComponent,
                value: cycle.calendarValue,
                to: nextDate
            ) else { break }
            nextDate = next
        }

        return nextDate
    }

    private func updateTrialHint() {
        guard !isLifetimeSelected else {
            editSubscriptionView.updateTrialHint(hint: nil, highlightRange: nil)
            return
        }

        guard let trialPeriod = selectedTrialPeriod,
              let trialEnd = trialPeriod.endDate(from: editSubscriptionView.datePicker.date)
        else {
            editSubscriptionView.updateTrialHint(hint: nil, highlightRange: nil)
            return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let dateString = formatter.string(from: trialEnd)

        let fullTextKey: String.LocalizationValue = "Trial ends on \(dateString)"
        let fullText = String(localized: fullTextKey)
        let range = (fullText as NSString).range(of: dateString)

        editSubscriptionView.updateTrialHint(hint: fullText, highlightRange: range)
    }

    private func updateNextBillingHint() {
        guard !isLifetimeSelected else {
            editSubscriptionView.updateNextBillingHint(hint: "", highlightRange: nil)
            return
        }

        let lastDate = editSubscriptionView.datePicker.date
        let nextDate = calculateNextBillingBoundaryDate(lastBillingDate: lastDate)
        clampSelectedEndDateIfNeeded()

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let dateString = formatter.string(from: selectedEndDate ?? nextDate)

        let fullTextKey: String.LocalizationValue = if selectedEndDate == nil {
            "Next billing date will be on \(dateString)"
        } else {
            "Subscription ends on \(dateString)"
        }
        let fullText = String(localized: fullTextKey)
        let range = (fullText as NSString).range(of: dateString)

        editSubscriptionView.updateNextBillingHint(hint: fullText, highlightRange: range)
    }

    private func handleEndDateTapped() {
        guard !isLifetimeSelected else { return }

        let lastDate = editSubscriptionView.datePicker.date
        let suggestedDate = calculateNextBillingBoundaryDate(lastBillingDate: lastDate)

        let pickerController = UIViewController()
        pickerController.view.backgroundColor = .systemBackground

        let picker = UIDatePicker().with {
            $0.datePickerMode = .date
            $0.preferredDatePickerStyle = .inline
            $0.minimumDate = lastDate
            $0.date = selectedEndDate ?? suggestedDate
        }

        let removeButton = UIButton(type: .system).with {
            $0.setTitle(String(localized: "Remove End Date"), for: .normal)
            $0.setTitleColor(.systemRed, for: .normal)
            $0.isHidden = selectedEndDate == nil
        }

        removeButton.addAction(
            UIAction { [weak self, weak pickerController] _ in
                guard let self else { return }
                self.selectedEndDate = nil
                self.editSubscriptionView.endDateSwitch.isOn = false
                self.editSubscriptionView.setEndDateSelectionVisible(false, animated: true)
                self.updateNextBillingHint()
                pickerController?.dismiss(animated: true)
            },
            for: .touchUpInside
        )

        let stackView = UIStackView(arrangedSubviews: [picker, removeButton]).with {
            $0.axis = .vertical
            $0.spacing = 12
            $0.alignment = .fill
        }

        pickerController.view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }

        picker.addTarget(self, action: #selector(inlineEndDatePickerChanged(_:)), for: .valueChanged)

        if let sheet = pickerController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(pickerController, animated: true)
    }

    @objc private func inlineEndDatePickerChanged(_ sender: UIDatePicker) {
        if !editSubscriptionView.endDateSwitch.isOn {
            editSubscriptionView.endDateSwitch.isOn = true
            editSubscriptionView.setEndDateSelectionVisible(true, animated: false)
        }
        selectedEndDate = sender.date
        updateEndDateDisplay()
        updateNextBillingHint()
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

// MARK: - Icon Actions

extension SubscriptionEditorController {
    private enum IconPickerConstants {
        static let previewSize: CGFloat = 256
    }

    @MainActor
    private func loadExistingIconIfNeeded() {
        guard let editSubscription else {
            editSubscriptionView.updateIconPreview(image: pendingIconImage)
            return
        }

        Task { [weak self] in
            guard let self else { return }
            let image = await iconStore.icon(for: editSubscription.id)
            await MainActor.run { [weak self] in
                self?.editSubscriptionView.updateIconPreview(image: image)
            }
        }
    }

    @MainActor
    private func updateIconMenu() {
        let chooseFromPhotosAction = UIAction(
            title: String(localized: "Choose from Photos"),
            image: UIImage(systemName: "photo")
        ) { [weak self] _ in
            self?.presentPhotoPicker()
        }

        let chooseFromFilesAction = UIAction(
            title: String(localized: "Choose from Files"),
            image: UIImage(systemName: "folder")
        ) { [weak self] _ in
            self?.presentIconFilePicker()
        }

        let fetchAppStoreIconAction = UIAction(
            title: String(localized: "Fetch App Store Icon"),
            image: UIImage(systemName: "apple.logo")
        ) { [weak self] _ in
            self?.presentAppStoreIconSearch()
        }

        let getIconFromURLAction = UIAction(
            title: String(localized: "Get Icon from URL"),
            image: UIImage(systemName: "link")
        ) { [weak self] _ in
            self?.presentIconURLPrompt()
        }

        var actions: [UIAction] = [
            chooseFromPhotosAction,
            chooseFromFilesAction,
            fetchAppStoreIconAction,
            getIconFromURLAction,
        ]

        if hasIconForCurrentContext() {
            let removeIconAction = UIAction(
                title: String(localized: "Remove Icon"),
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.removeCurrentIcon()
            }
            actions.append(removeIconAction)
        }

        editSubscriptionView.setIconMenu(
            UIMenu(
                title: String(localized: "App Icon"),
                children: actions
            )
        )
    }

    @MainActor
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @MainActor
    private func presentIconFilePicker() {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [UTType.image],
            asCopy: true
        )
        picker.allowsMultipleSelection = false
        picker.delegate = self
        present(picker, animated: true)
    }

    @MainActor
    private func presentAppStoreIconSearch() {
        let searchController = AppStoreIconSearchController(iconRemoteService: iconRemoteService)
        searchController.onSelectResult = { [weak self] result in
            guard let self else { return }
            guard let url = result.preferredArtworkURL else {
                self.showAlert(SubscriptionIconRemoteServiceError.appStoreArtworkMissing.localizedDescription)
                return
            }

            Task { [weak self] in
                await self?.fetchIcon(from: url)
            }
        }
        searchController.onSelectAppID = { [weak self] appID in
            Task { [weak self] in
                await self?.fetchAppStoreIcon(appID: appID)
            }
        }

        let navigationController = UINavigationController(rootViewController: searchController)
        navigationController.modalPresentationStyle = .pageSheet

        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }

        present(navigationController, animated: true)
    }

    @MainActor
    private func presentIconURLPrompt() {
        let alert = UIAlertController(
            title: String(localized: "Get Icon from URL"),
            message: String(localized: "Paste a website URL or an https image URL."),
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = String(localized: "https://example.com/icon.png")
            textField.keyboardType = .URL
            textField.textContentType = .URL
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }

        alert.addAction(
            UIAlertAction(
                title: String(localized: "Cancel"),
                style: .cancel
            )
        )
        alert.addAction(
            UIAlertAction(
                title: String(localized: "Fetch"),
                style: .default
            ) { [weak self, weak alert] _ in
                guard let self else { return }
                let text = alert?.textFields?.first?.text ?? ""
                Task { [weak self] in
                    await self?.fetchIcon(fromURLString: text)
                }
            }
        )

        present(alert, animated: true)
    }

    @MainActor
    private func hasIconForCurrentContext() -> Bool {
        if let editSubscription {
            return iconStore.iconExists(for: editSubscription.id)
        }
        return pendingIconImage != nil
    }

    @MainActor
    private func removeCurrentIcon() {
        if let editSubscription {
            do {
                try iconStore.removeIcon(for: editSubscription.id)
                editSubscriptionView.updateIconPreview(image: nil)
                updateIconMenu()
            } catch {
                showAlert(error.localizedDescription)
            }
            return
        }

        pendingIconImage = nil
        editSubscriptionView.updateIconPreview(image: nil)
        updateIconMenu()
    }

    @MainActor
    private func fetchIcon(fromURLString input: String) async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = normalizedIconURL(from: trimmed) else {
            showAlert(SubscriptionIconRemoteServiceError.invalidURL.localizedDescription)
            return
        }

        await fetchIcon(from: url)
    }

    private func normalizedIconURL(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), let scheme = url.scheme {
            if scheme.lowercased() == "http" {
                guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    return url
                }
                components.scheme = "https"
                return components.url
            }
            return url
        }

        if trimmed.hasPrefix("//") {
            return URL(string: "https:\(trimmed)")
        }

        return URL(string: "https://\(trimmed)")
    }

    @MainActor
    private func fetchIcon(from url: URL) async {
        editSubscriptionView.setIconLoading(true)
        defer { editSubscriptionView.setIconLoading(false) }

        do {
            let data = try await iconRemoteService.fetchIconData(from: url)
            try await applyIconData(data)
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    @MainActor
    private func fetchAppStoreIcon(appID: Int) async {
        editSubscriptionView.setIconLoading(true)
        defer { editSubscriptionView.setIconLoading(false) }

        do {
            let artworkURL = try await iconRemoteService.fetchAppStoreArtworkURL(appID: appID)
            let data = try await iconRemoteService.fetchImageData(from: artworkURL)
            try await applyIconData(data)
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    @MainActor
    private func applyIconData(_ data: Data) async throws {
        let previewImage = try await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: data) else {
                throw SubscriptionIconApplyError.invalidImageData
            }
            return image.normalizedSquareIcon(size: IconPickerConstants.previewSize)
        }.value

        try await applyIconPreviewImage(previewImage)
    }

    @MainActor
    private func applyIconImage(_ image: UIImage) async throws {
        let previewImage = await Task.detached(priority: .userInitiated) {
            image.normalizedSquareIcon(size: IconPickerConstants.previewSize)
        }.value

        try await applyIconPreviewImage(previewImage)
    }

    @MainActor
    private func applyIconPreviewImage(_ previewImage: UIImage) async throws {
        if let editSubscription {
            try await iconStore.saveIcon(previewImage, for: editSubscription.id)
            let saved = await iconStore.icon(for: editSubscription.id)
            editSubscriptionView.updateIconPreview(image: saved)
        } else {
            pendingIconImage = previewImage
            editSubscriptionView.updateIconPreview(image: previewImage)
        }

        updateIconMenu()
    }

    @MainActor
    private func importIcon(fromFileURL url: URL) async {
        editSubscriptionView.setIconLoading(true)
        defer { editSubscriptionView.setIconLoading(false) }

        do {
            let data = try await Task.detached(priority: .utility) {
                let needsAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if needsAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                return try Data(contentsOf: url)
            }.value

            try await applyIconData(data)
        } catch {
            showAlert(String(localized: "Failed to load the selected image."))
        }
    }
}

private enum SubscriptionIconApplyError: LocalizedError {
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            String(localized: "The downloaded data is not a valid image.")
        }
    }
}

// MARK: - Photo / File Picker

extension SubscriptionEditorController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let itemProvider = results.first?.itemProvider else { return }
        guard itemProvider.canLoadObject(ofClass: UIImage.self) else {
            showAlert(String(localized: "Failed to load the selected image."))
            return
        }

        editSubscriptionView.setIconLoading(true)
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            Task { @MainActor in
                guard let self else { return }
                self.editSubscriptionView.setIconLoading(false)

                guard let image = object as? UIImage else {
                    self.showAlert(String(localized: "Failed to load the selected image."))
                    return
                }

                do {
                    try await self.applyIconImage(image)
                } catch {
                    self.showAlert(error.localizedDescription)
                }
            }
        }
    }
}

extension SubscriptionEditorController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)
        guard let url = urls.first else { return }

        Task { [weak self] in
            await self?.importIcon(fromFileURL: url)
        }
    }
}
