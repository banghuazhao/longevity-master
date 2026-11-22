//
// Created by Banghua Zhao on 22/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

@Suite("Insights")
struct InsightsTests {
    private let calendar = testCalendar()
    /// A Sunday evening; the window runs back to Monday 26 October.
    private let now = testDate("2026-11-22 20:00")

    private func habit(_ id: Int, _ name: String, category: HabitCategory = .diet) -> Habit {
        Habit(id: id, name: name, category: category)
    }

    private func checkIn(_ habitID: Int, _ date: String) -> CheckIn {
        CheckIn(id: Int.random(in: 1 ... 1_000_000), date: testDate(date), habitID: habitID)
    }

    private func make(_ habits: [Habit], _ checkIns: [CheckIn]) -> Insights {
        Insights.make(habits: habits, checkIns: checkIns, skippedDays: [], now: now, calendar: calendar)
    }

    @Test("Weekdays run in the user's week order and the busiest one is the best day")
    func weekdays() {
        let insights = make([habit(1, "Walk")], [
            checkIn(1, "2026-11-16 08:00"), // Monday
            checkIn(1, "2026-11-09 08:00"), // Monday
            checkIn(1, "2026-11-10 08:00"), // Tuesday
            checkIn(1, "2026-11-11 08:00"), // Wednesday
            checkIn(1, "2026-11-12 08:00"), // Thursday
            checkIn(1, "2026-11-13 08:00"), // Friday
        ])
        #expect(insights.weekdayCounts.map(\.weekday) == [2, 3, 4, 5, 6, 7, 1])
        #expect(insights.bestWeekday == 2)
        // Saturday comes first among the days with nothing.
        #expect(insights.quietestWeekday == 7)
        #expect(insights.totalCheckIns == 6)
        #expect(insights.activeDays == 6)
    }

    @Test("Check-ins older than four weeks are left out")
    func windowIsFourWeeks() {
        let insights = make([habit(1, "Walk")], [
            checkIn(1, "2026-10-25 08:00"),
            checkIn(1, "2026-10-26 08:00"),
        ])
        #expect(insights.totalCheckIns == 1)
        #expect(!insights.hasEnoughData)
    }

    @Test("The time of day most check-ins fall in, and its share")
    func timeOfDay() {
        let insights = make([habit(1, "Walk")], [
            checkIn(1, "2026-11-20 07:00"),
            checkIn(1, "2026-11-19 09:00"),
            checkIn(1, "2026-11-18 11:59"),
            checkIn(1, "2026-11-17 21:00"),
        ])
        #expect(insights.mainTimeOfDay == .morning)
        #expect(insights.mainTimeOfDayShare == 0.75)
    }

    @Test("This week against last week")
    func weekOverWeek() {
        let insights = make([habit(1, "Walk")], [
            checkIn(1, "2026-11-22 08:00"),
            checkIn(1, "2026-11-20 08:00"),
            checkIn(1, "2026-11-16 08:00"),
            checkIn(1, "2026-11-14 08:00"),
            checkIn(1, "2026-11-10 08:00"),
        ])
        #expect(insights.thisWeekCount == 3)
        #expect(insights.lastWeekCount == 2)
        #expect(insights.weekOverWeekChange == 0.5)
    }

    @Test("The steadiest habit and the one slipping are told apart")
    func consistency() {
        let days = (0 ..< 14).map { calendar.date(byAdding: .day, value: -$0, to: now)! }
        var checkIns = days.map { CheckIn(id: Int.random(in: 1 ... 1_000_000), date: $0, habitID: 1) }
        // The second habit was done on its first day and twice since, out of 14.
        checkIns += [days[13], days[6], days[0]].map {
            CheckIn(id: Int.random(in: 1 ... 1_000_000), date: $0, habitID: 2)
        }
        let insights = make([habit(1, "Sleep", category: .sleep), habit(2, "Stretch", category: .exercise)], checkIns)
        #expect(insights.mostConsistent?.name == "Sleep")
        #expect(insights.mostConsistent?.adherence == 1)
        #expect(insights.needsAttention?.name == "Stretch")
        #expect(insights.topCategory == .sleep)
    }

    @Test("One habit doing well is not also the one needing attention")
    func singleHabit() {
        let days = (0 ..< 7).map { calendar.date(byAdding: .day, value: -$0, to: now)! }
        let checkIns = days.map { CheckIn(id: Int.random(in: 1 ... 1_000_000), date: $0, habitID: 1) }
        let insights = make([habit(1, "Sleep")], checkIns)
        #expect(insights.mostConsistent?.name == "Sleep")
        #expect(insights.needsAttention == nil)
    }
}
