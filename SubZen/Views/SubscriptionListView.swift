//
//  SubView.swift
//  SubZen
//
//  Created by Star on 2025/4/6.
//

import SwiftData  // Import SwiftData
import SwiftUI

struct SubscriptionListView: View {
    // Query to fetch subscriptions, sorted by date added (newest first)
    @Query(sort: [SortDescriptor(\Subscription.dateAdded, order: .reverse)])
    private var subscriptions: [Subscription]

    // Environment access for deleting (if needed later)
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack {  // Keep VStack for potential future elements outside the list
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
                    // Display the list of subscriptions
                    List {
                        ForEach(subscriptions) { sub in  // Iterate over fetched subscriptions
                            SubscriptionRowView(subscription: sub)  // Use the dedicated row view
                        }
                        // Add onDelete modifier if you want swipe-to-delete functionality
                        // .onDelete(perform: deleteSubscriptions)
                    }
                    // Optional: Apply list styles if desired
                    // .listStyle(.plain)
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
                // Optional: Add an EditButton if you implement onDelete
                // ToolbarItem(placement: .navigationBarLeading) {
                //     EditButton()
                // }
            }
        }
    }

    // Function to handle deletion (uncomment .onDelete above to use)
    /*
    private func deleteSubscriptions(offsets: IndexSet) {
    		withAnimation {
    				offsets.map { subscriptions[$0] }.forEach(modelContext.delete)
    				// SwiftData typically saves automatically after delete, but you can add explicit save here if needed
    				// do {
    				//     try modelContext.save()
    				// } catch {
    				//     print("Error saving after delete: \(error)")
    				// }
    		}
    }
    */
}

#Preview {
    // Preview needs the model container and potentially some sample data
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Subscription.self,
            configurations: config
        )

        // Add sample data for preview
        let sampleSub1 = Subscription(
            name: "Streamify",
            price: 9.99,
            Cycle: "Monthly",
            dateAdded: Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: .now
            )!
        )
        let sampleSub2 = Subscription(
            name: "CloudDrive Pro",
            price: 119.99,
            Cycle: "Yearly",
            dateAdded: .now
        )
        container.mainContext.insert(sampleSub1)
        container.mainContext.insert(sampleSub2)

        return SubscriptionListView()
            .modelContainer(container)  // Provide the container to the preview
    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}
