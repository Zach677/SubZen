//
//  SubView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import SwiftUI

struct SubView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("No subscriptions available")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Spacer()
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

#Preview {
    SubView()
}
