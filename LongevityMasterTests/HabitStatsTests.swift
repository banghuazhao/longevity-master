//
// Created by Banghua Zhao on 17/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

/// "Now" is Saturday 2026-10-17 at noon, so the 30-day window opens on 2026-09-18.
@Suite("Habit stats")
struct HabitStatsTests {
    let calendar = testCalendar()
    let now = testDate("2026-10-17 12:00")

    private func habit(_ id: Int = 1, frequency: HabitFrequency = .fixedDaysInWeek, detail: String = "1,2,3,4,5,6,7") -> Habit {
        Habit(id: id, name: "Habit \(id)", frequency: frequency, frequencyDetail: detail)
    }

    private func checkIns(_ habitID: Int, _ days: [String]) -> [CheckIn] {
        days.enumerated().map { index, day in
            CheckIn(id: habitID * 1000 + index, date: testDate(day + " 09:00"), habitID: habitID)
        }
    }

    /// Every day from `first` through `last`, as "yyyy-MM-dd".
    private func days(from first: String, through last: String) -> [String] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        var result: [String] = []
        var day = testDate(first)
        while day <= testDate(last) {
            result.append(formatter.string(from: day))
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        return result
    }

    private func stats(
        _ habit: Habit,
        _ checkIns: [CheckIn],
        skippedDays: [SkippedDay] = []
    ) -> HabitStats {
        HabitStats.make(
            habit: habit,
            checkIns: checkIns,
            restDays: RestDays(skippedDays, in: calendar),
            now: now,
            calendar: calendar
        )
    }

    @Test("A habit never checked in has nothing to show, and no misses held against it")
    func neverCheckedIn() {
        let result = stats(habit(), [])
        #expect(result == HabitStats(currentStreak: 0, bestStreak: 0, totalCheckIns: 0, recentAdherence: nil, firstCheckIn: nil))
    }

    @Test("Streaks and totals count days, so a day checked in twice counts once")
    func streaksAndTotals() {
        let result = stats(
            habit(),
            checkIns(1, ["2026-10-01", "2026-10-02", "2026-10-03", "2026-10-10", "2026-10-15", "2026-10-16", "2026-10-16"])
        )
        #expect(result.currentStreak == 2)
        #expect(result.bestStreak == 3)
        #expect(result.totalCheckIns == 6)
        #expect(result.firstCheckIn == testDate("2026-10-01 09:00"))
    }

    @Test("Other habits' check-ins are not counted")
    func ignoresOtherHabits() {
        let result = stats(habit(1), checkIns(1, ["2026-10-16"]) + checkIns(2, ["2026-10-15", "2026-10-14"]))
        #expect(result.totalCheckIns == 1)
        #expect(result.currentStreak == 1)
    }

    @Test("A daily habit done every day of the window is fully on track")
    func dailyFullyOnTrack() {
        let result = stats(habit(), checkIns(1, days(from: "2026-09-01", through: "2026-10-16")))
        #expect(result.recentAdherencePercent == 100)
    }

    @Test("Only the last 30 days count, and today only once it is done")
    func windowIsThirtyDays() {
        // Done every day before the window, then on 15 of the 29 settled days inside it.
        let before = days(from: "2026-08-01", through: "2026-09-17")
        let inside = Array(days(from: "2026-09-18", through: "2026-10-16").prefix(15))
        let result = stats(habit(), checkIns(1, before + inside))
        #expect(result.recentAdherencePercent == Int((15.0 / 29.0 * 100).rounded()))
    }

    @Test("A habit begun inside the window is judged from its first check-in")
    func newHabitJudgedFromFirstCheckIn() {
        let result = stats(habit(), checkIns(1, ["2026-10-13", "2026-10-14", "2026-10-15", "2026-10-16"]))
        #expect(result.recentAdherencePercent == 100)
    }

    @Test("Rest days owe nothing")
    func restDaysOweNothing() {
        let rest = [
            SkippedDay(id: 1, date: testDate("2026-10-14 12:00"), habitID: nil),
            SkippedDay(id: 2, date: testDate("2026-10-15 12:00"), habitID: 1),
        ]
        let result = stats(habit(), checkIns(1, ["2026-10-12", "2026-10-13", "2026-10-16"]), skippedDays: rest)
        #expect(result.recentAdherencePercent == 100)
        // The rest days bridge the run rather than ending it.
        #expect(result.currentStreak == 3)
    }

    @Test("A quota habit owes its quota spread across the week")
    func quotaHabit() {
        // Three a week; begun on Monday 2026-10-12, so five settled days owe 15/7 check-ins.
        let result = stats(
            habit(frequency: .nDaysEachWeek, detail: "3"),
            checkIns(1, ["2026-10-12", "2026-10-14"])
        )
        #expect(result.recentAdherencePercent == Int((2.0 / (15.0 / 7.0) * 100).rounded()))
    }

    @Test("Doing today counts towards it; not doing it yet does not count against")
    func todayOnlyHelps() {
        let done = stats(habit(), checkIns(1, ["2026-10-17"]))
        #expect(done.recentAdherencePercent == 100)
        #expect(done.currentStreak == 1)

        let twoDays = stats(habit(), checkIns(1, ["2026-10-16"]))
        #expect(twoDays.recentAdherencePercent == 100)
    }

    @Test("A check-in dated in the future does not break the figures")
    func futureCheckIn() {
        let result = stats(habit(), checkIns(1, ["2026-10-20"]))
        #expect(result.recentAdherence == nil)
        #expect(result.totalCheckIns == 1)
    }
}
