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
        let mockHabits = [
            Habit(
                name: "Morning Run",
                category: .exercise,
                frequency: .nDaysEachWeek(3),
                antiAgingRating: 4,
                icon: "🏃‍♂️",
                color: "green",
                note: "Stay active!",
                completionDates: []
            ),
            Habit(
                name: "Meditate",
                category: .mentalHealth,
                frequency: .fixedDaysInWeek([1, 3, 5]),
                antiAgingRating: 3,
                icon: "🧘",
                color: "purple",
                note: "Find peace daily",
                completionDates: [Date().addingTimeInterval(-86400)]
            ),
            Habit(
                name: "Healthy Breakfast",
                category: .diet,
                frequency: .nDaysEachMonth(20),
                antiAgingRating: 2,
                icon: "🥑",
                color: "teal",
                note: "Start the day right!",
                completionDates: []
            ),
        ]

        for habit in mockHabits {
            modelContext.insert(habit)
        }
    }
}
