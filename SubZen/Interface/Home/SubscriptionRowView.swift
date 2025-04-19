//
//  SubscriptionRowView.swift
//  SubZen
//
//  Created by Star on 2025/4/13.
//

import SwiftUI

struct SubscriptionRowView: View {
  let subscription: Subscription

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(subscription.name)
          .font(.headline)
        Text("/ \(subscription.Cycle)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text(
        subscription.price,
        format: .currency(
          code: Locale.current.currency?.identifier ?? "USD"
        )
      )
      .font(.headline)
      .foregroundColor(.accentColor)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 4)
    .contentShape(Rectangle())
  }
}
