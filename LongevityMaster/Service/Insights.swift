//
// Created by Banghua Zhao on 22/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// A handful of plain observations about the last four weeks: which day of the week goes
/// best, when in the day check-ins happen, which habit is steadiest and which is slipping.
///
/// Four whole weeks so that every weekday is counted the same number of times.
struct Insights: Equatable {
    static let windowDays = 28
    /// Fewer check-ins than this in the window and the patterns are noise.
    static let minimumCheckIns = 5

    struct WeekdayCount: Identifiable, Equatable {
        /// 1 = Sunday, as `Calendar` numbers them.
        let weekday: Int
        let count: Int
        var id: Int { weekday }
    }

    enum TimeOfDay: Equatable {
        case morning
        case afternoon
        case evening
    }

    struct HabitScore: Equatable {
        let name: String
        let icon: String
        /// Share of what fell due that got done, 0...1.
        let adherence: Double
    }

    /// Every weekday in the order the user's week runs, including the ones with nothing.
    let weekdayCounts: [WeekdayCount]
    let totalCheckIns: Int
    /// Days in the window with at least one check-in.
    let activeDays: Int
    /// The last seven days, today included, and the seven before them.
    let thisWeekCount: Int
    let lastWeekCount: Int
    let bestWeekday: Int?
    /// Only when it differs from the best day by something.
    let quietestWeekday: Int?
    let mainTimeOfDay: TimeOfDay?
    let mainTimeOfDayShare: Double
    let mostConsistent: HabitScore?
    let needsAttention: HabitScore?
    let topCategory: HabitCategory?
    let topCategoryShare: Double

    var hasEnoughData: Bool {
        totalCheckIns >= Self.minimumCheckIns
    }

    /// The change on the week before as a fraction, or nil when there was nothing to compare
    /// with.
    var weekOverWeekChange: Double? {
        guard lastWeekCount > 0 else { return nil }
        return Double(thisWeekCount - lastWeekCount) / Double(lastWeekCount)
    }

    static func make(
        habits: [Habit],
        checkIns: [CheckIn],
        skippedDays: [SkippedDay],
        now: Date,
        calendar: Calendar
    ) -> Insights {
        let today = calendar.startOfDay(for: now)
        let windowStart = calendar.date(byAdding: .day, value: -(windowDays - 1), to: today) ?? today
        let thisWeekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let lastWeekStart = calendar.date(byAdding: .day, value: -13, to: today) ?? today

        let recent = checkIns.filter { $0.date >= windowStart && $0.date <= now }

        // Weekdays, in the order the user's week runs.
        var countsByWeekday: [Int: Int] = [:]
        for checkIn in recent {
            countsByWeekday[calendar.component(.weekday, from: checkIn.date), default: 0] += 1
        }
        let weekdayCounts = (0 ..< 7).map { offset in
            let weekday = (calendar.firstWeekday - 1 + offset) % 7 + 1
            return WeekdayCount(weekday: weekday, count: countsByWeekday[weekday] ?? 0)
        }
        // Ties go to the earlier day in the week.
        let best = weekdayCounts.reduce(nil as WeekdayCount?) { best, day in
            guard day.count > 0 else { return best }
            return day.count > (best?.count ?? 0) ? day : best
        }
        let quietest = weekdayCounts.reduce(nil as WeekdayCount?) { quietest, day in
            day.count < (quietest?.count ?? .max) ? day : quietest
        }

        // Time of day.
        var countsByTime: [TimeOfDay: Int] = [:]
        for checkIn in recent {
            let hour = calendar.component(.hour, from: checkIn.date)
            let time: TimeOfDay = hour < 12 ? .morning : hour < 17 ? .afternoon : .evening
            countsByTime[time, default: 0] += 1
        }
        let mainTime = [TimeOfDay.morning, .afternoon, .evening]
            .max { (countsByTime[$0] ?? 0) < (countsByTime[$1] ?? 0) }
            .flatMap { (countsByTime[$0] ?? 0) > 0 ? $0 : nil }

        // Categories.
        let categoryByHabit = Dictionary(
            habits.map { ($0.id, $0.category) },
            uniquingKeysWith: { first, _ in first }
        )
        var countsByCategory: [HabitCategory: Int] = [:]
        for checkIn in recent {
            if let category = categoryByHabit[checkIn.habitID] {
                countsByCategory[category, default: 0] += 1
            }
        }
        let topCategory = HabitCategory.allCases
            .filter { (countsByCategory[$0] ?? 0) > 0 }
            .max { (countsByCategory[$0] ?? 0) < (countsByCategory[$1] ?? 0) }

        // Habits, judged by the same rule as their own pages.
        let restDays = RestDays(skippedDays, in: calendar)
        let scores = habits
            .filter { !$0.isArchived }
            .compactMap { habit -> HabitScore? in
                let stats = HabitStats.make(
                    habit: habit,
                    checkIns: checkIns,
                    restDays: restDays,
                    now: now,
                    calendar: calendar
                )
                guard let adherence = stats.recentAdherence else { return nil }
                return HabitScore(name: habit.name, icon: habit.icon, adherence: adherence)
            }
        // Ties are settled by name, so the same data always picks the same habit.
        let ranked = scores.sorted {
            $0.adherence != $1.adherence ? $0.adherence > $1.adherence : $0.name < $1.name
        }
        let mostConsistent = ranked.first.flatMap { $0.adherence >= 0.5 ? $0 : nil }
        let needsAttention = ranked.last.flatMap { last -> HabitScore? in
            guard last.adherence < 0.6, last != mostConsistent else { return nil }
            return last
        }

        let total = recent.count
        return Insights(
            weekdayCounts: weekdayCounts,
            totalCheckIns: total,
            activeDays: Set(recent.map { calendar.startOfDay(for: $0.date) }).count,
            thisWeekCount: recent.count { $0.date >= thisWeekStart },
            lastWeekCount: checkIns.count { $0.date >= lastWeekStart && $0.date < thisWeekStart },
            bestWeekday: best?.weekday,
            quietestWeekday: quietest.flatMap { quietest in
                guard let best, quietest.count < best.count else { return nil }
                return quietest.weekday
            },
            mainTimeOfDay: mainTime,
            mainTimeOfDayShare: mainTime.map { Double(countsByTime[$0] ?? 0) / Double(max(total, 1)) } ?? 0,
            mostConsistent: mostConsistent,
            needsAttention: needsAttention,
            topCategory: topCategory,
            topCategoryShare: topCategory.map { Double(countsByCategory[$0] ?? 0) / Double(max(total, 1)) } ?? 0
        )
    }
}
