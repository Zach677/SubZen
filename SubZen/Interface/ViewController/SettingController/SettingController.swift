//
//  SettingController.swift
//  SubZen
//
//  Created by Star on 2025/9/10.
//

import UIKit
import UniformTypeIdentifiers

class SettingController: UIViewController {
    private var settingView: SettingView { view as! SettingView }
    private var isResetInProgress = false
    private let notificationPermissionService: NotificationPermissionService
    private let subscriptionNotificationScheduler: SubscriptionNotificationScheduling
    private let defaultCurrencyProvider: DefaultCurrencyProviding
    private let exportService: SubscriptionExportService
    private let importService: SubscriptionImportService
    private var exportFileURL: URL?
    private var pendingImportURL: URL?
    #if DEBUG
        private let subscriptionProvider: () -> [Subscription]

        init(
            notificationPermissionService: NotificationPermissionService = .shared,
            subscriptionNotificationScheduler: SubscriptionNotificationScheduling = SubscriptionNotificationService(),
            subscriptionProvider: @escaping () -> [Subscription] = { SubscriptionManager.shared.allSubscriptions() },
            defaultCurrencyProvider: DefaultCurrencyProviding = DefaultCurrencyProvider(),
            exportService: SubscriptionExportService = SubscriptionExportService(),
            importService: SubscriptionImportService = SubscriptionImportService()
        ) {
            self.notificationPermissionService = notificationPermissionService
            self.subscriptionNotificationScheduler = subscriptionNotificationScheduler
            self.subscriptionProvider = subscriptionProvider
            self.defaultCurrencyProvider = defaultCurrencyProvider
            self.exportService = exportService
            self.importService = importService
            super.init(nibName: nil, bundle: nil)
        }
    #else
        init(
            notificationPermissionService: NotificationPermissionService = .shared,
            subscriptionNotificationScheduler: SubscriptionNotificationScheduling = SubscriptionNotificationService(),
            defaultCurrencyProvider: DefaultCurrencyProviding = DefaultCurrencyProvider(),
            exportService: SubscriptionExportService = SubscriptionExportService(),
            importService: SubscriptionImportService = SubscriptionImportService()
        ) {
            self.notificationPermissionService = notificationPermissionService
            self.subscriptionNotificationScheduler = subscriptionNotificationScheduler
            self.defaultCurrencyProvider = defaultCurrencyProvider
            self.exportService = exportService
            self.importService = importService
            super.init(nibName: nil, bundle: nil)
        }
    #endif

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func loadView() {
        view = SettingView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingView.delegate = self
        let current = defaultCurrencyProvider.loadDefaultCurrency()
        settingView.setDefaultCurrency(current)
    }

    private func presentFinalResetPrompt() {
        let alert = UIAlertController(
            title: String(localized: "Confirm Reset"),
            message: String(localized: "Tap Reset to erase all data and restart the app."),
            preferredStyle: .alert
        )

        let cancel = UIAlertAction(
            title: String(localized: "Cancel"),
            style: .cancel
        )
        let reset = UIAlertAction(
            title: String(localized: "Reset"),
            style: .destructive
        ) { [weak self] _ in
            self?.performFactoryReset()
        }

        alert.addAction(cancel)
        alert.addAction(reset)

        present(alert, animated: true)
    }

