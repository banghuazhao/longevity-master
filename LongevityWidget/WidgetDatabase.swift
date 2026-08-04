//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

/// The widget's own connection to the database the app keeps in the shared App Group container.
///
/// It deliberately does not run migrations: the app owns the schema, and a widget refresh is the
/// wrong moment to be altering tables. If the app has never launched there is nothing to read.
enum WidgetDatabase {
    enum Failure: Error {
        /// No App Group container, or the app has not created its database yet.
        case unavailable
    }

    private static func openDatabase() throws -> DatabasePool {
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
        let (habits, checkIns) = try database.read { db in
            (
                try Habit.where { !$0.isArchived }.order { $0.isFavorite.desc() }.fetchAll(db),
                try CheckIn.all.fetchAll(db)
            )
        }
        return HabitSchedule.habitsDue(
            on: date,
            habits: habits,
            checkIns: checkIns,
            calendar: .userPreferred(startWeekOnMonday: AppGroup.startWeekOnMonday)
        )
    }

    /// Checks a habit in for `date`, or clears that day's check-ins if it is already done.
    /// Mirrors what tapping a habit on the Today tab does.
    static func toggleCheckIn(habitID: Habit.ID, on date: Date) throws {
        let database = try openDatabase()
        let calendar = Calendar.userPreferred(startWeekOnMonday: AppGroup.startWeekOnMonday)
        let startOfDay = date.startOfDay(for: calendar)
        let endOfDay = date.endOfDay(for: calendar)

        try database.write { db in
            let existing = try CheckIn
                .where { $0.habitID.eq(habitID) }
                .where { $0.date.between(startOfDay, and: endOfDay) }
                .fetchCount(db)

            if existing > 0 {
                try CheckIn
                    .where { $0.habitID.eq(habitID) }
                    .where { $0.date.between(startOfDay, and: endOfDay) }
                    .delete()
                    .execute(db)
            } else {
                try CheckIn.upsert { CheckIn.Draft(date: date, habitID: habitID) }.execute(db)
            }
        }
    }
}
