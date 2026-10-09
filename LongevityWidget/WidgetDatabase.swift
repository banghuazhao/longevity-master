//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData
import WidgetKit

/// The connection everything outside the app's screens uses — the widget, Control Center and
/// Siri — to the database the app keeps in the shared App Group container.
///
/// It deliberately does not run migrations: the app owns the schema, and a widget refresh is the
/// wrong moment to be altering tables. If the app has never launched there is nothing to read.
///
/// Compiled into the app as well, for the intents Siri and Shortcuts run in the app's process.
enum WidgetDatabase {
    enum Failure: Error {
        /// No App Group container, or the app has not created its database yet.
        case unavailable
    }

    /// Set by the app at launch to its own open database. An intent running in the app's
    /// process then writes through the connection the app's screens observe, so a habit checked
    /// in by Siri ticks over on screen at once instead of on the next trip to the foreground.
    static var inAppDatabase: (any DatabaseWriter)?

    /// Set by the app to whatever else a check-in has to bring up to date — the reminders.
    /// The widget extension has no reminders to settle and leaves it unset.
    static var afterCheckInChange: (() -> Void)?

    private static func openDatabase() throws -> any DatabaseWriter {
        if let inAppDatabase { return inAppDatabase }
        guard let containerURL = AppGroup.containerURL else { throw Failure.unavailable }
        let url = containerURL.appending(component: "db.sqlite")
        guard FileManager.default.fileExists(atPath: url.path()) else { throw Failure.unavailable }

        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        // The app holds the same file open, so wait rather than fail when writes overlap.
        configuration.busyMode = .timeout(5)
        return try DatabasePool(path: url.path(), configuration: configuration)
    }

    /// Habits due on `date`, in the same order and by the same rules as the app's Today tab.
    static func habitsDue(on date: Date) throws -> [ScheduledHabit] {
        let database = try openDatabase()
        let (habits, checkIns, positions) = try database.read { db in
            (
                try Habit.where { !$0.isArchived }.fetchAll(db),
                try CheckIn.all.fetchAll(db),
                // Missing until the app has launched once since the update that added it. The
                // habits still show, in the order they had before.
                (try? HabitPosition.all.fetchAll(db)) ?? []
            )
        }
        return HabitSchedule.habitsDue(
            on: date,
            habits: Habit.inUserOrder(habits, positions: positions),
            checkIns: checkIns,
            calendar: .userPreferred(startWeekOnMonday: AppGroup.startWeekOnMonday)
        )
    }

    /// The habits that are not archived, favourites first — what Siri and Control Center offer
    /// to choose from.
    static func activeHabits() throws -> [Habit] {
        try openDatabase().read { db in
            try Habit.where { !$0.isArchived }.order { ($0.isFavorite.desc(), $0.name) }.fetchAll(db)
        }
    }

    static func habits(ids: [Habit.ID]) throws -> [Habit] {
        try openDatabase().read { db in
            try Habit.where { $0.id.in(ids) }.fetchAll(db)
        }
    }

    static func isCheckedIn(habitID: Habit.ID, on date: Date) throws -> Bool {
        let (startOfDay, endOfDay) = dayBounds(of: date)
        return try openDatabase().read { db in
            try CheckIn
                .where { $0.habitID.eq(habitID) }
                .where { $0.date.between(startOfDay, and: endOfDay) }
                .fetchCount(db) > 0
        }
    }

    /// Checks a habit in for `date`, or clears that day's check-ins if it is already done.
    /// Mirrors what tapping a habit on the Today tab does.
    static func toggleCheckIn(habitID: Habit.ID, on date: Date) throws {
        let isCheckedIn = try isCheckedIn(habitID: habitID, on: date)
        try setCheckIn(habitID: habitID, on: date, done: !isCheckedIn)
    }

    /// Makes `date` checked in for the habit, or not. Asking for what is already the case
    /// changes nothing — saying "check in Meditate" twice does not log it twice.
    ///
    /// - Returns: whether anything changed.
    @discardableResult
    static func setCheckIn(habitID: Habit.ID, on date: Date, done: Bool) throws -> Bool {
        let (startOfDay, endOfDay) = dayBounds(of: date)

        let changed = try openDatabase().write { db in
            let today = CheckIn
                .where { $0.habitID.eq(habitID) }
                .where { $0.date.between(startOfDay, and: endOfDay) }
            let existing = try today.fetchCount(db)

            if done, existing == 0 {
                try CheckIn.upsert { CheckIn.Draft(date: date, habitID: habitID) }.execute(db)
                return true
            } else if !done, existing > 0 {
                try today.delete().execute(db)
                return true
            }
            return false
        }
        if changed {
            didChange()
        }
        return changed
    }

    private static func dayBounds(of date: Date) -> (Date, Date) {
        let calendar = Calendar.userPreferred(startWeekOnMonday: AppGroup.startWeekOnMonday)
        return (date.startOfDay(for: calendar), date.endOfDay(for: calendar))
    }

    /// Every surface showing today's list has to redraw: the widgets, the Control Center
    /// toggles, and — when this runs in the app — whatever `afterCheckInChange` brings along.
    private static func didChange() {
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) {
            ControlCenter.shared.reloadAllControls()
        }
        afterCheckInChange?()
    }
}
