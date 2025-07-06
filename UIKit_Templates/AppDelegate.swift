//
//  AppDelegate.swift
//  SubZen
//
//  Created by Migration Team on 2024/XX/XX.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  // MARK: - Application Lifecycle

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 配置应用外观
    configureAppearance()

    // 初始化服务
    initializeServices()

    // 请求通知权限
    requestNotificationPermissions()

    return true
  }

  // MARK: - UISceneSession Lifecycle

  func application(
    _ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(
      name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(
    _ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
    // Called when the user discards a scene session.
  }

  // MARK: - Background Tasks

  func applicationDidEnterBackground(_ application: UIApplication) {
    // 保存数据
    saveApplicationData()
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // 应用即将终止，保存数据
    saveApplicationData()
  }

  // MARK: - Memory Management

  func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    // 清理缓存
    clearMemoryCache()
  }

  // MARK: - Private Methods

  private func configureAppearance() {
    // 配置导航栏外观
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor.systemBackground
    appearance.titleTextAttributes = [.foregroundColor: UIColor.label]

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance

    // 配置标签栏外观
    let tabBarAppearance = UITabBarAppearance()
    tabBarAppearance.configureWithOpaqueBackground()
    tabBarAppearance.backgroundColor = UIColor.systemBackground

    UITabBar.appearance().standardAppearance = tabBarAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
  }

  private func initializeServices() {
    // 初始化货币服务
    _ = CurrencyTotalService.shared

    // 初始化汇率服务
    _ = ExchangeRateService.shared

    // 初始化通知服务
    _ = NotificationPermissionService.shared

    print("✅ 服务初始化完成")
  }

  private func requestNotificationPermissions() {
    let notificationService = NotificationPermissionService.shared

    if notificationService.shouldRequestPermission() {
      Task {
        await notificationService.requestNotificationPermission()
      }
    }
  }

  private func saveApplicationData() {
    // 这里可以添加数据保存逻辑
    // 由于使用 UserDefaults，数据会自动保存
    print("💾 应用数据已保存")
  }

  private func clearMemoryCache() {
    // 清理汇率缓存
    ExchangeRateService.shared.clearCache()

    // 清理其他内存缓存
    print("🧹 内存缓存已清理")
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {

    // 在前台也显示通知
    completionHandler([.banner, .sound, .badge])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {

    // 处理通知点击
    handleNotificationResponse(response)
    completionHandler()
  }

  private func handleNotificationResponse(_ response: UNNotificationResponse) {
    let userInfo = response.notification.request.content.userInfo

    // 根据通知类型处理
    if let subscriptionId = userInfo["subscriptionId"] as? String {
      // 导航到对应的订阅详情
      navigateToSubscription(id: subscriptionId)
    }
  }

  private func navigateToSubscription(id: String) {
    // 通过 AppCoordinator 导航到订阅详情
    // 这里需要获取当前的 AppCoordinator 实例
    print("📱 导航到订阅: \(id)")
  }
}
