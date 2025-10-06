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
}

protocol TitleBarDelegate: AnyObject {
    func titleBarDidTapAddButton()
    func titleBarDidRequestSettings(_ titleBar: SubscriptionListView.TitleBar)
}

class SubscriptionListView: UIView {
    weak var delegate: SubscriptionListViewDelegate?

    private let titleBar = TitleBar()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped).with {
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .clear
        $0.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        $0.estimatedRowHeight = 88
        $0.rowHeight = UITableView.automaticDimension
    }

    private var subscriptions: [Subscription] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .background

        titleBar.delegate = self

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SubscriptionListView.SubscriptionTableViewCell.self, forCellReuseIdentifier: SubscriptionListView.SubscriptionTableViewCell.reuseIdentifier)

        addSubview(titleBar)
        addSubview(tableView)

        titleBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(60)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
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
            tableView.backgroundView = EmptyStateView()
        } else {
            tableView.backgroundView = nil
        }
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

        private let titleLabel = UILabel().with {
            $0.text = String(
                localized: "subscriptions.titleBar.title",
                defaultValue: "SubZen",
                comment: "Title displayed at the top of the subscriptions list"
            )
            $0.font = UIFont.systemFont(ofSize: 25, weight: .bold)
            $0.textColor = .label
        }

        private let addButton = NewSubButton()

        init() {
            super.init(frame: .zero)
            backgroundColor = .background

            addButton.delegate = self

            addSubview(titleLabel)
            addSubview(addButton)

            titleLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(40)
                make.centerY.equalToSuperview()
            }

            addButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-20)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(50)
            }

            installTitleGestures()
        }

        private func installTitleGestures() {
            titleLabel.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTitleTap))
            titleLabel.addGestureRecognizer(tapGesture)
        }

        @objc private func handleTitleTap() {
            delegate?.titleBarDidRequestSettings(self)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }
    }
}

extension SubscriptionListView.TitleBar: NewSubButtonDelegate {
    func newSubButtonTapped() {
        delegate?.titleBarDidTapAddButton()
    }
}
