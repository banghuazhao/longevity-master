//
// Created by Banghua Zhao on 10/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

/// Several days off at once — a holiday, an illness — for one habit or for all of them. Each
/// day becomes an ordinary `SkippedDay`, so streaks, achievements and reminders treat a stretch
/// of time off exactly as they treat a single rest day.
enum TimeOff {
    /// Long enough for any holiday, short enough that a slip of the date picker cannot write
    /// years of rows.
    static let maxDays = 90

    /// Every calendar day from `start` through `end`, at most `maxDays` of them. Empty if
    /// `end` comes before `start`.
    static func days(from start: Date, through end: Date, calendar: Calendar) -> [Date] {
        let first = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        guard first <= last else { return [] }

        var days: [Date] = []
        var day = first
        while day <= last, days.count < maxDays {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    /// Which of `days` still need a row. A day already off needs nothing more; and for one
    /// habit, a day it was already done stays done — taking time off must never erase a
    /// check-in. A day off from everything leaves check-ins alone anyway, as it does on Today.
    static func daysToAdd(
        _ days: [Date],
        habitID: Habit.ID?,
        skippedDays: [SkippedDay],
        checkIns: [CheckIn],
        calendar: Calendar
    ) -> [Date] {
        let alreadyOff = Set(
            skippedDays
                .filter { $0.habitID == habitID }
                .map { calendar.startOfDay(for: $0.date) }
        )
        let checkedIn: Set<Date> = if let habitID {
            Set(checkIns.filter { $0.habitID == habitID }.map { calendar.startOfDay(for: $0.date) })
        } else {
            []
        }
        return days.filter { day in
            let day = calendar.startOfDay(for: day)
            return !alreadyOff.contains(day) && !checkedIn.contains(day)
        }
    }

    /// Stretches of time off that have not ended yet, soonest first, with neighbouring days
    /// joined into one stretch.
    static func upcoming(
        _ skippedDays: [SkippedDay],
        habitID: Habit.ID?,
        asOf now: Date,
        calendar: Calendar
    ) -> [ClosedRange<Date>] {
        let today = calendar.startOfDay(for: now)
        let days = Set(
            skippedDays
                .filter { $0.habitID == habitID }
                .map { calendar.startOfDay(for: $0.date) }
        )
        .filter { $0 >= today }
        .sorted()

        var ranges: [ClosedRange<Date>] = []
        for day in days {
            if let last = ranges.last,
               let following = calendar.date(byAdding: .day, value: 1, to: last.upperBound),
               calendar.isDate(following, inSameDayAs: day) {
                ranges[ranges.count - 1] = last.lowerBound ... day
            } else {
                ranges.append(day ... day)
            }
        }
        return ranges
    }

    /// The moment a day off is filed under. Midday rather than midnight, so the row still
    /// lands on the same day if the phone later moves a few time zones west.
    static func storedDate(for day: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }

    static func add(
        from start: Date,
        through end: Date,
        habitID: Habit.ID?,
        calendar: Calendar,
        in db: Database
    ) throws {
        let days = days(from: start, through: end, calendar: calendar)
        guard let first = days.first, let last = days.last else { return }
        let lower = first
        let upper = last.endOfDay(for: calendar)

        let skippedDays = try SkippedDay
            .where { $0.date.between(lower, and: upper) }
            .fetchAll(db)
        let checkIns: [CheckIn] = if let habitID {
            try CheckIn
                .where { $0.habitID.eq(habitID) }
                .where { $0.date.between(lower, and: upper) }
                .fetchAll(db)
        } else {
            []
        }

        for day in daysToAdd(days, habitID: habitID, skippedDays: skippedDays, checkIns: checkIns, calendar: calendar) {
            try SkippedDay
                .insert { SkippedDay.Draft(date: storedDate(for: day, calendar: calendar), habitID: habitID) }
                .execute(db)
        }
    }

    /// Takes back a stretch of time off. Only rows of this scope go: removing a habit's own
    /// time off leaves any day off from everything in place, and the other way round.
    static func remove(
        _ range: ClosedRange<Date>,
        habitID: Habit.ID?,
        calendar: Calendar,
        in db: Database
    ) throws {
        let lower = calendar.startOfDay(for: range.lowerBound)
        let upper = range.upperBound.endOfDay(for: calendar)
        let inRange = SkippedDay.where { $0.date.between(lower, and: upper) }
        if let habitID {
            try inRange.where { $0.habitID.eq(habitID) }.delete().execute(db)
        } else {
            try inRange.where { $0.habitID.is(nil) }.delete().execute(db)
        }
    }
}