    private func performFactoryReset() {
        guard !isResetInProgress else { return }

        isResetInProgress = true
        settingView.setResetEnabled(false)

        SettingsResetService.shared.resetAll(scope: .full) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                terminateApp()
            case let .failure(error):
                isResetInProgress = false
                settingView.setResetEnabled(true)
                presentResetFailureAlert(error: error)
            }
        }
    }

    private func presentResetFailureAlert(error: Error) {
        let alert = UIAlertController(
            title: String(localized: "Reset Failed"),
            message: error.localizedDescription,
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

    private func terminateApp() {
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exit(0)
        }
    }

    private func presentCurrencyPicker() {
        let current = defaultCurrencyProvider.loadDefaultCurrency()
        let picker = CurrencyPickerController(currencies: CurrencyList.allCurrencies, selectedCode: current.code)
        picker.onSelectCurrency = { [weak self] currency in
            guard let self else { return }
            settingView.setDefaultCurrency(currency)
            defaultCurrencyProvider.saveDefaultCurrency(currency)
        }
        let navigationController = UINavigationController(rootViewController: picker)
        navigationController.modalPresentationStyle = .pageSheet
        if let sheet = navigationController.sheetPresentationController { sheet.detents = [.medium(), .large()] }
        present(navigationController, animated: true)
    }

    private func presentPrivacyPolicy() {
        let privacyController = PrivacyPolicyController()
        let navigationController = UINavigationController(rootViewController: privacyController)
        navigationController.modalPresentationStyle = .pageSheet
        if let sheet = navigationController.sheetPresentationController { sheet.detents = [.large()] }
        present(navigationController, animated: true)
    }

    private func presentExportActivity() {
        do {
            let fileURL = try exportService.exportToJSON()
            exportFileURL = fileURL

            let activityController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )

            activityController.completionWithItemsHandler = { [weak self] _, _, _, _ in
                if let url = self?.exportFileURL {
                    self?.exportService.cleanupExportFile(at: url)
                    self?.exportFileURL = nil
                }
            }

            if let popover = activityController.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            present(activityController, animated: true)
        } catch {
            presentExportFailureAlert(error: error)
        }
    }

    private func presentExportFailureAlert(error: Error) {
        let alert = UIAlertController(
            title: String(localized: "Export Failed"),
            message: error.localizedDescription,
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

    private func presentDocumentPicker() {
        // Include multiple content types as JSON files may be identified differently
        // depending on source (iCloud, email, etc.)
        let contentTypes: [UTType] = [.json, .plainText, .data]
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: contentTypes,
            asCopy: true
        )
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func handleImportDocumentPick(fileURL: URL) {
        let shouldStopAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        // Copy file to a temporary location to ensure access after scope ends.
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")

        do {
            try FileManager.default.copyItem(at: fileURL, to: tempURL)
            presentImportModeSelection(for: tempURL)
        } catch {
            presentImportFailureAlert(error: error)
        }
    }

    private func presentImportModeSelection(for fileURL: URL) {
        pendingImportURL = fileURL

        // Skip mode selection when list is empty - merge and replace are equivalent
        let existingSubscriptions = SubscriptionManager.shared.allSubscriptions()
        if existingSubscriptions.isEmpty {
            performImport(mode: .merge)
            return
        }

        let alert = UIAlertController(
            title: String(localized: "Import Mode"),
            message: nil,
            preferredStyle: .actionSheet
        )

        let mergeAction = UIAlertAction(
            title: String(localized: "Merge"),
            style: .default
        ) { [weak self] _ in
            self?.performImport(mode: .merge)
        }

        let replaceAction = UIAlertAction(
            title: String(localized: "Replace"),
            style: .destructive
        ) { [weak self] _ in
            self?.performImport(mode: .replace)
        }

        let cancelAction = UIAlertAction(
            title: String(localized: "Cancel"),
            style: .cancel
        ) { [weak self] _ in
            // Clean up temporary file when user cancels
            if let url = self?.pendingImportURL {
                try? FileManager.default.removeItem(at: url)
            }
            self?.pendingImportURL = nil
        }

        alert.addAction(mergeAction)
        alert.addAction(replaceAction)
        alert.addAction(cancelAction)

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    private func performImport(mode: ImportMode) {
        guard let fileURL = pendingImportURL else { return }
        pendingImportURL = nil

        defer {
            // Clean up temporary file
            try? FileManager.default.removeItem(at: fileURL)
        }

        do {
            let result = try importService.importFromJSON(fileURL: fileURL, mode: mode)
            presentImportSuccessAlert(result: result)
        } catch {
            presentImportFailureAlert(error: error)
        }
    }

    private func presentImportSuccessAlert(result: ImportResult) {
        let imported = Int64(result.imported)
        let message: String
        if result.skipped > 0 {
            let skipped = Int64(result.skipped)
            let key: String.LocalizationValue = "Imported \(imported), skipped \(skipped) duplicates"
            message = String(localized: key)
        } else {
            let key: String.LocalizationValue = "Imported \(imported) subscriptions"
            message = String(localized: key)
        }

        let alert = UIAlertController(
            title: String(localized: "Import Successful"),
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

    private func presentImportFailureAlert(error: Error) {
        let alert = UIAlertController(
            title: String(localized: "Import Failed"),
            message: error.localizedDescription,
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

extension SettingController: SettingViewDelegate {
    func settingViewDidTapReset(_: SettingView) {
        presentFinalResetPrompt()
    }

    func settingViewDidTapDefaultCurrency(_: SettingView) {
        presentCurrencyPicker()
    }

    func settingViewDidTapExportSubscriptions(_: SettingView) {
        presentExportActivity()
    }

    func settingViewDidTapImportSubscriptions(_: SettingView) {
        presentDocumentPicker()
    }

    func settingViewDidTapPrivacyPolicy(_: SettingView) {
        presentPrivacyPolicy()
    }

    #if DEBUG
        func settingViewDidTapDebugNotification(_: SettingView) {
            Task { [
                notificationPermissionService,
                subscriptionNotificationScheduler,
                subscriptionProvider
            ] in
                if notificationPermissionService.shouldRequestPermission() {
                    await notificationPermissionService.requestNotificationPermission()
                }

                let subscriptions = subscriptionProvider()

                for subscription in subscriptions {
                    do {
                        try await subscriptionNotificationScheduler.triggerDebugExpirationPreview(for: subscription)
                        print("[DebugNotification] Scheduled previews for '\(subscription.name)'.")
                    } catch {
                        print("[DebugNotification] Failed preview for '\(subscription.name)': \(error)")
                    }
                }
            }
        }
    #endif
}

// MARK: - UIDocumentPickerDelegate

extension SettingController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else {
            controller.dismiss(animated: true)
            return
        }

        controller.dismiss(animated: true) { [weak self] in
            self?.handleImportDocumentPick(fileURL: fileURL)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}
