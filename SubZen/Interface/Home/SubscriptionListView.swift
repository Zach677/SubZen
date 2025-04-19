//
//  SubView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import SwiftData
import SwiftUI

struct SubscriptionListView: View {
		@Environment(\.modelContext) private var modelContext
		
		@Query(sort: [SortDescriptor(\Subscription.dateAdded, order: .reverse)])
		private var subscriptions: [Subscription]
		
		@State private var subscriptionToEdit: Subscription?
		
		var body: some View {
				NavigationStack {
						VStack {
								if subscriptions.isEmpty {
										// Display empty state message
										ContentUnavailableView(
												"No Subscriptions",
												systemImage: "list.bullet.rectangle.portrait",
												description: Text(
														"Tap the + button to add your first subscription."
												)
										)
								} else {
										List {
												ForEach(subscriptions) { sub in
														SubscriptionRowView(
																subscription: sub,
																onEdit: {
																		print("ListView received onEdit for \(sub.name)")
																		subscriptionToEdit = sub
																},
																onDelete: {
																		print("ListView received onDelete for \(sub.name)")
																		deleteSubscription(sub)
																}
														)
												}
										}
								}
						}
						.navigationTitle("All Subscriptions")
						.toolbar {
								ToolbarItem(placement: .topBarTrailing) {
										NavigationLink {
												AddSubView()
										} label: {
												Image(systemName: "plus")
										}
								}
						}
						.sheet(item: $subscriptionToEdit) { subscription in
								EditSubscriptionView(subscription: subscription)
						}
				}
		}
		private func deleteSubscription(_ subscription: Subscription) {
				print("Executing delete for \(subscription.name)")
				modelContext.delete(subscription)
		}
}
