//
// Created by Banghua Zhao on 18/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

extension Date {
    func startOfDay(for calendar: Calendar) -> Date {
        calendar.startOfDay(for: self)
    }

    func endOfDay(for calendar: Calendar) -> Date {
        let startOfDay = startOfDay(for: calendar)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            .addingTimeInterval(-0.001)
        return endOfDay
    }

    func startOfWeek(for calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }

    func endOfWeek(for calendar: Calendar) -> Date {
        var components = DateComponents()
        components.weekOfYear = 1
        components.nanosecond = -1
        return calendar.date(byAdding: components, to: startOfWeek(for: calendar))!
    }

    func startOfMonth(for calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }

    func endOfMonth(for calendar: Calendar) -> Date {
        var components = DateComponents()
        components.month = 1
        components.nanosecond = -1
        return calendar.date(byAdding: components, to: startOfMonth(for: calendar))!
    }
}

extension Calendar {
    /// `Calendar.current` follows the device region’s week start; the app lets the user pick,
    /// and every scheduling calculation has to agree on which one is in effect.
    static func userPreferred(startWeekOnMonday: Bool) -> Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = startWeekOnMonday ? 2 : 1 // 2 = Monday, 1 = Sunday
        return calendar
    }

    /// How many days in a row, counting back from `date`, appear in `days`. Stops at `limit`,
    /// which is as far as any caller needs it counted.
    ///
    /// Streaks were being counted by rescanning the check-ins for each day walked; a set of
    /// start-of-days answers the same question without the rescan.
    func consecutiveDays(endingAt date: Date, within days: Set<Date>, upTo limit: Int) -> Int {
        var streak = 0
        var current = date
        while streak < limit, days.contains(startOfDay(for: current)) {
            streak += 1
            guard let previous = self.date(byAdding: .day, value: -1, to: current) else { break }
            current = previous
        }
        return streak
    }

    /// The streak the user is on right now: days in a row ending today, or ending yesterday
    /// while today’s check-in is still outstanding.
    ///
    /// Counting only from today reads zero for most of every day, which is not what anyone
    /// means by their current streak. Counting from the most recent check-in, whenever that
    /// was, reports a streak that ended weeks ago as current. Allowing exactly one day still
    /// in play separates the two.
    func currentDayStreak(in days: Set<Date>, asOf date: Date = Date()) -> Int {
        let today = startOfDay(for: date)
        let countFrom = days.contains(today)
            ? today
            : self.date(byAdding: .day, value: -1, to: today)
        guard let countFrom else { return 0 }
        return consecutiveDays(endingAt: countFrom, within: days, upTo: days.count)
    }

    /// How long each run of consecutive days in `days` lasted, oldest run first.
    ///
    /// Longest streak and average streak are both questions about this one list, and each was
    /// being answered by its own copy of the same walk.
    func dayStreakLengths(in days: Set<Date>) -> [Int] {
        var lengths: [Int] = []
        var run = 0
        var previous: Date?

        for day in days.sorted() {
            if let previous, dateComponents([.day], from: previous, to: day).day == 1 {
                run += 1
            } else {
                if run > 0 { lengths.append(run) }
                run = 1
            }
            previous = day
        }
        if run > 0 { lengths.append(run) }

        return lengths
    }

    func longestDayStreak(in days: Set<Date>) -> Int {
        dayStreakLengths(in: days).max() ?? 0
    }
}
