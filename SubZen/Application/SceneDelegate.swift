//
//  SceneDelegate.swift
//  SubZen
//
//  Created by Star on 2025/7/14.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // Use lazy initialization to ensure single instance creation throughout SceneDelegate lifecycle
    // Provides better memory management by avoiding duplicate controller instances
    lazy var mainController = MainController()

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Create local window variable to avoid repeated optional unwrapping for cleaner code
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .background
        window.rootViewController = mainController
        // Assign configured window to instance property for retention
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_: UIScene) {}

    func sceneDidBecomeActive(_: UIScene) {}

    func sceneWillResignActive(_: UIScene) {}

    func sceneWillEnterForeground(_: UIScene) {}

    func sceneDidEnterBackground(_: UIScene) {}
}
