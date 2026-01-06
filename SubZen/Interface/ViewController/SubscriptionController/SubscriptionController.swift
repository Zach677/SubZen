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
    private let lifetimeSpendingCalculator = LifetimeSpendingCalculator()
    private var summaryTask: Task<Void, Never>?
    private(set) var currentFilter: SubscriptionListView.Filter = .subscription
    private var cachedSubscriptions: [Subscription] = []
    weak var settingsDelegate: SubscriptionControllerSettingsDelegate?

    /// Indicates whether any subscription cell is currently showing swipe actions
    var isShowingSwipeActions: Bool {
        subscriptionListView.isShowingSwipeActions
    }

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
        cachedSubscriptions = subscriptionManager.allSubscriptions()
        applyFilterAndRefresh()
    }

    @objc private func handleSubscriptionsChanged() {
        loadSubscriptions()
    }

    @objc private func handleDefaultCurrencyChanged() {
        loadSubscriptions()
    }

    private func applyFilterAndRefresh() {
        let filteredSubscriptions = subscriptions(for: currentFilter)
        subscriptionListView.updateFilter(currentFilter)
        subscriptionListView.updateSubscriptions(filteredSubscriptions)
        refreshSummary(for: currentFilter, with: filteredSubscriptions)
    }

    private func subscriptions(for filter: SubscriptionListView.Filter) -> [Subscription] {
        switch filter {
        case .subscription:
            cachedSubscriptions
                .filter { !$0.isLifetime }
                .sorted { $0.remainingDays < $1.remainingDays }
        case .lifetime:
            cachedSubscriptions
                .filter(\.isLifetime)
                .sorted { $0.lastBillingDate > $1.lastBillingDate }
        }
    }

    private func refreshSummary(for filter: SubscriptionListView.Filter, with subscriptions: [Subscription]) {
        summaryTask?.cancel()

        guard !subscriptions.isEmpty else {
            subscriptionListView.updateSummary(nil)
            return
        }

        let baseCurrency = defaultCurrencyProvider.loadDefaultCurrency()

        // Check if currency conversion is needed
        let conversionMode = switch filter {
        case .subscription:
            spendingCalculator.evaluateConversionNeed(for: subscriptions, baseCurrencyCode: baseCurrency.code)
        case .lifetime:
            lifetimeSpendingCalculator.evaluateConversionNeed(for: subscriptions, baseCurrencyCode: baseCurrency.code)
        }

        switch conversionMode {
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

        summaryTask = Task { [currencyRateService, defaultCurrencyProvider, lifetimeSpendingCalculator, spendingCalculator, weak self] in
            guard let self else { return }
            do {
                let baseCurrency = defaultCurrencyProvider.loadDefaultCurrency()
                let snapshot = try await currencyRateService.latestSnapshot(for: baseCurrency.code)
                let result: SubscriptionSpendingResult = switch filter {
                case .subscription:
                    spendingCalculator.monthlyTotal(
                        for: subscriptions,
                        baseCurrencyCode: baseCurrency.code,
                        ratesSnapshot: snapshot
                    )
                case .lifetime:
                    lifetimeSpendingCalculator.total(
                        for: subscriptions,
                        baseCurrencyCode: baseCurrency.code,
                        ratesSnapshot: snapshot
                    )
                }

                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    let model = SubscriptionSummaryViewModel(
                        currency: baseCurrency,
                        total: result.total
                    )
                    subscriptionListView.updateSummary(model)
                }
            } catch {
                // Show fallback: calculate base currency subscriptions only
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    let baseCurrency = defaultCurrencyProvider.loadDefaultCurrency()
                    let fallbackTotal = switch filter {
                    case .subscription:
                        calculateFallbackTotal(
                            subscriptions: subscriptions,
                            baseCurrencyCode: baseCurrency.code
                        )
                    case .lifetime:
                        calculateLifetimeFallbackTotal(
                            subscriptions: subscriptions,
                            baseCurrencyCode: baseCurrency.code
                        )
                    }
                    let model = SubscriptionSummaryViewModel(
                        currency: baseCurrency,
                        total: fallbackTotal
                    )
                    subscriptionListView.updateSummary(model)
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

    private func calculateLifetimeFallbackTotal(
        subscriptions: [Subscription],
        baseCurrencyCode: String
    ) -> Decimal {
        let base = baseCurrencyCode.uppercased()
        var total: Decimal = 0

        for subscription in subscriptions {
            let code = subscription.currencyCode.uppercased()
            if code == base {
                total += subscription.price
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

    func subscriptionListViewDidChangeFilter(_: SubscriptionListView, filter: SubscriptionListView.Filter) {
        currentFilter = filter
        applyFilterAndRefresh()
    }
}
