//
// Created by Banghua Zhao on 25/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

/// The streak helpers back four screens — the Today tab, a habit's detail, My Stats and the
/// score breakdown — which used to disagree with each other about what a streak was.
@Suite("Streaks over days")
struct CalendarStreakTests {
    private let calendar = testCalendar()

    // MARK: - consecutiveDays

    @Test("Counts back from the given day and stops at the first gap")
    func consecutiveDaysStopsAtGap() {
        let days = testDays(["2026-08-25", "2026-08-24", "2026-08-23", "2026-08-21"])
        #expect(calendar.consecutiveDays(endingAt: testDate("2026-08-25"), within: days, upTo: 10) == 3)
    }

    @Test("Stops at the limit rather than walking the whole history")
    func consecutiveDaysHonoursLimit() {
        let days = testDays((1 ... 30).map { String(format: "2026-08-%02d", $0) })
        #expect(calendar.consecutiveDays(endingAt: testDate("2026-08-30"), within: days, upTo: 5) == 5)
    }

    @Test("A day with no check-in has no streak ending on it")
    func consecutiveDaysFromAnEmptyDay() {
        let days = testDays(["2026-08-24", "2026-08-23"])
        #expect(calendar.consecutiveDays(endingAt: testDate("2026-08-25"), within: days, upTo: 10) == 0)
    }

    @Test("The time of day the check-in was made does not matter")
    func consecutiveDaysIgnoresTimeOfDay() {
        let days = testDays(["2026-08-25", "2026-08-24"])
        #expect(calendar.consecutiveDays(endingAt: testDate("2026-08-25 23:59"), within: days, upTo: 10) == 2)
    }

    // MARK: - currentDayStreak

    @Test("Counts today when today is already checked in")
    func currentStreakIncludesToday() {
        let days = testDays(["2026-08-25", "2026-08-24", "2026-08-23"])
        #expect(calendar.currentDayStreak(in: days, asOf: testDate("2026-08-25 09:00")) == 3)
    }

    @Test("A streak is not broken while today's check-in is still outstanding")
    func currentStreakSurvivesAPendingToday() {
        let days = testDays(["2026-08-24", "2026-08-23", "2026-08-22"])
        #expect(calendar.currentDayStreak(in: days, asOf: testDate("2026-08-25 09:00")) == 3)
    }

    @Test("Missing both yesterday and today does break it")
    func currentStreakBreaksAfterAMissedDay() {
        let days = testDays(["2026-08-23", "2026-08-22"])
        #expect(calendar.currentDayStreak(in: days, asOf: testDate("2026-08-25 09:00")) == 0)
    }

    @Test("A run that ended weeks ago is not the current streak")
    func currentStreakIgnoresAnOldRun() {
        let days = testDays(["2026-07-01", "2026-07-02", "2026-07-03", "2026-07-04"])
        #expect(calendar.currentDayStreak(in: days, asOf: testDate("2026-08-25 09:00")) == 0)
    }

    @Test("No check-ins at all is a streak of zero, not a crash")
    func currentStreakOfNothing() {
        #expect(calendar.currentDayStreak(in: [], asOf: testDate("2026-08-25")) == 0)
    }

    @Test("A check-in dated in the future does not extend today's streak")
    func currentStreakIgnoresFutureDays() {
        let days = testDays(["2026-08-30", "2026-08-25", "2026-08-24"])
        #expect(calendar.currentDayStreak(in: days, asOf: testDate("2026-08-25 09:00")) == 2)
    }

    // MARK: - dayStreakLengths and longestDayStreak

    @Test("Reports each run of consecutive days, oldest first")
    func streakLengthsInOrder() {
        let days = testDays([
            "2026-08-01",
            "2026-08-05", "2026-08-06", "2026-08-07",
            "2026-08-20", "2026-08-21",
        ])
        #expect(calendar.dayStreakLengths(in: days) == [1, 3, 2])
    }

    @Test("The longest streak is the longest run, not the last or the first")
    func longestStreakPicksTheBiggestRun() {
        let days = testDays([
            "2026-08-01",
            "2026-08-05", "2026-08-06", "2026-08-07",
            "2026-08-20", "2026-08-21",
        ])
        #expect(calendar.longestDayStreak(in: days) == 3)
    }

    @Test("One day is a streak of one")
    func longestStreakOfASingleDay() {
        #expect(calendar.longestDayStreak(in: testDays(["2026-08-25"])) == 1)
    }

    @Test("No check-ins is a longest streak of zero")
    func longestStreakOfNothing() {
        #expect(calendar.longestDayStreak(in: []) == 0)
        #expect(calendar.dayStreakLengths(in: []).isEmpty)
    }

    @Test("Runs are counted across a month boundary")
    func streaksSpanMonths() {
        let days = testDays(["2026-07-30", "2026-07-31", "2026-08-01", "2026-08-02"])
        #expect(calendar.longestDayStreak(in: days) == 4)
    }

    @Test("Runs are counted across a leap day")
    func streaksSpanLeapDay() {
        let days = testDays(["2028-02-28", "2028-02-29", "2028-03-01"])
        #expect(calendar.longestDayStreak(in: days) == 3)
    }
}
