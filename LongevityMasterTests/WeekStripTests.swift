//
// Created by Banghua Zhao on 23/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

/// The week strip on the Today tab rings each day by how much of it was done. These pin down
/// which week it shows and what each day counts.
@MainActor
@Suite("Today's week strip")
struct WeekStripTests {
    private let calendar = testCalendar()

    /// 2026-08-26 is a Wednesday.
    private let wednesday = testDate("2026-08-26 12:00")

    private func habit(id: Int, frequency: HabitFrequency = .fixedDaysInWeek, detail: String = "1,2,3,4,5,6,7") -> Habit {
        Habit(
            id: id,
            name: "Habit \(id)",
            category: .diet,
            frequency: frequency,
            frequencyDetail: detail,
            antiAgingRating: 3,
            icon: "🥑",
            color: 0,
            note: "",
            isFavorite: false,
            isArchived: false
        )
    }

    private func checkIn(_ id: Int, _ day: String, habitID: Int) -> CheckIn {
        CheckIn(id: id, date: testDate(day, calendar), habitID: habitID)
    }

    @Test("Shows seven days from the user's first day of the week")
    func weekStartsOnFirstWeekday() {
        let mondayFirst = TodayViewModel.weekProgress(
            containing: wednesday, habits: [], checkIns: [], skippedDays: [],
            calendar: calendar, now: wednesday
        )
        #expect(mondayFirst.count == 7)
        #expect(mondayFirst.first?.date == testDate("2026-08-24"))

        let sundayCalendar = testCalendar(startWeekOnMonday: false)
        let sundayFirst = TodayViewModel.weekProgress(
            containing: wednesday, habits: [], checkIns: [], skippedDays: [],
            calendar: sundayCalendar, now: wednesday
        )
        #expect(sundayFirst.first?.date == testDate("2026-08-23", sundayCalendar))
    }

    @Test("Counts what was due and what was done on each day")
    func countsDoneAndDue() {
        let daily = habit(id: 1)
        let mondaysOnly = habit(id: 2, detail: "2")
        let week = TodayViewModel.weekProgress(
            containing: wednesday,
            habits: [daily, mondaysOnly],
            checkIns: [
                checkIn(1, "2026-08-24 08:00", habitID: 1),
                checkIn(2, "2026-08-24 09:00", habitID: 2),
                checkIn(3, "2026-08-25 08:00", habitID: 1),
            ],
            skippedDays: [],
            calendar: calendar,
            now: wednesday
        )

        let monday = week[0]
        #expect(monday.due == 2)
        #expect(monday.done == 2)
        #expect(monday.isComplete)

        let tuesday = week[1]
        #expect(tuesday.due == 1)
        #expect(tuesday.done == 1)

        let today = week[2]
        #expect(today.due == 1)
        #expect(today.done == 0)
        #expect(today.fraction == 0)
        #expect(!today.isComplete)
    }

    @Test("Days still to come owe nothing")
    func futureDaysAreEmpty() {
        let week = TodayViewModel.weekProgress(
            containing: wednesday, habits: [habit(id: 1)], checkIns: [], skippedDays: [],
            calendar: calendar, now: wednesday
        )
        let thursday = week[3]
        #expect(thursday.isFuture)
        #expect(thursday.due == 0)
        #expect(!week[2].isFuture)
    }

    @Test("A day off from everything is marked, a day off from one habit is not")
    func restDaysAreMarked() {
        let week = TodayViewModel.weekProgress(
            containing: wednesday,
            habits: [habit(id: 1)],
            checkIns: [],
            skippedDays: [
                SkippedDay(id: 1, date: testDate("2026-08-24"), habitID: nil),
                SkippedDay(id: 2, date: testDate("2026-08-25"), habitID: 1),
            ],
            calendar: calendar,
            now: wednesday
        )
        #expect(week[0].isRestDay)
        #expect(!week[1].isRestDay)
    }

    @Test("A day with nothing due is never shown as finished")
    func nothingDueIsNotComplete() {
        let week = TodayViewModel.weekProgress(
            containing: wednesday, habits: [], checkIns: [], skippedDays: [],
            calendar: calendar, now: wednesday
        )
        #expect(week.allSatisfy { !$0.isComplete })
    }
}
