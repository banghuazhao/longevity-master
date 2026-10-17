//
// Created by Banghua Zhao on 17/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// A look back at one calendar year: how much got done, when, and on what.
///
/// Every figure here is a count of what happened rather than a judgement against a schedule.
/// A habit's schedule can change many times in a year, and only today's is stored, so a year's
/// "on track" would be measured against plans the user never had. What the user did is known
/// exactly.
///
/// Archived habits are counted: their check-ins were real, and putting a habit away in
/// November should not erase what it did from January to October.
struct YearReview {
    struct HabitTotal: Identifiable {
        let habit: Habit
        let checkIns: Int

        var id: Habit.ID { habit.id }
    }

    struct MonthTotal: Identifiable {
        /// The first day of the month.
        let month: Date
        let checkIns: Int

        var id: Date { month }
    }

    struct CategoryTotal: Identifiable {
        let category: HabitCategory
        let checkIns: Int

        var id: Int { category.rawValue }
    }

    struct WeekdayTotal {
        /// `Calendar` numbering: 1 = Sunday ... 7 = Saturday.
        let weekday: Int
        let checkIns: Int
    }

    let year: Int
    let yearStart: Date
    /// The start of the year's last day.
    let yearEnd: Date
    /// The year has not finished yet, so its figures are "so far".
    let isCurrentYear: Bool
    /// Days of the year lived so far, from the user's first check-in if that fell in it: all
    /// of them once it is over, none before it begins.
    let dayCount: Int
    /// Days each habit was checked in on, added up — a habit checked in twice in one day
    /// counts once.
    let checkInCount: Int
    /// Days with at least one check-in.
    let activeDayCount: Int
    /// Days off from everything, up to today.
    let restDayCount: Int
    /// The longest run of active days inside the year, bridged by days off.
    let longestStreak: Int
    /// All twelve, in order.
    let months: [MonthTotal]
    /// Habits checked in at least once, the busiest first.
    let habits: [HabitTotal]
    /// Categories checked in at least once, the busiest first.
    let categories: [CategoryTotal]
    let busiestWeekday: WeekdayTotal?
    /// Habits whose first check-in ever fell in this year.
    let newHabitCount: Int

    var isEmpty: Bool { checkInCount == 0 }

    /// The busiest month; the earlier one when two tie, since it got there first.
    var bestMonth: MonthTotal? {
        var best: MonthTotal?
        for month in months where month.checkIns > (best?.checkIns ?? 0) {
            best = month
        }
        return best
    }

    /// Share of the days lived so far that had a check-in.
    var activeDayShare: Double? {
        dayCount > 0 ? Double(activeDayCount) / Double(dayCount) : nil
    }

    var activeDayPercent: Int? {
        activeDayShare.map { Int(($0 * 100).rounded()) }
    }

    /// One line on how the year went, in the reader's language.
    var verdict: String {
        switch activeDayShare ?? 0 {
        case 0.8...:
            return String(localized: "Outstanding. Healthy habits are part of who you are now.")
        case 0.5..<0.8:
            return String(localized: "A strong year. You showed up more days than not.")
        case 0.2..<0.5:
            return String(localized: "A solid foundation. Small steps add up.")
        default:
            return String(localized: "Every check-in counts. Keep showing up.")
        }
    }

    // MARK: - Working it out

