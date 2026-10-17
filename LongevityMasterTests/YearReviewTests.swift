//
// Created by Banghua Zhao on 17/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

/// "Now" is Saturday 2026-10-17 at noon, the 290th day of 2026. 2026-02-02 is a Monday.
@Suite("Year in review")
struct YearReviewTests {
    let calendar = testCalendar()
    let now = "2026-10-17 12:00"

    private func habit(_ id: Int, category: HabitCategory = .diet, isArchived: Bool = false) -> Habit {
        Habit(id: id, name: "Habit \(id)", category: category, isArchived: isArchived)
    }

    private func checkIns(_ habitID: Int, _ days: [String]) -> [CheckIn] {
        days.enumerated().map { index, day in
            CheckIn(id: habitID * 1000 + index, date: testDate(day + " 09:00"), habitID: habitID)
        }
    }

    private func restDay(_ id: Int, _ day: String, habitID: Int? = nil) -> SkippedDay {
        SkippedDay(id: id, date: testDate(day + " 12:00"), habitID: habitID)
    }

    private func review(
        _ year: Int = 2026,
        now: String? = nil,
        habits: [Habit],
        checkIns: [CheckIn],
        skippedDays: [SkippedDay] = [],
        calendar: Calendar? = nil
    ) -> YearReview {
        YearReview.make(
            year: year,
            now: testDate(now ?? self.now),
            habits: habits,
            checkIns: checkIns,
            skippedDays: skippedDays,
            calendar: calendar ?? self.calendar
        )
    }

    @Test("Counts days checked in per habit, inside the year and up to today only")
    func countsInsideTheYear() {
        let result = review(
            habits: [habit(1), habit(2)],
            checkIns: checkIns(1, ["2025-12-31", "2026-01-01", "2026-01-01", "2026-03-05"])
                + checkIns(2, ["2026-03-05", "2026-10-20"])
        )
        #expect(result.yearStart == testDate("2026-01-01"))
        #expect(result.yearEnd == testDate("2026-12-31"))
        #expect(result.isCurrentYear)
        #expect(result.dayCount == 290)
        #expect(result.checkInCount == 3)
        #expect(result.activeDayCount == 2)
        #expect(result.months.count == 12)
        #expect(result.months.map(\.checkIns) == [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        #expect(result.months[0].month == testDate("2026-01-01"))
        #expect(!result.isEmpty)
    }

    @Test("A year that is over counts every one of its days")
    func pastYears() {
        let past = review(2025, habits: [habit(1)], checkIns: checkIns(1, ["2024-12-31", "2025-06-01"]))
        #expect(!past.isCurrentYear)
        #expect(past.dayCount == 365)
        #expect(past.checkInCount == 1)

        let leap = review(2024, habits: [habit(1)], checkIns: [])
        #expect(leap.dayCount == 366)
        #expect(leap.isEmpty)
    }

    @Test("A year the user began part-way through is counted from their first check-in")
    func countedFromFirstCheckIn() {
        // Every day from 2025-11-10 to the end of the year: 52 days.
        let days = (0..<52).map { calendar.date(byAdding: .day, value: $0, to: testDate("2025-11-10 09:00"))! }
        let result = review(
            2025,
            habits: [habit(1)],
            checkIns: days.enumerated().map { CheckIn(id: $0.offset, date: $0.element, habitID: 1) }
        )
        #expect(result.dayCount == 52)
        #expect(result.activeDayPercent == 100)

        // The next year starts from January 1 as usual.
        let next = review(2026, habits: [habit(1)], checkIns: checkIns(1, ["2025-11-10", "2026-02-02"]))
        #expect(next.dayCount == 290)
    }

    @Test("A year still to come has nothing in it, rather than a share of nothing")
    func futureYear() {
        let result = review(2027, habits: [habit(1)], checkIns: checkIns(1, ["2026-10-16"]))
        #expect(result.dayCount == 0)
        #expect(result.isEmpty)
        #expect(result.activeDayShare == nil)
        #expect(result.bestMonth == nil)
        #expect(result.busiestWeekday == nil)
    }

    @Test("Habits come busiest first, and archived ones still count")
    func habitOrder() {
        let result = review(
            habits: [habit(1), habit(2, isArchived: true), habit(3), habit(4)],
            checkIns: checkIns(1, ["2026-02-02", "2026-02-03", "2026-02-04"])
                + checkIns(2, ["2026-02-02", "2026-02-03", "2026-02-04", "2026-02-05", "2026-02-06"])
                + checkIns(3, ["2026-03-02", "2026-03-03", "2026-03-04"])
        )
        #expect(result.habits.map(\.habit.id) == [2, 1, 3])
        #expect(result.habits.map(\.checkIns) == [5, 3, 3])
        #expect(result.checkInCount == 11)
    }

    @Test("A check-in for a habit that no longer exists is not counted")
    func ignoresOrphans() {
        let result = review(habits: [habit(1)], checkIns: checkIns(1, ["2026-02-02"]) + checkIns(9, ["2026-02-03"]))
        #expect(result.checkInCount == 1)
        #expect(result.activeDayCount == 1)
    }

    @Test("The longest streak is bridged by days off, and stops at the year's edge")
    func longestStreak() {
        let bridged = review(
            habits: [habit(1)],
            checkIns: checkIns(1, ["2026-02-01", "2026-02-02", "2026-02-04", "2026-02-05"]),
            skippedDays: [restDay(1, "2026-02-03")]
        )
        #expect(bridged.longestStreak == 4)

        let acrossNewYear = review(
            habits: [habit(1)],
            checkIns: checkIns(1, ["2025-12-29", "2025-12-30", "2025-12-31", "2026-01-01", "2026-01-02"])
        )
        #expect(acrossNewYear.longestStreak == 2)
    }

