//
//  SubscriptionRowView.swift
//  SubZen
//
//  Created by Star on 2025/4/13.
//

import SwiftUI

struct SubscriptionRowView: View {
    let subscription: Subscription

    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Last billed: \(dateFormatter.string(from: subscription.lastBillingDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text(
                        subscription.price,
                        format: .currency(
                            code: subscription.currencyCode
                        )
                    )
                    .font(.headline)
                    .foregroundColor(.primary)
                    Text("/ \(subscription.cycle)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("\(subscription.remainingDays) days lefts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