    /// - Parameter now: the present moment; days after it are not counted.
    static func make(
        year: Int,
        now: Date,
        habits: [Habit],
        checkIns: [CheckIn],
        skippedDays: [SkippedDay],
        calendar: Calendar
    ) -> YearReview {
        let today = calendar.startOfDay(for: now)
        let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? today
        let nextYearStart = calendar.date(byAdding: .year, value: 1, to: yearStart) ?? yearStart
        let yearEnd = calendar.date(byAdding: .day, value: -1, to: nextYearStart) ?? yearStart
        // The last day that has been lived, or `nil` for a year still to come.
        let lastCounted: Date? = today < yearStart ? nil : min(today, yearEnd)

        let habitsByID = Dictionary(habits.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        // One entry per habit per day, inside the year and not after today.
        var daysByHabit: [Habit.ID: Set<Date>] = [:]
        var firstDayByHabit: [Habit.ID: Date] = [:]
        for checkIn in checkIns where habitsByID[checkIn.habitID] != nil {
            let day = calendar.startOfDay(for: checkIn.date)
            if day <= today {
                firstDayByHabit[checkIn.habitID] = min(firstDayByHabit[checkIn.habitID] ?? day, day)
            }
            guard let lastCounted, day >= yearStart, day <= lastCounted else { continue }
            daysByHabit[checkIn.habitID, default: []].insert(day)
        }

        var activeDays: Set<Date> = []
        var monthCounts: [Int: Int] = [:]
        var weekdayCounts: [Int: Int] = [:]
        var categoryCounts: [HabitCategory: Int] = [:]
        var habitTotals: [HabitTotal] = []
        for (habitID, days) in daysByHabit {
            guard let habit = habitsByID[habitID] else { continue }
            activeDays.formUnion(days)
            habitTotals.append(HabitTotal(habit: habit, checkIns: days.count))
            categoryCounts[habit.category, default: 0] += days.count
            for day in days {
                monthCounts[calendar.component(.month, from: day), default: 0] += 1
                weekdayCounts[calendar.component(.weekday, from: day), default: 0] += 1
            }
        }

        let restDays = RestDays(skippedDays, in: calendar).everyHabit.filter { day in
            guard let lastCounted else { return false }
            return day >= yearStart && day <= lastCounted
        }

        let months = (1...12).compactMap { month -> MonthTotal? in
            calendar.date(from: DateComponents(year: year, month: month, day: 1)).map {
                MonthTotal(month: $0, checkIns: monthCounts[month] ?? 0)
            }
        }

        // Walked in the order the user's week runs, so a tie goes to the earlier day.
        var busiestWeekday: WeekdayTotal?
        for offset in 0..<7 {
            let weekday = (calendar.firstWeekday - 1 + offset) % 7 + 1
            let count = weekdayCounts[weekday] ?? 0
            if count > (busiestWeekday?.checkIns ?? 0) {
                busiestWeekday = WeekdayTotal(weekday: weekday, checkIns: count)
            }
        }

        // Nothing records when the user started, so their first check-in stands in for it, the
        // way the weekly review judges a habit from its first check-in: someone who began in
        // November is not held to the ten months before they had the app.
        let countFrom = max(yearStart, firstDayByHabit.values.min() ?? yearStart)
        let dayCount = lastCounted.map { last in
            countFrom <= last ? (calendar.dateComponents([.day], from: countFrom, to: last).day ?? 0) + 1 : 0
        } ?? 0

        let newHabitCount = firstDayByHabit.values.filter { $0 >= yearStart && $0 <= yearEnd }.count

        return YearReview(
            year: year,
            yearStart: yearStart,
            yearEnd: yearEnd,
            isCurrentYear: today >= yearStart && today <= yearEnd,
            dayCount: dayCount,
            checkInCount: habitTotals.reduce(0) { $0 + $1.checkIns },
            activeDayCount: activeDays.count,
            restDayCount: restDays.count,
            longestStreak: calendar.longestDayStreak(in: activeDays, skipping: restDays),
            months: months,
            habits: habitTotals.sorted { ($0.checkIns, -$0.habit.id) > ($1.checkIns, -$1.habit.id) },
            categories: categoryCounts
                .map { CategoryTotal(category: $0.key, checkIns: $0.value) }
                .sorted { ($0.checkIns, -$0.category.rawValue) > ($1.checkIns, -$1.category.rawValue) },
            busiestWeekday: busiestWeekday,
            newHabitCount: newHabitCount
        )
    }

    /// A year in review is January to December whatever calendar the device is set to: a
    /// year number means the same thing to everyone the card is shared with, and building
    /// January 1 from a bare year number is only well defined in a calendar without eras.
    /// The user's time zone, language and week start carry over.
    static func calendar(from userCalendar: Calendar) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = userCalendar.timeZone
        calendar.locale = userCalendar.locale
        calendar.firstWeekday = userCalendar.firstWeekday
        return calendar
    }

    /// The year worth reviewing right now: last year through January, while it is still the
    /// one people are looking back on, and this year the rest of the time.
    static func defaultYear(now: Date, earliestCheckIn: Date?, calendar: Calendar) -> Int {
        let year = calendar.component(.year, from: now)
        guard
            calendar.component(.month, from: now) == 1,
            let earliestCheckIn,
            calendar.component(.year, from: earliestCheckIn) < year
        else { return year }
        return year - 1
    }

    /// From the year of the first check-in through this one.
    static func availableYears(earliestCheckIn: Date?, now: Date, calendar: Calendar) -> ClosedRange<Int> {
        let thisYear = calendar.component(.year, from: now)
        let firstYear = earliestCheckIn.map { calendar.component(.year, from: $0) } ?? thisYear
        return min(firstYear, thisYear)...thisYear
    }
}
