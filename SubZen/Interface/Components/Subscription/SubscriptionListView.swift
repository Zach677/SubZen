//
//  SubscriptionListView.swift
//  SubZen
//
//  Created by Star on 2025/8/9.
//

import UIKit
import SnapKit

protocol SubscriptionListViewDelegate: AnyObject {
		func subscriptionListViewDidSelectSubscription(_ subscription: Subscription)
}

class SubscriptionListView: UIView {
		
		weak var delegate: SubscriptionListViewDelegate?
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
				setupUI()
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) {
				fatalError()
		}
		
		private func setupUI() {
				backgroundColor = .systemGroupedBackground
				
				tableView.dataSource = self
				tableView.delegate = self
				tableView.register(SubscriptionListView.SubscriptionTableViewCell.self, forCellReuseIdentifier: "SubscriptionListView.SubscriptionTableViewCell.reuseIdentifier")
				
				addSubview(tableView)
				tableView.snp.makeConstraints { make in
						make.edges.equalToSuperview()
				}
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
		func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
				subscriptions.count
		}
		func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
				let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriptionTableViewCell.reuseIdentifier", for: indexPath) as! SubscriptionTableViewCell
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