    @Test("Rest days count days off from everything, already taken, in this year")
    func restDays() {
        let result = review(
            habits: [habit(1)],
            checkIns: checkIns(1, ["2026-02-02"]),
            skippedDays: [
                restDay(1, "2025-12-25"),
                restDay(2, "2026-02-03"),
                restDay(3, "2026-02-04"),
                restDay(4, "2026-02-05", habitID: 1),
                restDay(5, "2026-12-24"),
            ]
        )
        #expect(result.restDayCount == 2)
    }

    @Test("The busiest weekday breaks ties by the order the user's week runs in")
    func busiestWeekday() {
        // Two Sundays and two Mondays.
        let days = ["2026-02-01", "2026-02-08", "2026-02-02", "2026-02-09"]

        let mondayFirst = review(habits: [habit(1)], checkIns: checkIns(1, days))
        #expect(mondayFirst.busiestWeekday?.weekday == 2)
        #expect(mondayFirst.busiestWeekday?.checkIns == 2)

        let sundayFirst = review(
            habits: [habit(1)],
            checkIns: checkIns(1, days),
            calendar: testCalendar(startWeekOnMonday: false)
        )
        #expect(sundayFirst.busiestWeekday?.weekday == 1)

        let clearWinner = review(habits: [habit(1)], checkIns: checkIns(1, days + ["2026-02-16"]))
        #expect(clearWinner.busiestWeekday?.weekday == 2)
        #expect(clearWinner.busiestWeekday?.checkIns == 3)
    }

    @Test("Categories come busiest first")
    func categories() {
        let result = review(
            habits: [habit(1, category: .sleep), habit(2, category: .exercise), habit(3, category: .exercise)],
            checkIns: checkIns(1, ["2026-02-02", "2026-02-03"])
                + checkIns(2, ["2026-02-02", "2026-02-03"])
                + checkIns(3, ["2026-02-04"])
        )
        #expect(result.categories.map(\.category) == [.exercise, .sleep])
        #expect(result.categories.map(\.checkIns) == [3, 2])
    }

    @Test("The best month is the busiest, and the earlier of two that tie")
    func bestMonth() {
        let result = review(
            habits: [habit(1)],
            checkIns: checkIns(1, ["2026-03-01", "2026-03-02", "2026-05-01", "2026-05-02", "2026-07-01"])
        )
        #expect(result.bestMonth?.month == testDate("2026-03-01"))
        #expect(result.bestMonth?.checkIns == 2)
    }

    @Test("A habit is new to the year its first check-in ever fell in")
    func newHabits() {
        let result = review(
            habits: [habit(1), habit(2), habit(3)],
            checkIns: checkIns(1, ["2025-11-01", "2026-02-02"]) + checkIns(2, ["2026-04-01"])
        )
        #expect(result.newHabitCount == 1)

        let lastYear = review(2025, habits: [habit(1), habit(2), habit(3)], checkIns: checkIns(1, ["2025-11-01"]))
        #expect(lastYear.newHabitCount == 1)
    }

    @Test("The verdict follows the share of days with a check-in")
    func verdict() {
        // 290 days so far; 232 of them is 80%.
        let busyDays = (0..<232).map { calendar.date(byAdding: .day, value: $0, to: testDate("2026-01-01 09:00"))! }
        let busy = review(
            habits: [habit(1)],
            checkIns: busyDays.enumerated().map { CheckIn(id: $0.offset, date: $0.element, habitID: 1) }
        )
        #expect(busy.activeDayPercent == 80)
        #expect(busy.verdict == String(localized: "Outstanding. Healthy habits are part of who you are now."))

        let quiet = review(habits: [habit(1)], checkIns: checkIns(1, ["2026-02-02"]))
        #expect(quiet.verdict == String(localized: "Every check-in counts. Keep showing up."))
    }

    @Test("January looks back on last year, once there is a last year to look back on")
    func defaultYear() {
        #expect(YearReview.defaultYear(now: testDate("2026-10-17"), earliestCheckIn: testDate("2025-03-01"), calendar: calendar) == 2026)
        #expect(YearReview.defaultYear(now: testDate("2027-01-10"), earliestCheckIn: testDate("2026-03-01"), calendar: calendar) == 2026)
        #expect(YearReview.defaultYear(now: testDate("2027-01-10"), earliestCheckIn: testDate("2027-01-02"), calendar: calendar) == 2027)
        #expect(YearReview.defaultYear(now: testDate("2027-01-10"), earliestCheckIn: nil, calendar: calendar) == 2027)
        #expect(YearReview.defaultYear(now: testDate("2027-02-01"), earliestCheckIn: testDate("2026-03-01"), calendar: calendar) == 2027)
    }

    @Test("Years run from the first check-in through this one")
    func availableYears() {
        let today = testDate(self.now)
        #expect(YearReview.availableYears(earliestCheckIn: testDate("2024-06-01"), now: today, calendar: calendar) == 2024...2026)
        #expect(YearReview.availableYears(earliestCheckIn: nil, now: today, calendar: calendar) == 2026...2026)
        // A clock that went backwards must not make an empty range.
        #expect(YearReview.availableYears(earliestCheckIn: testDate("2027-06-01"), now: today, calendar: calendar) == 2026...2026)
    }

    @Test("The review's calendar is Gregorian whatever the device uses, and keeps the user's week")
    func gregorianCalendar() {
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = TimeZone(identifier: "Asia/Bangkok")!
        buddhist.firstWeekday = 1

        let result = YearReview.calendar(from: buddhist)
        #expect(result.identifier == .gregorian)
        #expect(result.timeZone == buddhist.timeZone)
        #expect(result.firstWeekday == 1)
        #expect(result.component(.year, from: testDate("2026-10-17")) == 2026)
    }
}
