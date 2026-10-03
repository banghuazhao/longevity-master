//
// Created by Banghua Zhao on 03/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// How one week went: how much of what was due got done, which habits carried it, and which
/// ones slipped.
///
/// Each habit is judged by the same rules as a program (`ProgramProgress`) — a fixed-day habit
/// owes its days, a quota habit owes its quota spread across the week, rest days owe nothing,
/// and today only counts once it helps — so "on track" means the same thing on both screens.
struct WeeklyReview {
    struct HabitResult: Identifiable {
        let habit: Habit
        /// Days in the week the habit was checked in on.
        let done: Int
        let due: Double
        let credited: Double

        var id: Habit.ID { habit.id }

        /// `nil` when nothing fell due — a monthly habit in a week without one of its days.
        var adherence: Double? {
            due > 0 ? credited / due : nil
        }

        var adherencePercent: Int? {
            adherence.map { Int(($0 * 100).rounded()) }
        }
    }

    struct Day: Identifiable {
        let date: Date
        /// Habits checked in that day.
        let checkInCount: Int
        /// A day off from everything.
        let isRestDay: Bool
        /// Still ahead, in the week under way.
        let isFuture: Bool

        var id: Date { date }
    }

    let weekStart: Date
    /// The start of the week's last day.
    let weekEnd: Date
    /// The week has not finished yet, so its figures are "so far".
    let isCurrentWeek: Bool
    let days: [Day]
    /// Best first.
    let habits: [HabitResult]
    let adherence: Double?
    let previousAdherence: Double?

    var adherencePercent: Int? {
        adherence.map { Int(($0 * 100).rounded()) }
    }

    /// Percentage points up or down on the week before, when both weeks had anything due.
    var change: Int? {
        guard let adherence, let previousAdherence else { return nil }
        return Int(((adherence - previousAdherence) * 100).rounded())
    }

    var checkInCount: Int {
        days.reduce(0) { $0 + $1.checkInCount }
    }

    var activeDayCount: Int {
        days.filter { $0.checkInCount > 0 }.count
    }

    /// Habits that did everything they owed, the busiest first.
    var strongest: [HabitResult] {
        habits
            .filter { $0.due >= 1 && ($0.adherence ?? 0) >= 0.999 }
            .sorted { $0.done > $1.done }
            .prefix(3)
            .map { $0 }
    }

    /// Habits that kept less than 60% of what they owed, the furthest behind first. Anything
    /// owing less than a whole check-in is left out: missing a third of a check-in is not news.
    var needsAttention: [HabitResult] {
        habits
            .filter { $0.due >= 1 && ($0.adherence ?? 1) < 0.6 }
            .sorted { ($0.adherence ?? 0) < ($1.adherence ?? 0) }
            .prefix(3)
            .map { $0 }
    }

    /// One line on how the week went, in the reader's language.
    var verdict: String {
        guard let adherence else {
            return String(localized: "Nothing was due this week. Add a habit or two to get started.")
        }
        switch adherence {
        case 0.9...:
            return String(localized: "Outstanding week. This is what lasting change looks like.")
        case 0.7..<0.9:
            return String(localized: "Strong week. Keep the rhythm going.")
        case 0.4..<0.7:
            return String(localized: "A solid base. Protect one habit next week and build from there.")
        default:
            return String(localized: "Every week is a fresh start. Pick one small habit and begin there.")
        }
    }

    // MARK: - Working it out

