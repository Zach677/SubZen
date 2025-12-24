//
//  SubscriptionController.swift
//  SubZen
//
//  Created by Star on 2025/7/17.
//

import SnapKit
import UIKit

protocol SubscriptionControllerSettingsDelegate: AnyObject {
    func subscriptionControllerDidRequestSettings(_ controller: SubscriptionController)
}

class SubscriptionController: UIViewController {
    private let subscriptionListView = SubscriptionListView()
    let subscriptionManager = SubscriptionManager.shared
    private let currencyRateService = CurrencyRateService()
    private let defaultCurrencyProvider = DefaultCurrencyProvider()
    private let spendingCalculator = SubscriptionSpendingCalculator()
    private var summaryTask: Task<Void, Never>?
    weak var settingsDelegate: SubscriptionControllerSettingsDelegate?

    deinit {
        NotificationCenter.default.removeObserver(self)
        summaryTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        subscriptionListView.delegate = self

        view.addSubview(subscriptionListView)

        subscriptionListView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        // Observe creation and update events to keep list fresh
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionsChanged),
            name: .newSubCreated,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionsChanged),
            name: .subscriptionUpdated,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDefaultCurrencyChanged),
            name: .defaultCurrencyDidChange,
            object: nil
        )
        loadSubscriptions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSubscriptions()
    }

    func loadSubscriptions() {
        let subscriptions = subscriptionManager.allSubscriptions()
        subscriptionListView.updateSubscriptions(subscriptions)
        refreshSummary(with: subscriptions)
    }

    @objc private func handleSubscriptionsChanged() {
        loadSubscriptions()
    }

    @objc private func handleDefaultCurrencyChanged() {
        loadSubscriptions()
    }

    private func refreshSummary(with subscriptions: [Subscription]) {
        summaryTask?.cancel()

        guard !subscriptions.isEmpty else {
            subscriptionListView.updateSummary(nil)
            return
        }

        let baseCurrency = defaultCurrencyProvider.loadDefaultCurrency()

        // Check if currency conversion is needed
        switch spendingCalculator.evaluateConversionNeed(for: subscriptions, baseCurrencyCode: baseCurrency.code) {
        case let .noCurrencyConversion(total):
            // All subscriptions use the base currency; skip network request
            let model = SubscriptionSummaryViewModel(
                currency: baseCurrency,
                total: total
            )
            subscriptionListView.updateSummary(model)
            return

        case .requiresConversion:
            break
        }

        summaryTask = Task { [weak self] in
            guard let self else { return }
            do {
                let snapshot = try await currencyRateService.latestSnapshot(for: baseCurrency.code)
                let result = spendingCalculator.monthlyTotal(
                    for: subscriptions,
                    baseCurrencyCode: baseCurrency.code,
                    ratesSnapshot: snapshot
                )

                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    let model = SubscriptionSummaryViewModel(
                        currency: baseCurrency,
                        total: result.total
                    )
                    self.subscriptionListView.updateSummary(model)
                }
            } catch {
                // Show fallback: calculate base currency subscriptions only
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    let fallbackTotal = self.calculateFallbackTotal(
                        subscriptions: subscriptions,
                        baseCurrencyCode: baseCurrency.code
                    )
                    let model = SubscriptionSummaryViewModel(
                        currency: baseCurrency,
                        total: fallbackTotal
                    )
                    self.subscriptionListView.updateSummary(model)
                }
            }
        }
    }

    private func calculateFallbackTotal(
        subscriptions: [Subscription],
        baseCurrencyCode: String
    ) -> Decimal {
        let base = baseCurrencyCode.uppercased()
        var total: Decimal = 0

        for subscription in subscriptions {
            let code = subscription.currencyCode.uppercased()
            if code == base {
                total += spendingCalculator.monthlyAmount(for: subscription)
            }
        }

        return total
    }
}

extension SubscriptionController: SubscriptionListViewDelegate {
    func subscriptionListViewDidRequestSettings(_: SubscriptionListView) {
        settingsDelegate?.subscriptionControllerDidRequestSettings(self)
    }

    func subscriptionListViewDidTapAddButton() {
        addSubscriptionTapped()
    }

    func subscriptionListViewDidSelectSubscription(_ subscription: Subscription) {
        presentSubscriptionEditor(for: subscription)
    }

    func subscriptionListViewDidRequestDelete(_ subscription: Subscription) {
        deleteSubscription(subscription)
    }
}
