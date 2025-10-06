//
//  SettingController.swift
//  SubZen
//
//  Created by Star on 2025/9/10.
//

import UIKit

class SettingController: UIViewController {
    private var settingView: SettingView { view as! SettingView }
    private var isResetInProgress = false
    private let notificationPermissonService: NotificationPermissionService
    private let subscriptionNotificationScheduler: SubscriptionNotificationScheduling
    #if DEBUG
        private let subscriptionProvider: () -> [Subscription]

        init(
            notificationPermissonService: NotificationPermissionService = .shared,
            subscriptionNotificationScheduler: SubscriptionNotificationScheduling = SubscriptionNotificationService(),
            subscriptionProvider: @escaping () -> [Subscription] = { SubscriptionManager.shared.getAllSubscriptions() }
        ) {
            self.notificationPermissonService = notificationPermissonService
            self.subscriptionNotificationScheduler = subscriptionNotificationScheduler
            self.subscriptionProvider = subscriptionProvider
            super.init(nibName: nil, bundle: nil)
        }
    #else
        init(
            notificationPermissonService: NotificationPermissionService = .shared,
            subscriptionNotificationScheduler: SubscriptionNotificationScheduling = SubscriptionNotificationService()
        ) {
            self.notificationPermissonService = notificationPermissonService
            self.subscriptionNotificationScheduler = subscriptionNotificationScheduler
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
}

extension SettingController: SettingViewDelegate {
    func settingViewDidTapReset(_: SettingView) {
        presentFinalResetPrompt()
    }

    #if DEBUG
        func settingViewDidTapDebugNotification(_: SettingView) {
            Task { [
                notificationPermissonService,
                subscriptionNotificationScheduler,
                subscriptionProvider
            ] in
                if notificationPermissonService.shouldRequestPermission() {
                    await notificationPermissonService.requestNotificationPermission()
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
