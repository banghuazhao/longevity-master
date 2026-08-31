//
// Created by Banghua Zhao on 31/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

/// A day the user has declared off. A streak counts *through* a rest day rather than being
/// reset by it, so a deliberate break — a sick day, a holiday, a scheduled recovery day —
/// costs nothing. It does not add to the streak either: resting is not doing.
@Table
struct SkippedDay: Identifiable {
    let id: Int
    @Column(as: Date.self)
    var date: Date
    /// `nil` is a rest day from everything, and bridges the overall streak as well as every
    /// habit's own. A habit's id rests from that habit alone.
    var habitID: Habit.ID?
}

extension SkippedDay.Draft: Identifiable {}

/// Days off, split the way every streak calculation needs them. Built once from the table and
/// then asked, rather than re-filtering the whole list per habit — the Today list, the stats
/// screen and the achievement checks each want the same two shapes.
struct RestDays {
    /// The days off from everything. These are what the overall streak — the one on My Stats
    /// and behind the longevity score — counts through.
    let everyHabit: Set<Date>
    private let byHabit: [Habit.ID: Set<Date>]

    init(_ skippedDays: some Collection<SkippedDay>, in calendar: Calendar) {
        var everyHabit: Set<Date> = []
        var byHabit: [Habit.ID: Set<Date>] = [:]
        for skipped in skippedDays {
            let day = skipped.date.startOfDay(for: calendar)
            if let habitID = skipped.habitID {
                byHabit[habitID, default: []].insert(day)
            } else {
                everyHabit.insert(day)
            }
        }
        self.everyHabit = everyHabit
        self.byHabit = byHabit
    }

    /// The days off that apply to one habit: its own, plus the days off from everything.
    func forHabit(_ habitID: Habit.ID) -> Set<Date> {
        everyHabit.union(byHabit[habitID] ?? [])
    }

    /// Whether `date` is a day off from every habit.
    func isEveryHabitRestDay(_ date: Date, in calendar: Calendar) -> Bool {
        everyHabit.contains(date.startOfDay(for: calendar))
    }
}
