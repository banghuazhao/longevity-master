//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var habits: [Habit]

    private let currentDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 3))!
    private let calendar = Calendar.current

    private var todayHabits: [Habit] {
        habits.filter { habit in
            switch habit.frequency {
            case let .nDaysEachWeek(days):
                return days >= 7 // Daily habits
            case let .fixedDaysInWeek(days):
                let weekday = calendar.component(.weekday, from: currentDate) // 2 = Tuesday
                return days.contains(weekday)
            default:
                return false
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .zero) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.headline)
                        Text("\(formattedDate())")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    ForEach(HabitCategory.allCases, id: \.rawValue) { category in
                        let habits = todayHabits.filter { $0.category == category }
                        if !habits.isEmpty {
                            HStack {
                                Spacer()
                                Text(category.rawValue)
                                Spacer()
                            }
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                                ForEach(habits) { habit in
                                    HabitIconButton(habit: habit)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Action to add new habit
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: currentDate)
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewDataService.shared.modelContainer)
}
