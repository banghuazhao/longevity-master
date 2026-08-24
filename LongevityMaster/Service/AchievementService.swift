//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData
import Observation
import Sharing

@Observable
class AchievementService {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    @ObservationIgnored
    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true

    var userCalendar: Calendar {
        .userPreferred(startWeekOnMonday: startWeekOnMonday)
    }

    var achievementToShow: Achievement?

    init() {
        // Initialize achievements if they don't exist
        Task {
            await initializeAchievements()
        }
    }

    private func initializeAchievements() async {
        await withErrorReporting {
            try await database.write { db in
                let existingCount = try Achievement.all.fetchCount(db)
                if existingCount == 0 {
                    // Insert all achievement definitions
                    for achievementDraft in AchievementDefinitions.all {
                        try Achievement.upsert { achievementDraft }.execute(db)
                    }
                }
            }
        }
    }

    // MARK: - Evaluating a check-in

    /// Everything the criteria need, read once per check-in.
    ///
    /// Judging the achievements used to fan a single check-in out into a database read per
    /// streak and total-check-ins achievement, plus several passes that paired every check-in
    /// against every habit. It was also inconsistent about what it was judging: the criteria
    /// that read the observed table copies were looking at a database that had not yet caught
    /// up with the check-in just written, while the ones that read directly had. Every
    /// criterion now sees the same fresh snapshot.
    private struct Snapshot {
        let checkIns: [CheckIn]
        let habits: [Habit]
        let checkInsByHabit: [Habit.ID: [CheckIn]]
        let categoryByHabit: [Habit.ID: HabitCategory]
        /// The start of every day carrying a check-in against any habit at all.
        let activeDays: Set<Date>

        init(checkIns: [CheckIn], habits: [Habit], calendar: Calendar) {
            self.checkIns = checkIns
            self.habits = habits
            checkInsByHabit = Dictionary(grouping: checkIns, by: \.habitID)
            categoryByHabit = Dictionary(
                habits.map { ($0.id, $0.category) },
                uniquingKeysWith: { first, _ in first }
            )
            activeDays = Set(checkIns.map { $0.date.startOfDay(for: calendar) })
        }
    }

    func checkAchievementsAndShow(for checkIn: CheckIn) async {
        await withErrorReporting {
            let calendar = userCalendar

            // Locked achievements come from the same read as the rest, so an achievement
            // unlocked a moment ago cannot be unlocked again and have its date overwritten.
            let (checkIns, habits, locked) = try await database.read { db in
                (
                    try CheckIn.all.fetchAll(db),
                    try Habit.all.fetchAll(db),
                    try Achievement.where { !$0.isUnlocked }.fetchAll(db)
                )
            }

            let snapshot = Snapshot(checkIns: checkIns, habits: habits, calendar: calendar)
            let earned = locked.filter {
                meetsCriteria($0, for: checkIn, in: snapshot, calendar: calendar)
            }
            guard !earned.isEmpty else { return }

            // One transaction for the lot, rather than one per achievement.
            let unlockedDate = Date()
            let saved = try await database.write { db in
                try earned.compactMap { achievement -> Achievement? in
                    var achievement = achievement
                    achievement.isUnlocked = true
                    achievement.unlockedDate = unlockedDate
                    achievement.habitID = checkIn.habitID
                    return try Achievement.update(achievement).returning(\.self).fetchOne(db)
                }
            }

            if let toShow = saved.first {
                await MainActor.run {
                    achievementToShow = toShow
                }
            }
        }
    }

    private func meetsCriteria(
        _ achievement: Achievement,
        for checkIn: CheckIn,
        in snapshot: Snapshot,
        calendar: Calendar
    ) -> Bool {
        guard let criteria = AchievementCriteria.decode(from: achievement.criteria.encode()) else {
            return false
        }
        let target = criteria.targetValue

        switch achievement.type {
        case .streak:
            let habitID = achievement.habitID ?? checkIn.habitID
            let habitCheckIns = snapshot.checkInsByHabit[habitID] ?? []
            guard !habitCheckIns.isEmpty else { return false }
            let days = Set(habitCheckIns.map { $0.date.startOfDay(for: calendar) })
            return calendar.consecutiveDays(endingAt: checkIn.date, within: days, upTo: target) >= target

        case .totalCheckIns:
            let habitID = achievement.habitID ?? checkIn.habitID
            return (snapshot.checkInsByHabit[habitID] ?? []).count >= target

        case .perfectWeek:
            return everyHabitMetItsTarget(
                in: checkIn.date.startOfWeek(for: calendar) ... checkIn.date.endOfWeek(for: calendar),
                period: .week,
                snapshot: snapshot,
                calendar: calendar
            )

        case .perfectMonth:
            return everyHabitMetItsTarget(
                in: checkIn.date.startOfMonth(for: calendar) ... checkIn.date.endOfMonth(for: calendar),
                period: .month,
                snapshot: snapshot,
                calendar: calendar
            )

        case .categoryMaster:
            guard let category = criteria.category else { return false }
            let count = snapshot.checkIns.count { snapshot.categoryByHabit[$0.habitID] == category }
            return count >= target

        case .earlyBird:
            return calendar.component(.hour, from: checkIn.date) < 8

        case .nightOwl:
            return calendar.component(.hour, from: checkIn.date) >= 22

        case .consistency:
            return calendar.consecutiveDays(endingAt: checkIn.date, within: snapshot.activeDays, upTo: target) >= target

        case .variety:
            let categories = Set(snapshot.checkIns.compactMap { snapshot.categoryByHabit[$0.habitID] })
            return categories.count >= target

        case .milestone:
            return snapshot.checkIns.count >= target
        }
    }

