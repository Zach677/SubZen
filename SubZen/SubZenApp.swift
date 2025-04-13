//
//  SubZenApp.swift
//  SubZen
//
//  Created by Star on 2025/3/29.
//

import SwiftUI
import SwiftData

@main
struct SubZenApp: App {
		var sharedModelContrainer: ModelContainer = {
				let schema = Schema([
						Subscription.self
				])
				let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
				
				do {
						return try ModelContainer(for: schema, configurations: [modelConfiguration])
				} catch {
						fatalError("Could not create ModelContrainer: \(error)")
				}
		}()
		
    var body: some Scene {
        WindowGroup {
						SubView()
        }
				.modelContainer(sharedModelContrainer)
    }
}
