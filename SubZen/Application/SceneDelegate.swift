//
//  SceneDelegate.swift
//  SubZen
//
//  Created by Star on 2025/7/14.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // 使用 lazy 延迟初始化，确保在整个 SceneDelegate 生命周期内只创建一次
    // 避免重复创建控制器实例，提供更好的内存管理
    lazy var mainController = MainController()

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // 创建局部 window 变量避免重复的可选解包，代码更清晰
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = mainController
        // 将配置好的 window 赋值给实例属性进行持有
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_: UIScene) {}

    func sceneDidBecomeActive(_: UIScene) {}

    func sceneWillResignActive(_: UIScene) {}

    func sceneWillEnterForeground(_: UIScene) {}

    func sceneDidEnterBackground(_: UIScene) {}
}
