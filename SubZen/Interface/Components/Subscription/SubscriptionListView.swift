//
//  SubscriptionListView.swift
//  SubZen
//
//  Created by Star on 2025/8/9.
//

import SnapKit
import UIKit

protocol SubscriptionListViewDelegate: AnyObject {
    func subscriptionListViewDidSelectSubscription(_ subscription: Subscription)
    func subscriptionListViewDidTapAddButton()
    func subscriptionListViewDidRequestSettings(_ listview: SubscriptionListView)
    func subscriptionListViewDidRequestDelete(_ subscription: Subscription)
    func subscriptionListViewDidChangeFilter(_ listview: SubscriptionListView, filter: SubscriptionListView.Filter)
}

protocol TitleBarDelegate: AnyObject {
    func titleBarDidTapAddButton()
    func titleBarDidRequestSettings(_ titleBar: SubscriptionListView.TitleBar)
}

class SubscriptionListView: UIView {
    enum LayoutConstants {
        static let filterHeight: CGFloat = 34
        static let filterContentInset: CGFloat = 0
        static let rowCardHorizontalInset: CGFloat = 16
        static let tableContentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        static let bottomFadeHeight: CGFloat = 72
        static let titleBarHeight: CGFloat = 64
        static let titleBarButtonSize: CGFloat = 56
    }

    enum Filter: Int {
        case subscription
        case lifetime
    }

    weak var delegate: SubscriptionListViewDelegate?

    /// Indicates whether any cell is currently showing swipe actions (delete button visible)
    private(set) var isShowingSwipeActions = false

    private let titleBar = TitleBar()
    private let summaryView = SubscriptionSummaryView()
    private let filterContainer = UIView()
    private lazy var filterSegmentedControl = UISegmentedControl(
        items: [
            String(localized: "Subscription"),
            String(localized: "Lifetime"),
        ]
    ).with {
        $0.selectedSegmentIndex = Filter.subscription.rawValue
        $0.addTarget(self, action: #selector(handleFilterChanged), for: .valueChanged)
    }

    private let headerStack = UIStackView().with {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .fill
        $0.distribution = .fill
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped).with {
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .clear
        $0.contentInset = LayoutConstants.tableContentInset
        $0.estimatedRowHeight = 88
        $0.rowHeight = UITableView.automaticDimension
    }

    private let bottomFadeView = BottomFadeView().with {
        $0.isHidden = true
    }

    private var subscriptions: [Subscription] = []
    private var selectedFilter: Filter = .subscription

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .background

        titleBar.delegate = self

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SubscriptionListView.SubscriptionTableViewCell.self, forCellReuseIdentifier: SubscriptionListView.SubscriptionTableViewCell.reuseIdentifier)

        addSubview(headerStack)
        addSubview(tableView)
        addSubview(bottomFadeView)

        headerStack.addArrangedSubview(titleBar)
        headerStack.addArrangedSubview(summaryView)
        headerStack.addArrangedSubview(filterContainer)

        filterContainer.addSubview(filterSegmentedControl)
        EditSubscriptionSelectionStyler.configureSegmentedControl(filterSegmentedControl, cornerRadius: 12)
        EditSubscriptionSelectionStyler.applySegmentedStyle(
            to: filterSegmentedControl,
            reduceTransparencyActive: UIAccessibility.isReduceTransparencyEnabled
        )

