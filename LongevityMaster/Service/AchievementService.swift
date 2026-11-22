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
        /// Days off. Streaks count through these, and a habit is not held to its schedule on
        /// one.
        let restDays: RestDays
        /// Programs seen through to their last day.
        let finishedProgramCount: Int
        /// The longevity score as the Rating tab shows it.
        var longevityScore: Int

        init(
            checkIns: [CheckIn],
            habits: [Habit],
            skippedDays: [SkippedDay],
            enrollments: [ProgramEnrollment],
            customPrograms: [CustomProgram],
            unlockedAchievementCount: Int,
            now: Date,
            calendar: Calendar
        ) {
            self.checkIns = checkIns
            self.habits = habits
            checkInsByHabit = Dictionary(grouping: checkIns, by: \.habitID)
            categoryByHabit = Dictionary(
                habits.map { ($0.id, $0.category) },
                uniquingKeysWith: { first, _ in first }
            )
            activeDays = Set(checkIns.map { $0.date.startOfDay(for: calendar) })
            restDays = RestDays(skippedDays, in: calendar)
            finishedProgramCount = ProgramEnrollments.finishedCount(
                enrollments,
                customPrograms: customPrograms,
                now: now,
                calendar: calendar
            )
            longevityScore = RatingService.score(
                habits: habits,
                unlockedAchievementCount: unlockedAchievementCount,
                checkIns: checkIns,
                skippedDays: skippedDays,
                calendar: calendar
            ).totalScore
        }
    }

    /// Judges the achievements again against the most recent check-in, whichever way it was
    /// made.
    ///
    /// Some are earned without a check-in in the app: a rating reached, a program run to its
    /// last day, a year gone by — and check-ins from the widget, Control Center or Siri are
    /// never judged where they are made. Run once the app is up, so those are not left
    /// waiting for the next check-in on the Today tab.
    func checkAchievementsForLatestCheckIn() async {
        let latest = await withErrorReporting {
            try await database.read { db in
                try CheckIn.order { $0.date.desc() }.fetchOne(db)
            }
        }
        guard let latest = latest ?? nil else { return }
        await checkAchievementsAndShow(for: latest)
    }

    func checkAchievementsAndShow(for checkIn: CheckIn) async {
        await withErrorReporting {
            let calendar = userCalendar

            // Locked achievements come from the same read as the rest, so an achievement
            // unlocked a moment ago cannot be unlocked again and have its date overwritten.
            let (checkIns, habits, skippedDays, enrollments, customPrograms, unlockedCount, locked) = try await database.read { db in
                (
                    try CheckIn.all.fetchAll(db),
                    try Habit.all.fetchAll(db),
                    try SkippedDay.all.fetchAll(db),
                    try ProgramEnrollment.all.fetchAll(db),
                    try CustomProgram.all.fetchAll(db),
                    try Achievement.where { $0.isUnlocked }.fetchCount(db),
                    try Achievement.where { !$0.isUnlocked }.fetchAll(db)
                )
            }

            var snapshot = Snapshot(
                checkIns: checkIns,
                habits: habits,
                skippedDays: skippedDays,
                enrollments: enrollments,
                customPrograms: customPrograms,
                unlockedAchievementCount: unlockedCount,
                now: Date(),
                calendar: calendar
            )
            // Every achievement unlocked adds to the longevity score, which can carry it past
            // a rating that is an achievement of its own. Judge again until nothing more is
            // earned, rather than leaving that one for the next check-in.
            var earned: [Achievement] = []
            var stillLocked = locked
            while true {
                let newlyEarned = stillLocked.filter {
                    meetsCriteria($0, for: checkIn, in: snapshot, calendar: calendar)
                }
                guard !newlyEarned.isEmpty else { break }
                earned += newlyEarned
                let newlyEarnedIDs = Set(newlyEarned.map(\.id))
                stillLocked.removeAll { newlyEarnedIDs.contains($0.id) }
                snapshot.longevityScore = RatingService.score(
                    habits: habits,
                    unlockedAchievementCount: unlockedCount + earned.count,
                    checkIns: checkIns,
                    skippedDays: skippedDays,
                    calendar: calendar
                ).totalScore
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
            return calendar.consecutiveDays(
                endingAt: checkIn.date,
                within: days,
                skipping: snapshot.restDays.forHabit(habitID),
                upTo: target
            ) >= target

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
            return calendar.consecutiveDays(
                endingAt: checkIn.date,
                within: snapshot.activeDays,
                skipping: snapshot.restDays.everyHabit,
                upTo: target
            ) >= target

        case .variety:
            let categories = Set(snapshot.checkIns.compactMap { snapshot.categoryByHabit[$0.habitID] })
            return categories.count >= target

        case .milestone:
            return snapshot.checkIns.count >= target

        case .comeback:
            // The days with nothing at all between this check-in's day and the last one
            // before it. Only a check-in that ends the gap can earn it.
            let day = checkIn.date.startOfDay(for: calendar)
            guard
                let previous = snapshot.activeDays.filter({ $0 < day }).max(),
                let gap = calendar.dateComponents([.day], from: previous, to: day).day
            else { return false }
            return gap - 1 >= target

        case .balancedDay:
            let day = checkIn.date.startOfDay(for: calendar)
            let categories = Set(
                snapshot.checkIns
                    .filter { $0.date.startOfDay(for: calendar) == day }
                    .compactMap { snapshot.categoryByHabit[$0.habitID] }
            )
            return categories.count >= target

        case .programGraduate:
            return snapshot.finishedProgramCount >= target

        case .longevityRating:
            return snapshot.longevityScore >= target

        case .anniversary:
            let day = checkIn.date.startOfDay(for: calendar)
            guard
                let first = snapshot.activeDays.min(),
                let elapsed = calendar.dateComponents([.day], from: first, to: day).day
            else { return false }
            return elapsed >= target

        case .topHabitStreak:
            guard
                let habit = snapshot.habits.first(where: { $0.id == checkIn.habitID }),
                habit.antiAgingRating >= 5
            else { return false }
            let days = Set((snapshot.checkInsByHabit[habit.id] ?? []).map { $0.date.startOfDay(for: calendar) })
            return calendar.consecutiveDays(
                endingAt: checkIn.date,
                within: days,
                skipping: snapshot.restDays.forHabit(habit.id),
                upTo: target
            ) >= target
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

            let restDays = snapshot.restDays.forHabit(habit.id)

            switch habit.frequency {
            case .fixedDaysInWeek, .fixedDaysInMonth:
                // A day taken off is not a day the habit came due, so it cannot be the day
                // that costs a perfect week.
                let due = scheduledDays(for: habit, in: range, calendar: calendar)
                    .filter { $0 <= now && !restDays.contains($0) }
                guard !due.isEmpty else { continue }
                judgedAnything = true
                let checkedDays = Set(checkIns.map { $0.date.startOfDay(for: calendar) })
                guard Set(due).isSubset(of: checkedDays) else { return false }

            case .nDaysEachWeek:
                judgedAnything = true
                switch period {
                case .week:
                    let owed = quota(habit.nDaysPerWeek, lessRestDaysIn: range, from: restDays)
                    guard checkIns.count >= owed else { return false }
                case .month:
                    for week in wholeWeeks(in: range, calendar: calendar) where week.upperBound <= now {
                        let met = checkIns.count { week.contains($0.date) }
                        let owed = quota(habit.nDaysPerWeek, lessRestDaysIn: week, from: restDays)
                        guard met >= owed else { return false }
                    }
                }

            case .nDaysEachMonth:
                guard period == .month else { continue }
                judgedAnything = true
                let owed = quota(habit.nDaysPerMonth, lessRestDaysIn: range, from: restDays)
                guard checkIns.count >= owed else { return false }
            }
        }

        return judgedAnything
    }

    /// What a quota habit owes over `range` once the days taken off inside it are deducted.
    /// A habit asking for five days a week owes four in a week with one rest day. Never
    /// negative: a period made entirely of rest days owes nothing.
    private func quota(_ target: Int, lessRestDaysIn range: ClosedRange<Date>, from restDays: Set<Date>) -> Int {
        guard !restDays.isEmpty else { return target }
        let resting = restDays.count { range.contains($0) }
        return max(0, target - resting)
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
