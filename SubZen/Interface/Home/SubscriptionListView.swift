//
//  SubView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import SwiftData
import SwiftUI

struct SubscriptionListView: View {
    @Query(sort: [SortDescriptor(\Subscription.dateAdded, order: .reverse)])
    private var subscriptions: [Subscription]

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
                            SubscriptionRowView(subscription: sub)
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
        }
    }
}
