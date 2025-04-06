//
//  ContentView.swift
//  SubZen
//
//  Created by Star on 2025/3/29.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
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
                    Button(action: {
                        // Future action for adding a subscription
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
