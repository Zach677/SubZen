//
//  MainController.swift
//  SubZen
//
//  Created by Star on 2025/7/14.
//

import SwiftUI
import UIKit

class MainController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MainController: viewDidLoad called")
        setupSwiftUIView()
        setupNotificationPermission()
    }

    private func setupSwiftUIView() {
        // 创建SwiftUI视图
        let subscriptionListView = SubscriptionListView()
        let hostingController = UIHostingController(rootView: subscriptionListView)

        // 添加为子视图控制器
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        // 设置自动布局约束
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        print("SwiftUI view setup completed")
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
