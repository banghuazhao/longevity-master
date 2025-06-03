//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SwiftData

@MainActor
class PreviewDataService {
    static let shared = PreviewDataService()

    let modelContainer: ModelContainer

    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private init() {
        do {
            modelContainer = try ModelContainer(
                for: Schema([Habit.self]),
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            addMockData()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private func addMockData() {
        for habit in HabitsDataStore.all {
            modelContext.insert(habit)
        }
    }
}
