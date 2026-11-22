//
// Created by Banghua Zhao on 22/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import HealthKit
import OSLog
import SQLiteData

private let logger = Logger(subsystem: "LongevityMaster", category: "HealthSync")

/// Checks in the habits linked to Apple Health once Health shows their goal was met.
///
/// Runs whenever the app comes to the foreground, and right after a habit is linked. It only
/// ever adds check-ins, and only for today and yesterday — yesterday so that a walk finished
/// late in the evening still counts when the app is next opened in the morning.
enum HealthSync {
    /// False on the Mac, where there is no Health store to read.
    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private static let store = HKHealthStore()

    /// Asks to read what `metric` needs. Health shows its sheet only the first time; after
    /// that it returns at once, whatever the user chose. Apps are never told whether reading
    /// was refused — a refused read simply finds no data.
    static func requestAccess(to metric: HealthMetric) async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: [metric.objectType])
        } catch {
            logger.error("Health authorization failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Syncing

    @MainActor private static var isSyncing = false

    /// Checks in every linked habit whose goal was met, then brings the widgets, reminders and
    /// achievements up to date.
    @MainActor
    static func syncAll() async {
        guard isAvailable, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        @Dependency(\.defaultDatabase) var database
        @Dependency(\.achievementService) var achievementService
        @Dependency(\.notificationService) var notificationService

        let calendar = Calendar.userPreferred(startWeekOnMonday: AppGroup.startWeekOnMonday)
        do {
            let created = try await sync(
                database: database,
                now: Date(),
                calendar: calendar
            ) { metric, day in
                await total(of: metric, on: day, calendar: calendar)
            }
            guard let last = created.last else { return }
            logger.info("Checked in \(created.count) habit(s) from Apple Health")
            WidgetRefresher.reload()
            await notificationService.syncAllReminders()
            await achievementService.checkAchievementsAndShow(for: last)
        } catch {
            logger.error("Health sync failed: \(error.localizedDescription)")
        }
    }

    /// The decisions behind `syncAll`, with Health itself passed in so tests can stand in for it.
    ///
    /// For each linked habit, each of yesterday and today is looked at once at most:
    /// - not due that day (a rest from its schedule, or a quota already met) — skipped, and
    ///   looked at again next time;
    /// - already checked in by hand — nothing to add, and the day is settled;
    /// - goal met — checked in, and the day is settled;
    /// - goal not met yet — looked at again next time.
    ///
    /// A settled day is never looked at again, so a check-in the user takes back is not made
    /// a second time.
    ///
    /// - Returns: the check-ins it made.
    @discardableResult
    static func sync(
        database: any DatabaseWriter,
        now: Date,
        calendar: Calendar,
        total: (HealthMetric, Date) async throws -> Double
    ) async throws -> [CheckIn] {
        let (links, habits, checkIns) = try await database.read { db in
            (
                try HealthLink.all.fetchAll(db),
                try Habit.where { !$0.isArchived }.fetchAll(db),
                try CheckIn.all.fetchAll(db)
            )
        }
        guard !links.isEmpty else { return [] }

        let habitsByID = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return [] }

        var created: [CheckIn] = []
        for link in links {
            guard let habit = habitsByID[link.habitID] else { continue }
            var settled = link.lastCheckInDay.map { calendar.startOfDay(for: $0) }

            for day in [yesterday, today] {
                if let settled, settled >= day { continue }
                guard
                    let scheduled = HabitSchedule.habitsDue(
                        on: day,
                        habits: [habit],
                        checkIns: checkIns + created,
                        calendar: calendar
                    ).first
                else { continue }

                if scheduled.isCompleted {
                    settled = day
                    continue
                }

                let value = try await total(link.metric, day)
                guard value >= Double(link.goal) else { continue }

                // Today's is stamped now, as a check-in by hand would be; yesterday's at
                // midday, which no early-bird or night-owl award reads anything into.
                let date = day == today
                    ? now
                    : calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
                let checkIn = try await database.write { db in
                    try CheckIn
                        .insert { CheckIn.Draft(date: date, habitID: habit.id) }
                        .returning(\.self)
                        .fetchOne(db)
                }
                if let checkIn {
                    created.append(checkIn)
                }
                settled = day
            }

            if let settled, settled != link.lastCheckInDay.map({ calendar.startOfDay(for: $0) }) {
                var updated = link
                updated.lastCheckInDay = settled
                try await database.write { [updated] db in
                    try HealthLink.update(updated).execute(db)
                }
            }
        }
        return created
    }

    // MARK: - Reading Health

    /// `metric`'s total for `day`, in the metric's own unit. Nothing recorded, or nothing the
    /// app may read, comes back as zero.
    static func total(of metric: HealthMetric, on day: Date, calendar: Calendar) async -> Double {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }

        do {
            switch metric {
            case .steps:
                return try await sum(.stepCount, unit: .count(), from: start, to: end)
            case .exerciseMinutes:
                return try await sum(.appleExerciseTime, unit: .minute(), from: start, to: end)
            case .mindfulMinutes:
                let seconds = try await duration(of: HKCategoryType(.mindfulSession), from: start, to: end) { _ in true }
                return seconds / 60
            case .sleepHours:
                // The night that ends on `day`: from six the evening before until midday.
                guard
                    let nightStart = calendar.date(byAdding: .hour, value: -6, to: start),
                    let nightEnd = calendar.date(byAdding: .hour, value: 12, to: start)
                else { return 0 }
                let asleep = Set(HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue))
                let seconds = try await duration(of: HKCategoryType(.sleepAnalysis), from: nightStart, to: nightEnd) {
                    asleep.contains($0.value)
                }
                return seconds / 3600
            }
        } catch {
            // No data at all is reported as an error rather than an empty result.
            return 0
        }
    }

    /// A cumulative quantity over a span. Health's own statistics merge what the phone and a
    /// watch both recorded, so the same steps are not counted twice.
    private static func sum(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from start: Date,
        to end: Date
    ) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(identifier), predicate: predicate),
            options: .cumulativeSum
        )
        let statistics = try await descriptor.result(for: store)
        return statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
    }

    /// Seconds covered by the category samples `isCounted` accepts, cut to the span. Where
    /// samples overlap — the phone and a watch both tracking the same night — the time is
    /// counted once.
    private static func duration(
        of type: HKCategoryType,
        from start: Date,
        to end: Date,
        isCounted: @escaping (HKCategorySample) -> Bool
    ) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        let intervals = try await descriptor.result(for: store)
            .filter(isCounted)
            .compactMap { sample -> DateInterval? in
                let from = max(sample.startDate, start)
                let to = min(sample.endDate, end)
                return from < to ? DateInterval(start: from, end: to) : nil
            }
        return mergedDuration(of: intervals)
    }

    /// The time covered by `intervals`, with overlaps counted once.
    static func mergedDuration(of intervals: [DateInterval]) -> TimeInterval {
        var total: TimeInterval = 0
        var current: DateInterval?
        for interval in intervals.sorted(by: { $0.start < $1.start }) {
            if let open = current, interval.start <= open.end {
                current = DateInterval(start: open.start, end: max(open.end, interval.end))
            } else {
                if let open = current { total += open.duration }
                current = interval
            }
        }
        if let open = current { total += open.duration }
        return total
    }
}

extension HealthMetric {
    /// The Health data the metric is read from.
    var objectType: HKObjectType {
        switch self {
        case .steps: HKQuantityType(.stepCount)
        case .exerciseMinutes: HKQuantityType(.appleExerciseTime)
        case .mindfulMinutes: HKCategoryType(.mindfulSession)
        case .sleepHours: HKCategoryType(.sleepAnalysis)
        }
    }
}
