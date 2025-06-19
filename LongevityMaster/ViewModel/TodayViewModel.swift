//
// Created by Banghua Zhao on 06/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Observation
import SharingGRDB
import SwiftUI

@Observable
@MainActor
class TodayViewModel {
    var todayHabits: [TodayHabit] = []
    
    var selectedDate: Date = Date()

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var dataBase

    @ObservationIgnored
    @Dependency(\.calendar) var calendar

    func updateQuery() async {
        let allTodayHabits = FetchAll(
            Habit
                .group(by: \.id)
                .leftJoin(CheckIn.all) {
                    $0.id.eq($1.habitID) &&
                        $1.date.between(
                            selectedDate.startOfDay(for: calendar),
                            and: selectedDate.endOfDay(for: calendar)
                        )
                }
                .select {
                    TodayHabit.Columns(
                        habit: $0,
                        isCompleted: $1.count() > 0
                    )
                },
            animation: .default
        )
        let allCheckIns = FetchAll(CheckIn.all, animation: .default)
        withAnimation {
            todayHabits = allTodayHabits.wrappedValue.filter { todayHabit in
                let habit = todayHabit.habit
                switch habit.frequency {
                case .fixedDaysInWeek:
                    // Day of the week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
                    let dayOfWeek = calendar.component(.weekday, from: selectedDate)
                    return habit.daysOfWeek.contains(dayOfWeek)
                case .fixedDaysInMonth:
                    // Get the day of the month (1–31)
                    let dayOfMonth = calendar.component(.day, from: selectedDate)
                    return habit.daysOfMonth.contains(dayOfMonth)
                case .nDaysEachWeek:
                    let startOfWeek = selectedDate.startOfWeek(for: calendar)
                    let endOfWeek = selectedDate.endOfWeek(for: calendar)
                    let checkInsThisWeek = allCheckIns.wrappedValue.filter { checkIn in
                        checkIn.habitID == habit.id &&
                        checkIn.date >= startOfWeek &&
                        checkIn.date <= endOfWeek
                    }
                    return habit.nDaysPerWeek > checkInsThisWeek.count || todayHabit.isCompleted
                case .nDaysEachMonth:
                    let startOfMonth = selectedDate.startOfMonth(for: calendar)
                    let endOfMonth = selectedDate.endOfMonth(for: calendar)
                    let checkInsThisMonth = allCheckIns.wrappedValue.filter { checkIn in
                        checkIn.habitID == habit.id &&
                        checkIn.date >= startOfMonth &&
                        checkIn.date <= endOfMonth
                    }
                    return habit.nDaysPerMonth > checkInsThisMonth.count || todayHabit.isCompleted
                }
            }
        }
    }

    func onChangeOfSelectedDate() async {
        await updateQuery()
    }

    func onTapHabitItem(_ todayHabit: TodayHabit) async {
        if todayHabit.isCompleted {
            withErrorReporting {
                try dataBase.write { db in
                    try CheckIn
                        .where { $0.habitID.eq(todayHabit.habit.id) }
                        .where {
                            $0.date.between(
                                selectedDate.startOfDay(for: calendar),
                                and: selectedDate.endOfDay(for: calendar)
                            )
                        }
                        .delete()
                        .execute(db)
                }
            }
        } else {
            withErrorReporting {
                try dataBase.write { db in
                    let checkIn = CheckIn.Draft(date: selectedDate, habitID: todayHabit.habit.id)
                    try CheckIn.upsert(checkIn)
                        .execute(db)
                }
            }
        }
        await updateQuery()
    }
}