    // MARK: - Perfect week and month

    /// Which period a "perfect" run is being judged over.
    private enum PerfectPeriod {
        case week
        case month
    }

    /// True when every active habit did what it owed over `range`.
    ///
    /// Fixed-schedule habits must have a check-in on each day they came due; days still ahead
    /// are not held against the user. Quota habits ("5 times a week") must have met the count.
    /// A habit whose quota period outlasts `range` — a monthly quota judged over one week —
    /// cannot be settled here and is passed over; a weekly quota judged over a month has to
    /// have been met in every whole week the month contains.
    ///
    /// Returns false when nothing could be judged at all, so a user with no habits does not
    /// get handed a perfect week.
    private func everyHabitMetItsTarget(
        in range: ClosedRange<Date>,
        period: PerfectPeriod,
        snapshot: Snapshot,
        calendar: Calendar
    ) -> Bool {
        let habits = snapshot.habits.filter { !$0.isArchived }
        guard !habits.isEmpty else { return false }

        let now = Date()
        var judgedAnything = false

        for habit in habits {
            let checkIns = (snapshot.checkInsByHabit[habit.id] ?? []).filter { range.contains($0.date) }

            switch habit.frequency {
            case .fixedDaysInWeek, .fixedDaysInMonth:
                let due = scheduledDays(for: habit, in: range, calendar: calendar).filter { $0 <= now }
                guard !due.isEmpty else { continue }
                judgedAnything = true
                let checkedDays = Set(checkIns.map { $0.date.startOfDay(for: calendar) })
                guard Set(due).isSubset(of: checkedDays) else { return false }

            case .nDaysEachWeek:
                judgedAnything = true
                switch period {
                case .week:
                    guard checkIns.count >= habit.nDaysPerWeek else { return false }
                case .month:
                    for week in wholeWeeks(in: range, calendar: calendar) where week.upperBound <= now {
                        let met = checkIns.count { week.contains($0.date) }
                        guard met >= habit.nDaysPerWeek else { return false }
                    }
                }

            case .nDaysEachMonth:
                guard period == .month else { continue }
                judgedAnything = true
                guard checkIns.count >= habit.nDaysPerMonth else { return false }
            }
        }

        return judgedAnything
    }

    /// The days inside `range` on which a fixed-schedule habit came due. Empty for quota
    /// habits, which owe a count over the period rather than any particular day.
    private func scheduledDays(for habit: Habit, in range: ClosedRange<Date>, calendar: Calendar) -> [Date] {
        let days: Set<Int>
        let unit: Calendar.Component
        switch habit.frequency {
        case .fixedDaysInWeek:
            days = habit.daysOfWeek
            unit = .weekday
        case .fixedDaysInMonth:
            days = habit.daysOfMonth
            unit = .day
        case .nDaysEachWeek, .nDaysEachMonth:
            return []
        }
        guard !days.isEmpty else { return [] }

        var result: [Date] = []
        var day = range.lowerBound.startOfDay(for: calendar)
        while day <= range.upperBound {
            if days.contains(calendar.component(unit, from: day)) {
                result.append(day)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// The weeks lying wholly inside `range`, so judging a weekly quota over a month does not
    /// fail on the part-weeks hanging off either end.
    private func wholeWeeks(in range: ClosedRange<Date>, calendar: Calendar) -> [ClosedRange<Date>] {
        var weeks: [ClosedRange<Date>] = []
        var start = range.lowerBound.startOfWeek(for: calendar)
        while start <= range.upperBound {
            let end = start.endOfWeek(for: calendar)
            if start >= range.lowerBound, end <= range.upperBound {
                weeks.append(start ... end)
            }
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { break }
            start = next
        }
        return weeks
    }
}


// Dependency injection
extension DependencyValues {
    var achievementService: AchievementService {
        get { self[AchievementServiceKey.self] }
        set { self[AchievementServiceKey.self] = newValue }
    }
}

private enum AchievementServiceKey: DependencyKey {
    static let liveValue = AchievementService()
}
