//
//  AppCoordinator.swift
//  SubZen
//
//  Created by Migration Team on 2024/XX/XX.
//

import UIKit

// MARK: - Coordinator Protocol

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }

    func start()
    func finish()
}

extension Coordinator {
    func finish() {
        // 默认实现：从父协调器中移除自己
    }
}

// MARK: - App Coordinator

class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    private let window: UIWindow

    // MARK: - Initialization

    init(window: UIWindow) {
        self.window = window
        navigationController = UINavigationController()

        // 配置导航控制器
        configureNavigationController()

        // 设置窗口
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    // MARK: - Coordinator Methods

    func start() {
        showSubscriptionList()
    }

    func finish() {
        // 应用协调器通常不需要finish
    }

    // MARK: - Navigation Methods

    func showSubscriptionList() {
        let mainCoordinator = MainCoordinator(navigationController: navigationController)
        mainCoordinator.parentCoordinator = self
        childCoordinators.append(mainCoordinator)
        mainCoordinator.start()
    }

    func showAddSubscription() {
        let addCoordinator = AddSubscriptionCoordinator(navigationController: navigationController)
        addCoordinator.parentCoordinator = self
        childCoordinators.append(addCoordinator)
        addCoordinator.start()
    }

    func navigateToSubscription(id: String) {
        // 导航到特定订阅
        if let mainCoordinator = childCoordinators.first(where: { $0 is MainCoordinator })
            as? MainCoordinator
        {
            mainCoordinator.showSubscriptionDetail(id: id)
        }
    }

    func refreshData() {
        // 刷新所有数据
        if let mainCoordinator = childCoordinators.first(where: { $0 is MainCoordinator })
            as? MainCoordinator
        {
            mainCoordinator.refreshData()
        }
    }

    // MARK: - Child Coordinator Management

    func childDidFinish(_ child: Coordinator) {
        childCoordinators.removeAll { $0 === child }
    }

    // MARK: - Private Methods

    private func configureNavigationController() {
        // 配置导航控制器的外观
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .systemBlue

        // 配置导航栏样式
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold),
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
        ]

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
    }
}

// MARK: - Main Coordinator

class MainCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: AppCoordinator?

    private var subscriptionListViewController: SubscriptionListViewController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showSubscriptionList()
    }

    func finish() {
        parentCoordinator?.childDidFinish(self)
    }

    func showSubscriptionList() {
        let viewController = SubscriptionListViewController()
        viewController.coordinator = self
        subscriptionListViewController = viewController

        navigationController.pushViewController(viewController, animated: true)
    }

    func showAddSubscription() {
        let addCoordinator = AddSubscriptionCoordinator(navigationController: navigationController)
        addCoordinator.parentCoordinator = self
        addCoordinator.delegate = self
        childCoordinators.append(addCoordinator)
        addCoordinator.start()
    }

    func showEditSubscription(_ subscription: Subscription) {
        let editCoordinator = EditSubscriptionCoordinator(
            navigationController: navigationController,
            subscription: subscription
        )
        editCoordinator.parentCoordinator = self
        editCoordinator.delegate = self
        childCoordinators.append(editCoordinator)
        editCoordinator.start()
    }

    func showSubscriptionDetail(id: String) {
        // 显示订阅详情
        subscriptionListViewController?.scrollToSubscription(id: id)
    }

    func showSettings() {
        let settingsCoordinator = SettingsCoordinator(navigationController: navigationController)
        settingsCoordinator.parentCoordinator = self
        childCoordinators.append(settingsCoordinator)
        settingsCoordinator.start()
    }

    func refreshData() {
        subscriptionListViewController?.refreshData()
    }

    func childDidFinish(_ child: Coordinator) {
        childCoordinators.removeAll { $0 === child }
    }
}

// MARK: - Add Subscription Coordinator

class AddSubscriptionCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: MainCoordinator?
    weak var delegate: SubscriptionCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showAddSubscriptionForm()
    }

    func finish() {
        parentCoordinator?.childDidFinish(self)
    }

    func showAddSubscriptionForm() {
        let viewController = AddSubscriptionViewController()
        viewController.coordinator = self

        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .pageSheet

        navigationController.present(navController, animated: true)
    }

    func showCurrencySelection(selectedCurrency: String, completion: @escaping (String) -> Void) {
        let currencyCoordinator = CurrencySelectionCoordinator(
            navigationController: navigationController,
            selectedCurrency: selectedCurrency,
            completion: completion
        )
        currencyCoordinator.parentCoordinator = self
        childCoordinators.append(currencyCoordinator)
        currencyCoordinator.start()
    }

    func didAddSubscription(_ subscription: Subscription) {
        delegate?.didAddSubscription(subscription)
        dismissAddSubscription()
    }

    func dismissAddSubscription() {
        navigationController.dismiss(animated: true) { [weak self] in
            self?.finish()
        }
    }
}

// MARK: - Edit Subscription Coordinator

class EditSubscriptionCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: MainCoordinator?
    weak var delegate: SubscriptionCoordinatorDelegate?

    private let subscription: Subscription

    init(navigationController: UINavigationController, subscription: Subscription) {
        self.navigationController = navigationController
        self.subscription = subscription
    }

    func start() {
        showEditSubscriptionForm()
    }

    func finish() {
        parentCoordinator?.childDidFinish(self)
    }

    func showEditSubscriptionForm() {
        let viewController = EditSubscriptionViewController(subscription: subscription)
        viewController.coordinator = self

        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .pageSheet

        navigationController.present(navController, animated: true)
    }

    func showCurrencySelection(selectedCurrency: String, completion: @escaping (String) -> Void) {
        let currencyCoordinator = CurrencySelectionCoordinator(
            navigationController: navigationController,
            selectedCurrency: selectedCurrency,
            completion: completion
        )
        currencyCoordinator.parentCoordinator = self
        childCoordinators.append(currencyCoordinator)
        currencyCoordinator.start()
    }

    func didUpdateSubscription(_ subscription: Subscription) {
        delegate?.didUpdateSubscription(subscription)
        dismissEditSubscription()
    }

    func dismissEditSubscription() {
        navigationController.dismiss(animated: true) { [weak self] in
            self?.finish()
        }
    }
}

// MARK: - Currency Selection Coordinator

class CurrencySelectionCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: Coordinator?

    private let selectedCurrency: String
    private let completion: (String) -> Void

    init(
        navigationController: UINavigationController, selectedCurrency: String,
        completion: @escaping (String) -> Void
    ) {
        self.navigationController = navigationController
        self.selectedCurrency = selectedCurrency
        self.completion = completion
    }

    func start() {
        showCurrencySelection()
    }

    func finish() {
        if let parent = parentCoordinator as? AddSubscriptionCoordinator {
            parent.childDidFinish(self)
        } else if let parent = parentCoordinator as? EditSubscriptionCoordinator {
            parent.childDidFinish(self)
        }
    }

    func showCurrencySelection() {
        let viewController = CurrencySelectionViewController(selectedCurrency: selectedCurrency)
        viewController.coordinator = self
        viewController.onCurrencySelected = { [weak self] currency in
            self?.completion(currency)
            self?.dismissCurrencySelection()
        }

        navigationController.pushViewController(viewController, animated: true)
    }

    func dismissCurrencySelection() {
        navigationController.popViewController(animated: true)
        finish()
    }
}

// MARK: - Settings Coordinator

class SettingsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: MainCoordinator?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showSettings()
    }

    func finish() {
        parentCoordinator?.childDidFinish(self)
    }

    func showSettings() {
        let viewController = SettingsViewController()
        viewController.coordinator = self

        navigationController.pushViewController(viewController, animated: true)
    }
}

// MARK: - Subscription Coordinator Delegate

protocol SubscriptionCoordinatorDelegate: AnyObject {
    func didAddSubscription(_ subscription: Subscription)
    func didUpdateSubscription(_ subscription: Subscription)
    func didDeleteSubscription(_ subscription: Subscription)
}

// MARK: - MainCoordinator + SubscriptionCoordinatorDelegate

extension MainCoordinator: SubscriptionCoordinatorDelegate {
    func didAddSubscription(_ subscription: Subscription) {
        subscriptionListViewController?.addSubscription(subscription)
    }

    func didUpdateSubscription(_ subscription: Subscription) {
        subscriptionListViewController?.updateSubscription(subscription)
    }

    func didDeleteSubscription(_ subscription: Subscription) {
        subscriptionListViewController?.deleteSubscription(subscription)
    }
}
