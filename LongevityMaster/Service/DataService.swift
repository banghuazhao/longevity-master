//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftData

@MainActor
class DataService {
    static let shared = DataService()

    let modelContainer: ModelContainer

    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private init() {
        do {
            modelContainer = try ModelContainer(
                for: Schema([Habit.self]),
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
