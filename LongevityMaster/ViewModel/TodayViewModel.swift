//
// Created by Banghua Zhao on 06/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Observation
import SharingGRDB

@Observable
@MainActor
class TodayViewModel {
    @ObservationIgnored
    @FetchAll var habits: [Habit]

    @ObservationIgnored
    @FetchAll var checkIns: [CheckIn]

    var selectedDate: Date = Date()

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var dataBase

    @ObservationIgnored
    @Dependency(\.calendar) var calendar

    func isHabitCompleted(_ habit: Habit) -> Bool {
        checkIns.contains { checkIn in
            checkIn.habitID == habit.id &&
            calendar.isDate(checkIn.date, inSameDayAs: selectedDate)
        }
    }

    func onTapHabitItem(_ habit: Habit) {
        if isHabitCompleted(habit) {
            withErrorReporting {
                try dataBase.write { db in
                    let currentCheckIns = checkIns.filter { checkIn in
                        checkIn.habitID == habit.id &&
                        calendar.isDate(checkIn.date, inSameDayAs: selectedDate)
                    }
                    let ids = currentCheckIns.map(\.id)
                    try CheckIn
                        .where { $0.id.in(ids) }
                        .delete()
                        .execute(db)
                }
            }
        } else {
            withErrorReporting {
                try dataBase.write { db in
                    let checkIn = CheckIn.Draft(date: selectedDate, habitID: habit.id)
                    try CheckIn.upsert(checkIn)
                        .execute(db)
                }
            }
        }
    }
}
