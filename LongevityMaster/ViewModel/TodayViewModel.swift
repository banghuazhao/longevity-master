//
// Created by Banghua Zhao on 06/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Observation
import SharingGRDB

@Selection
struct TodayHabit {
    let habit: Habit
    let isCompleted: Bool
}

@Observable
@MainActor
class TodayViewModel {
    @ObservationIgnored
    @FetchAll var todayHabits: [TodayHabit]

    var selectedDate: Date = Date()

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var dataBase

    @ObservationIgnored
    @Dependency(\.calendar) var calendar

    init() {
        _todayHabits = FetchAll(
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
    }

    func updateQuery() async {
        await withErrorReporting {
            try await $todayHabits.load(
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
