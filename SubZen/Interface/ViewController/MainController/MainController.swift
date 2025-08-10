//
//  MainController.swift
//  SubZen
//
//  Created by Star on 2025/7/14.
//

import SnapKit
import UIKit

class MainController: UIViewController {
    let contentView = UIView().with {
        $0.backgroundColor = .systemBackground
    }

    let subscriptionController = SubscriptionController().with {
        $0.view.translatesAutoresizingMaskIntoConstraints = false
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

        view.backgroundColor = .systemBackground

        view.addSubview(contentView)
        contentView.addSubview(subscriptionController.view)

        addChild(subscriptionController)
        subscriptionController.didMove(toParent: self)

        setupViews()
        setupNotificationPermission()
    }

    private func setupViews() {
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        subscriptionController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
