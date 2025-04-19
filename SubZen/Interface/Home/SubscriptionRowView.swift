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

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(subscription.name)
          .font(.headline)
        Text("/ \(subscription.cycle)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text(
        subscription.price,
        format: .currency(
						code: subscription.currencyCode
        )
      )
      .font(.headline)
      .foregroundColor(.accentColor)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 4)
    .contentShape(Rectangle())
			
		.contextMenu {
				Button {
						print("编辑按钮点击 (来自 RowView) - 触发 onEdit")
						onEdit() // 调用编辑回调
				} label: {
						Label("Edit", systemImage: "pencil")
				}

				Button(role: .destructive) {
						print("删除按钮点击 (来自 RowView) - 触发 onDelete")
						onDelete() // 调用删除回调
				} label: {
						Label("Delete", systemImage: "trash")
				}
		}
  }
}