        filterSegmentedControl.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LayoutConstants.filterContentInset)
            make.leading.equalTo(tableView.layoutMarginsGuide.snp.leading).offset(LayoutConstants.rowCardHorizontalInset)
            make.trailing.equalTo(tableView.layoutMarginsGuide.snp.trailing).offset(-LayoutConstants.rowCardHorizontalInset)
            make.height.equalTo(LayoutConstants.filterHeight)
        }

        titleBar.snp.makeConstraints { make in
            make.height.equalTo(LayoutConstants.titleBarHeight)
        }

        summaryView.isHidden = true

        headerStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        bottomFadeView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(LayoutConstants.bottomFadeHeight)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func updateSubscriptions(_ subscriptions: [Subscription]) {
        self.subscriptions = subscriptions
        tableView.reloadData()
        updateEmptyState()
    }

    func updateEmptyState() {
        if subscriptions.isEmpty {
            tableView.backgroundView = EmptyStateView(model: emptyStateModel(for: selectedFilter))
        } else {
            tableView.backgroundView = nil
        }

        updateBottomFade()
    }

    func updateSummary(_ model: SubscriptionSummaryViewModel?) {
        summaryView.configure(with: model)
    }

    func updateFilter(_ filter: Filter) {
        guard filter != selectedFilter else { return }
        selectedFilter = filter
        filterSegmentedControl.selectedSegmentIndex = filter.rawValue
    }

    @objc private func handleFilterChanged(_ sender: UISegmentedControl) {
        tableView.setEditing(false, animated: true)

        guard let filter = Filter(rawValue: sender.selectedSegmentIndex) else {
            assertionFailure("Unexpected filter segment index \(sender.selectedSegmentIndex)")
            return
        }

        selectedFilter = filter
        delegate?.subscriptionListViewDidChangeFilter(self, filter: filter)
    }

    private func emptyStateModel(for filter: Filter) -> EmptyStateView.Model {
        switch filter {
        case .subscription:
            EmptyStateView.Model(
                systemImageName: "creditcard",
                title: String(localized: "No Subscriptions"),
                subtitle: String(localized: "Add your first subscription to get started")
            )
        case .lifetime:
            EmptyStateView.Model(
                systemImageName: "infinity.circle",
                title: String(localized: "No Lifetime Subscriptions"),
                subtitle: String(localized: "Add your first lifetime subscription to get started")
            )
        }
    }

    private func updateBottomFade() {
        let enabled = !subscriptions.isEmpty && !UIAccessibility.isReduceTransparencyEnabled
        bottomFadeView.isHidden = !enabled

        tableView.contentInset = LayoutConstants.tableContentInset

        if enabled {
            bottomFadeView.updateColors(baseColor: .background)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection == nil
            || traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)
        else {
            return
        }

        guard !bottomFadeView.isHidden else { return }
        bottomFadeView.updateColors(baseColor: .background)
    }
}

extension SubscriptionListView: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        subscriptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionListView.SubscriptionTableViewCell.reuseIdentifier, for: indexPath) as! SubscriptionListView.SubscriptionTableViewCell
        cell.configure(with: subscriptions[indexPath.row])
        return cell
    }
}

extension SubscriptionListView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let subscription = subscriptions[indexPath.row]
        delegate?.subscriptionListViewDidSelectSubscription(subscription)
    }

    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let subscription = subscriptions[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: String(localized: "Delete")) { [weak self] _, _, completionHandler in
            self?.delegate?.subscriptionListViewDidRequestDelete(subscription)
            completionHandler(true)
        }

        deleteAction.backgroundColor = .systemRed

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }

    func tableView(_: UITableView, willBeginEditingRowAt _: IndexPath) {
        isShowingSwipeActions = true
    }

    func tableView(_: UITableView, didEndEditingRowAt _: IndexPath?) {
        isShowingSwipeActions = false
    }
}

extension SubscriptionListView: TitleBarDelegate {
    func titleBarDidTapAddButton() {
        delegate?.subscriptionListViewDidTapAddButton()
    }

    func titleBarDidRequestSettings(_: SubscriptionListView.TitleBar) {
        delegate?.subscriptionListViewDidRequestSettings(self)
    }
}

extension SubscriptionListView {
    final class TitleBar: UIView {
        weak var delegate: TitleBarDelegate?

        private let settingsButton = NewSubButton(
            systemImageName: "gearshape",
            accessibilityLabel: String(localized: "Setting")
        )
        private let addButton = NewSubButton()

        init() {
            super.init(frame: .zero)
            backgroundColor = .background

            settingsButton.delegate = self
            addButton.delegate = self

            addSubview(settingsButton)
            addSubview(addButton)

            settingsButton.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(20)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(LayoutConstants.titleBarButtonSize)
            }

            addButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-20)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(LayoutConstants.titleBarButtonSize)
            }
        }

        private func requestSettings() {
            delegate?.titleBarDidRequestSettings(self)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }
    }
}

extension SubscriptionListView.TitleBar: NewSubButtonDelegate {
    func newSubButtonTapped(_ button: NewSubButton) {
        if button === addButton {
            delegate?.titleBarDidTapAddButton()
        } else if button === settingsButton {
            requestSettings()
        }
    }
}

extension SubscriptionListView {
    final class BottomFadeView: UIView {
        override class var layerClass: AnyClass { CAGradientLayer.self }

        private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear

            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            gradientLayer.locations = [0, 1]
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        func updateColors(baseColor: UIColor) {
            let resolved = baseColor.resolvedColor(with: traitCollection)
            gradientLayer.colors = [
                resolved.withAlphaComponent(0.0).cgColor,
                resolved.withAlphaComponent(1.0).cgColor,
            ]
        }
    }
}
