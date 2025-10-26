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
    private let notificationPermissionService = NotificationPermissionService.shared
    private lazy var subscriptionNotificationService = SubscriptionNotificationService()
    private lazy var settingsController = SettingController(
        notificationPermissionService: notificationPermissionService,
        subscriptionNotificationScheduler: subscriptionNotificationService
    )
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
    private var panShowing = false
    private var panStartX: CGFloat = 0.0
    private var isHandlingPan = false
    private var panVisibleX: CGFloat = 0

    @objc private func hideSettingsTapped() {
        hideSettings()
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translationX = gesture.translation(in: view).x

        switch gesture.state {
        case .began:
            let locationInSettings = gesture.location(in: settingsContainer)
            if isShowingSettings, settingsContainer.bounds.contains(locationInSettings) {
                isHandlingPan = false
                return
            }

            isHandlingPan = true
            view.layer.removeAllAnimations()

            panShowing = isShowingSettings
            panStartX = panShowing ? settingsWidth : 0.0
            panVisibleX = panStartX

            settingsContainer.isHidden = false
            settingsLeadingConstraint?.update(offset: panStartX - settingsWidth)

            view.layoutIfNeeded()

        case .changed:
            guard isHandlingPan else { return }

            var visibleX = panStartX + translationX
            visibleX = min(max(0, visibleX), settingsWidth)

            settingsLeadingConstraint?.update(offset: visibleX - settingsWidth)
            panVisibleX = visibleX
            contentView.transform = visibleX == 0 ? .identity : CGAffineTransform(translationX: visibleX, y: 0)

            if visibleX > 0 {
                dimmingLeadingConstraint?.update(offset: visibleX)
            } else {
                dimmingLeadingConstraint?.update(offset: view.bounds.width)
            }
            dimmingView.alpha = visibleX / settingsWidth

            view.layoutIfNeeded()

        case .ended, .cancelled, .failed:
            guard isHandlingPan else { return }

            isHandlingPan = false

            let velocityX = gesture.velocity(in: view).x
            let speedThreshold: CGFloat = 300
            let positionThreshold = settingsWidth * 0.25

            let shouldShow: Bool = if velocityX > speedThreshold {
                true
            } else if velocityX < -speedThreshold {
                false
            } else {
                panVisibleX > positionThreshold
            }
            setSettingsVisible(shouldShow, animated: true)

        default:
            break
        }
    }

    private func setSettingsVisible(_ visible: Bool, animated: Bool) {
        isShowingSettings = visible
        dimmingView.isUserInteractionEnabled = visible

        if visible {
            settingsContainer.isHidden = false
        }

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

    deinit {
        NotificationCenter.default.removeObserver(self)
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

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsDidReset),
            name: .settingsDidReset,
            object: nil
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !isHandlingPan else { return }
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

    @objc private func handleSettingsDidReset() {
        hideSettings(animated: false)
    }
}

extension MainController: SubscriptionControllerSettingsDelegate {
    func subscriptionControllerDidRequestSettings(_: SubscriptionController) {
        showSettings()
    }
}
