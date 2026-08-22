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
}
