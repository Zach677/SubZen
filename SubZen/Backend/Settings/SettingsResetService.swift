//
//  SettingsResetService.swift
//  SubZen
//
//  Created by Star on 2025/9/12.
//

import Foundation

protocol SubscriptionManaging {
    func eraseAll()
}

protocol CurrencyResetting {
    func resetBaseCurrency()
}

protocol NotificationPermissionResetting {
    func resetRequestTracking()
}

protocol ExchangeRateCacheClearing {
    func clearCache()
}

final class SettingsResetService {
    enum Scope {
        case settingsOnly
        case full
    }

    static let shared = SettingsResetService()

    private let subscriptionManager: SubscriptionManaging
    private let currencyService: CurrencyResetting
    private let notificationService: NotificationPermissionResetting
    private let exchangeRateService: ExchangeRateCacheClearing
    private let notificationCenter: NotificationCenter

    init(
        subscriptionManager: SubscriptionManaging = SubscriptionManager.shared,
        currencyService: CurrencyResetting = CurrencyTotalService.shared,
        notificationService: NotificationPermissionResetting = NotificationPermissionService.shared,
        exchangeRateService: ExchangeRateCacheClearing = ExchangeRateService.shared,
        notificationCenter: NotificationCenter = .default
    ) {
        self.subscriptionManager = subscriptionManager
        self.currencyService = currencyService
        self.notificationService = notificationService
        self.exchangeRateService = exchangeRateService
        self.notificationCenter = notificationCenter
    }

    func resetAll(scope: Scope = .full, completion: ((Result<Void, Error>) -> Void)? = nil) {
        let performReset = { [weak self] in
            guard let self else { return }

            exchangeRateService.clearCache()
            currencyService.resetBaseCurrency()
            notificationService.resetRequestTracking()

            if scope == .full {
                subscriptionManager.eraseAll()
            }

            notificationCenter.post(name: .settingsDidReset, object: nil)
            completion?(.success(()))
        }

        if Thread.isMainThread {
            performReset()
        } else {
            DispatchQueue.main.async {
                performReset()
            }
        }
    }
}

extension SubscriptionManager: SubscriptionManaging {}

extension CurrencyTotalService: CurrencyResetting {}

extension NotificationPermissionService: NotificationPermissionResetting {}

extension ExchangeRateService: ExchangeRateCacheClearing {
    func clearCache() {
        clearCache(for: nil)
    }
}