    /// - Parameters:
    ///   - date: any day in the week to review.
    ///   - now: the present moment; days after it are not held against anyone.
    static func make(
        weekContaining date: Date,
        now: Date,
        habits: [Habit],
        checkIns: [CheckIn],
        skippedDays: [SkippedDay],
        calendar: Calendar
    ) -> WeeklyReview {
        let weekStart = date.startOfWeek(for: calendar)
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let todayStart = calendar.startOfDay(for: now)
        let activeHabits = habits.filter { !$0.isArchived }
        let activeIDs = Set(activeHabits.map(\.id))
        let checkInsByHabit = Dictionary(grouping: checkIns, by: \.habitID)
        let restDays = RestDays(skippedDays, in: calendar)

        let results = habitResults(
            weekStart: weekStart,
            weekEnd: weekEnd,
            now: now,
            habits: activeHabits,
            checkInsByHabit: checkInsByHabit,
            restDays: restDays,
            calendar: calendar
        )

        let previousStart = calendar.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
        let previousEnd = calendar.date(byAdding: .day, value: 6, to: previousStart) ?? previousStart
        let previous = habitResults(
            weekStart: previousStart,
            weekEnd: previousEnd,
            now: now,
            habits: activeHabits,
            checkInsByHabit: checkInsByHabit,
            restDays: restDays,
            calendar: calendar
        )

        var habitsByDay: [Date: Set<Habit.ID>] = [:]
        for checkIn in checkIns where activeIDs.contains(checkIn.habitID) {
            let day = calendar.startOfDay(for: checkIn.date)
            guard day >= weekStart, day <= weekEnd else { continue }
            habitsByDay[day, default: []].insert(checkIn.habitID)
        }
        let days = (0..<7).compactMap { offset -> Day? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            return Day(
                date: day,
                checkInCount: habitsByDay[day]?.count ?? 0,
                isRestDay: restDays.everyHabit.contains(day),
                isFuture: day > todayStart
            )
        }

        return WeeklyReview(
            weekStart: weekStart,
            weekEnd: weekEnd,
            isCurrentWeek: todayStart <= weekEnd,
            days: days,
            habits: results.sorted { ($0.adherence ?? -1, $0.done) > ($1.adherence ?? -1, $1.done) },
            adherence: combinedAdherence(results),
            previousAdherence: combinedAdherence(previous)
        )
    }

    /// Added up across habits rather than averaged, so a daily habit weighs seven times what a
    /// once-a-week one does.
    private static func combinedAdherence(_ results: [HabitResult]) -> Double? {
        let due = results.reduce(0) { $0 + $1.due }
        guard due > 0 else { return nil }
        return results.reduce(0) { $0 + $1.credited } / due
    }

    /// Habits have no creation date, so a habit's first check-in stands in for when it began:
    /// one first done on Thursday is judged from Thursday, not blamed for Monday to Wednesday.
    /// A habit never checked in at all is judged in the week under way only — otherwise paging
    /// back would show every new habit as missed in weeks before it existed.
    private static func habitResults(
        weekStart: Date,
        weekEnd: Date,
        now: Date,
        habits: [Habit],
        checkInsByHabit: [Habit.ID: [CheckIn]],
        restDays: RestDays,
        calendar: Calendar
    ) -> [HabitResult] {
        let todayStart = calendar.startOfDay(for: now)
        guard weekStart <= todayStart else { return [] }

        return habits.compactMap { habit in
            let habitCheckIns = checkInsByHabit[habit.id] ?? []
            let start: Date
            if let first = habitCheckIns.map(\.date).min() {
                let firstDay = calendar.startOfDay(for: first)
                guard firstDay <= weekEnd else { return nil }
                start = max(weekStart, firstDay)
            } else {
                guard todayStart <= weekEnd else { return nil }
                start = weekStart
            }
            let length = (calendar.dateComponents([.day], from: start, to: weekEnd).day ?? 0) + 1

            let progress = ProgramProgress.make(
                durationDays: length,
                startDate: start,
                today: now,
                habits: [habit],
                checkIns: habitCheckIns,
                restDays: restDays,
                calendar: calendar
            )
            return HabitResult(habit: habit, done: progress.checkInCount, due: progress.due, credited: progress.credited)
        }
    }

    /// The week worth reviewing right now: the one just ending on its last day, the one just
    /// ended on the first day of the next, and otherwise the week under way.
    static func defaultWeek(now: Date, calendar: Calendar) -> Date {
        let weekStart = now.startOfWeek(for: calendar)
        if calendar.isDate(now, inSameDayAs: weekStart),
           let lastWeek = calendar.date(byAdding: .day, value: -7, to: weekStart) {
            return lastWeek
        }
        return weekStart
    }

    /// `Calendar` numbers weekdays 1 = Sunday ... 7 = Saturday. The week ends the day before it
    /// starts again.
    static func lastWeekday(of calendar: Calendar) -> Int {
        (calendar.firstWeekday + 5) % 7 + 1
    }
}
