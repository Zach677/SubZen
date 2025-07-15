//
//  SceneDelegate.swift
//  SubZen
//
//  Created by Star on 2025/7/14.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
		var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MainController()
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_: UIScene) {
    }

    func sceneDidBecomeActive(_: UIScene) {
    }

    func sceneWillResignActive(_: UIScene) {
    }

    func sceneWillEnterForeground(_: UIScene) {
    }

    func sceneDidEnterBackground(_: UIScene) {
    }
}
