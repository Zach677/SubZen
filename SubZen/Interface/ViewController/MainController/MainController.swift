//
//  MainController.swift
//  SubZen
//
//  Created by Star on 2025/7/14.
//

import SnapKit
import UIKit

class MainController: UIViewController {
    private let contentView = UIView().with {
        $0.backgroundColor = .background
    }

    private let subscriptionController = SubscriptionController()
    private let settingsController = SettingController()
    private let settingsContainer = UIView().with {
        $0.backgroundColor = .background
        $0.clipsToBounds = true
    }

    private var settingsLeadingConstraint: Constraint?
    private var settingsWidth: CGFloat { view.bounds.width * 0.75 }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        setupSettingsStack()

        addChild(subscriptionController)
        subscriptionController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subscriptionController.view)
        subscriptionController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        subscriptionController.didMove(toParent: self)

        subscriptionController.settingsDelegate = self

        setupNotificationPermission()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        settingsLeadingConstraint?.update(offset: -settingsWidth)
    }

    private func setupSettingsStack() {
        addChild(settingsController)
        settingsController.view.translatesAutoresizingMaskIntoConstraints = false

        view.insertSubview(settingsContainer, belowSubview: contentView)
        settingsContainer.snp.makeConstraints { make in
            settingsLeadingConstraint = make.leading.equalTo(view.snp.leading).offset(-settingsWidth).constraint
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
            make.width.equalTo(view.snp.width).multipliedBy(0.75)
        }

        settingsContainer.addSubview(settingsController.view)
        settingsController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        settingsController.didMove(toParent: self)
    }

    private func setupNotificationPermission() {
        let notificationService = NotificationPermissionService.shared

        if notificationService.shouldRequestPermission() {
            Task {
                await notificationService.requestNotificationPermission()
                print("Notification permission requested")
            }
        } else {
            print("Notification permission already requested or not needed")
        }
    }
}

extension MainController: SubscriptionControllerSettingsDelegate {
    func subscriptionControllerDidRequestSettings(_: SubscriptionController) {}
}
