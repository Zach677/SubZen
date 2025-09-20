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

    private var isShowingSettings = false
    private let dimmingView = UIView().with {
        $0.backgroundColor = .background.withAlphaComponent(0.1)
        $0.alpha = 0.0
    }

    private var settingsLeadingConstraint: Constraint?
    private var dimmingLeadingConstraint: Constraint?
    private var settingsWidth: CGFloat { view.bounds.width * 0.75 }

    @objc private func hideSettingsTapped() {
        hideSettings()
    }

    private func setSettingsVisible(_ visible: Bool, animated: Bool) {
        isShowingSettings = visible
        dimmingView.isUserInteractionEnabled = visible

        let animations = { [weak self] in
            guard let self else { return }
            settingsLeadingConstraint?.update(offset: visible ? 0 : -settingsWidth)
            dimmingLeadingConstraint?.update(offset: visible ? settingsWidth : view.bounds.width)
            view.layoutIfNeeded()

            let translation = visible ? settingsWidth : 0
            contentView.transform = translation == 0 ? .identity : CGAffineTransform(translationX: translation, y: 0)
            dimmingView.alpha = visible ? 1.0 : 0.0
        }

        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.2,
                options: [.curveEaseOut]
            ) {
                animations()
            }
        } else {
            animations()
        }
    }

    private func showSettings(animated: Bool = true) {
        guard !isShowingSettings else { return }
        setSettingsVisible(true, animated: animated)
    }

    private func hideSettings(animated: Bool = true) {
        guard isShowingSettings else { return }
        setSettingsVisible(false, animated: animated)
    }

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
        setupDimmingOverlay()

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
        setSettingsVisible(isShowingSettings, animated: false)
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

    private func setupDimmingOverlay() {
        view.insertSubview(dimmingView, aboveSubview: contentView)
        dimmingView.snp.makeConstraints { make in
            dimmingLeadingConstraint = make.leading.equalTo(view.snp.leading).offset(view.bounds.width).constraint
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideSettingsTapped))
        dimmingView.addGestureRecognizer(tapGesture)
        dimmingView.isUserInteractionEnabled = false
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
    func subscriptionControllerDidRequestSettings(_: SubscriptionController) {
        showSettings()
    }
}
