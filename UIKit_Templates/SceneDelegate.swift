//
//  SceneDelegate.swift
//  SubZen
//
//  Created by Migration Team on 2024/XX/XX.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?
  var appCoordinator: AppCoordinator?

  // MARK: - Scene Lifecycle

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    // 创建窗口
    window = UIWindow(windowScene: windowScene)

    // 初始化应用协调器
    appCoordinator = AppCoordinator(window: window!)

    // 启动应用
    appCoordinator?.start()

    print("🚀 应用启动完成")
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    // 场景断开连接时调用
    print("📱 场景已断开连接")
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // 场景变为活跃状态
    handleSceneDidBecomeActive()
  }

  func sceneWillResignActive(_ scene: UIScene) {
    // 场景即将失去活跃状态
    handleSceneWillResignActive()
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    // 场景即将进入前台
    handleSceneWillEnterForeground()
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    // 场景已进入后台
    handleSceneDidEnterBackground()
  }

  // MARK: - Private Methods

  private func handleSceneDidBecomeActive() {
    // 刷新汇率数据（如果需要）
    refreshExchangeRatesIfNeeded()

    // 更新应用图标徽章
    updateAppBadge()

    print("✅ 应用已激活")
  }

  private func handleSceneWillResignActive() {
    // 保存当前状态
    saveCurrentState()

    print("⏸️ 应用即将失去焦点")
  }

  private func handleSceneWillEnterForeground() {
    // 刷新数据
    refreshDataIfNeeded()

    print("🔄 应用即将进入前台")
  }

  private func handleSceneDidEnterBackground() {
    // 保存数据
    saveApplicationData()

    // 清理临时数据
    cleanupTemporaryData()

    print("💤 应用已进入后台")
  }

  private func refreshExchangeRatesIfNeeded() {
    // 检查汇率数据是否需要刷新
    let exchangeRateService = ExchangeRateService.shared
    let baseCurrency = CurrencyTotalService.shared.baseCurrency

    if !exchangeRateService.isCacheValid(for: baseCurrency) {
      Task {
        do {
          _ = try await exchangeRateService.refreshExchangeRates(baseCurrency: baseCurrency)
          print("💱 汇率数据已刷新")
        } catch {
          print("❌ 汇率数据刷新失败: \(error)")
        }
      }
    }
  }

  private func updateAppBadge() {
    // 更新应用图标徽章（显示即将到期的订阅数量）
    // 这里可以添加逻辑来计算即将到期的订阅
    Task {
      await MainActor.run {
        UIApplication.shared.applicationIconBadgeNumber = 0
      }
    }
  }

  private func saveCurrentState() {
    // 保存当前的应用状态
    // 例如：当前选中的标签、滚动位置等
    UserDefaults.standard.set(Date(), forKey: "LastActiveDate")
  }

  private func refreshDataIfNeeded() {
    // 检查是否需要刷新数据
    if let lastActiveDate = UserDefaults.standard.object(forKey: "LastActiveDate") as? Date {
      let timeInterval = Date().timeIntervalSince(lastActiveDate)

      // 如果超过 5 分钟，刷新数据
      if timeInterval > 300 {
        appCoordinator?.refreshData()
      }
    }
  }

  private func saveApplicationData() {
    // 保存应用数据
    // UserDefaults 会自动保存，这里可以添加其他保存逻辑
    UserDefaults.standard.synchronize()
  }

  private func cleanupTemporaryData() {
    // 清理临时数据
    // 例如：清理临时缓存、取消网络请求等
    URLCache.shared.removeAllCachedResponses()
  }
}

// MARK: - Deep Link Handling

extension SceneDelegate {

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }

    // 处理深链接
    handleDeepLink(url)
  }

  private func handleDeepLink(_ url: URL) {
    // 解析深链接并导航到相应页面
    print("🔗 处理深链接: \(url)")

    // 例如：subzen://subscription/123
    if url.scheme == "subzen" {
      switch url.host {
      case "subscription":
        if let subscriptionId = url.pathComponents.last {
          appCoordinator?.navigateToSubscription(id: subscriptionId)
        }
      case "add":
        appCoordinator?.showAddSubscription()
      default:
        break
      }
    }
  }
}

// MARK: - Shortcut Items

extension SceneDelegate {

  func scene(
    _ scene: UIScene, performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {

    // 处理快捷操作
    handleShortcutItem(shortcutItem)
    completionHandler(true)
  }

  private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
    print("⚡ 处理快捷操作: \(shortcutItem.type)")

    switch shortcutItem.type {
    case "com.zach.SubZen.add-subscription":
      appCoordinator?.showAddSubscription()
    case "com.zach.SubZen.view-total":
      appCoordinator?.showSubscriptionList()
    default:
      break
    }
  }
}
