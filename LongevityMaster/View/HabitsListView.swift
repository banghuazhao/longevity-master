//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftData
import SwiftUI

struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(habits) { habit in
                    HabitCardView(
                        habit: habit,
                        onTapMore: {}
                    )
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
}

struct HabitsListView_Previews {
    @MainActor
    static var mockContainer: ModelContainer {
        let container = try! ModelContainer(for: Habit.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockHabits = [
            Habit(
                name: "Morning Run",
                category: .exercise,
                frequency: .nDaysEachWeek(3),
                icon: "🏃‍♂️",
                color: "green",
                note: "Stay active!",
                antiAgingRating: 4,
                completionDates: [],
                isCompleted: false
            ),
            Habit(
                name: "Meditate",
                category: .mentalHealth,
                frequency: .fixedDaysInWeek([1, 3, 5]),
                icon: "🧘",
                color: "purple",
                note: "Find peace daily",
                antiAgingRating: 3,
                completionDates: [Date().addingTimeInterval(-86400)],
                isCompleted: true
            ),
            Habit(
                name: "Healthy Breakfast",
                category: .diet,
                frequency: .nDaysEachMonth(20),
                icon: "🥑",
                color: "teal",
                note: "Start the day right!",
                antiAgingRating: 2,
                completionDates: [],
                isCompleted: false
            )
        ]

        for habit in mockHabits {
            context.insert(habit)
        }

        return container
    }
}

#Preview {
    HabitsListView()
        .modelContainer(HabitsListView_Previews.mockContainer)
}
