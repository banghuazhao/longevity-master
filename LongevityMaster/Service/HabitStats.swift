//
// Created by Banghua Zhao on 17/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// The figures at the top of a habit's page: its streaks, how often it has been done, and how
/// well it has kept to its schedule lately.
///
/// Streaks are the same day streaks the habit's tile and share card show, and "on track" is
/// judged by the same rules as the weekly review and programs (`ProgramProgress`), so no two
/// screens disagree about the same habit.
struct HabitStats: Equatable {
    let currentStreak: Int
    let bestStreak: Int
    /// Days the habit was checked in on.
    let totalCheckIns: Int
    /// Share of what fell due in the last `recentWindowDays` that got done, 0...1.
    ///
    /// `nil` when nothing fell due — and for a habit never checked in, which has no first
    /// check-in to start counting from. Habits have no creation date, so a brand-new habit
    /// would otherwise read as a month of misses.
    let recentAdherence: Double?
    let firstCheckIn: Date?

    static let recentWindowDays = 30

    var recentAdherencePercent: Int? {
        recentAdherence.map { Int(($0 * 100).rounded()) }
    }

    static func make(
        habit: Habit,
        checkIns: [CheckIn],
        restDays: RestDays,
        now: Date,
        calendar: Calendar
    ) -> HabitStats {
        let ownCheckIns = checkIns.filter { $0.habitID == habit.id }
        let activeDays = Set(ownCheckIns.map { calendar.startOfDay(for: $0.date) })
        let rested = restDays.forHabit(habit.id)
        let firstDay = activeDays.min()

        return HabitStats(
            currentStreak: calendar.currentDayStreak(in: activeDays, skipping: rested, asOf: now),
            bestStreak: calendar.longestDayStreak(in: activeDays, skipping: rested),
            totalCheckIns: activeDays.count,
            recentAdherence: firstDay.flatMap { first in
                recentAdherence(
                    habit: habit,
                    checkIns: ownCheckIns,
                    restDays: restDays,
                    since: first,
                    now: now,
                    calendar: calendar
                )
            },
            firstCheckIn: ownCheckIns.map(\.date).min()
        )
    }

    /// Counted from the first check-in when that is less than the window ago: a habit begun
    /// last Thursday is judged from Thursday, the way the weekly review judges it.
    private static func recentAdherence(
        habit: Habit,
        checkIns: [CheckIn],
        restDays: RestDays,
        since firstDay: Date,
        now: Date,
        calendar: Calendar
    ) -> Double? {
        let today = calendar.startOfDay(for: now)
        guard
            firstDay <= today,
            let windowStart = calendar.date(byAdding: .day, value: -(recentWindowDays - 1), to: today)
        else { return nil }
        let start = max(windowStart, firstDay)
        let length = (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1

        return ProgramProgress.make(
            durationDays: length,
            startDate: start,
            today: now,
            habits: [habit],
            checkIns: checkIns,
            restDays: restDays,
            calendar: calendar
        ).adherence
    }
}
