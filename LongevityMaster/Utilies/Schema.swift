//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import OSLog
import SQLiteData

private let logger = Logger(subsystem: "Reminders", category: "Database")

/// The database lives in the shared App Group container so the widget extension can read it.
/// If the group is unavailable — entitlement missing, or not yet provisioned — fall back to the
/// app's own Documents directory: the app keeps working and only the widget goes without data.
private func liveDatabaseURL() -> URL {
    let legacyURL = URL.documentsDirectory.appending(component: "db.sqlite")
    guard let containerURL = AppGroup.containerURL else { return legacyURL }

    let sharedURL = containerURL.appending(component: "db.sqlite")
    let fileManager = FileManager.default
    guard !fileManager.fileExists(atPath: sharedURL.path()) else { return sharedURL }
    guard fileManager.fileExists(atPath: legacyURL.path()) else { return sharedURL }

    // Copy the whole set before deleting anything: a database moved without its write-ahead
    // log is a database missing its most recent transactions.
    let suffixes = ["", "-wal", "-shm"]
    do {
        for suffix in suffixes {
            let source = URL(filePath: legacyURL.path() + suffix)
            guard fileManager.fileExists(atPath: source.path()) else { continue }
            try fileManager.copyItem(at: source, to: URL(filePath: sharedURL.path() + suffix))
        }
    } catch {
        logger.error("failed to move database into app group: \(error.localizedDescription)")
        for suffix in suffixes {
            try? fileManager.removeItem(at: URL(filePath: sharedURL.path() + suffix))
        }
        return legacyURL
    }

    for suffix in suffixes {
        try? fileManager.removeItem(at: URL(filePath: legacyURL.path() + suffix))
    }
    logger.info("moved database into app group container")
    return sharedURL
}

/// The files the live database is kept in, wherever they are now — the shared container or
/// the app's own Documents — so the app can hand them over when it cannot open them itself.
/// Only looks: unlike `liveDatabaseURL()`, it never moves anything.
func liveDatabaseFiles() -> [URL] {
    var candidates = [URL.documentsDirectory.appending(component: "db.sqlite")]
    if let containerURL = AppGroup.containerURL {
        candidates.insert(containerURL.appending(component: "db.sqlite"), at: 0)
    }
    let fileManager = FileManager.default
    guard let database = candidates.first(where: { fileManager.fileExists(atPath: $0.path(percentEncoded: false)) }) else { return [] }
    return ["", "-wal", "-shm"]
        .map { URL(filePath: database.path(percentEncoded: false) + $0) }
        .filter { fileManager.fileExists(atPath: $0.path(percentEncoded: false)) }
}

/// Opens the app's database and brings its schema up to date.
///
/// `inMemory` builds a throwaway database with the same schema even in the live app — what
/// the app runs on while its real one cannot be opened, so nothing that touches the database
/// at launch has to cope with there being none.
func appDatabase(inMemory: Bool = false) throws -> any DatabaseWriter {
    @Dependency(\.context) var context

    let database: any DatabaseWriter

    var configuration = Configuration()
    configuration.foreignKeysEnabled = true
    configuration.prepareDatabase { db in
        #if DEBUG
            db.trace(options: .profile) {
                if context == .preview {
                    print($0.expandedDescription)
                } else {
                    logger.debug("\($0.expandedDescription)")
                }
            }
        #endif
    }

    // The widget reads and writes this same file from another process, so wait for the lock
    // instead of failing outright when the two overlap.
    configuration.busyMode = .timeout(5)

    switch context {
    case .live where !inMemory:
        let path = liveDatabaseURL().path()
        logger.info("open \(path)")
        database = try DatabasePool(path: path, configuration: configuration)
    case .live, .preview, .test:
        database = try DatabaseQueue(configuration: configuration)
    }

    var migrator = DatabaseMigrator()
    #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
    #endif
    migrator.registerMigration("Create tables") { db in
        try #sql(
            """
            CREATE TABLE "habits" (
             "id" INTEGER PRIMARY KEY AUTOINCREMENT, 
             "name" TEXT NOT NULL DEFAULT '', 
             "category" INTEGER NOT NULL DEFAULT 0, 
             "frequency" INTEGER NOT NULL DEFAULT 0, 
             "frequencyDetail" TEXT NOT NULL DEFAULT '', 
             "antiAgingRating" INTEGER NOT NULL DEFAULT 0, 
             "icon" TEXT NOT NULL DEFAULT '', 
             "color" TEXT NOT NULL DEFAULT '', 
             "note" TEXT NOT NULL DEFAULT '', 
             "isFavorite" INTEGER NOT NULL DEFAULT 0, 
             "isArchived" INTEGER NOT NULL DEFAULT 0 
            ) STRICT 
            """
        )
        .execute(db)

        try #sql(
            """
            CREATE TABLE "checkIns" ( 
             "id" INTEGER PRIMARY KEY AUTOINCREMENT, 
             "date" TEXT NOT NULL DEFAULT '', 
             "habitID" INTEGER NOT NULL DEFAULT 0 REFERENCES "habits"("id") ON DELETE CASCADE 
            ) STRICT
            """
        )
        .execute(db)
        
        try #sql(
            """
            CREATE TABLE "reminders" (
             "id" INTEGER PRIMARY KEY AUTOINCREMENT,
             "title" TEXT NOT NULL DEFAULT '',
             "body" TEXT NOT NULL DEFAULT '',
             "time" TEXT NOT NULL DEFAULT '',
             "habitID" INTEGER REFERENCES "habits"("id") ON DELETE CASCADE,
             "notificationID" TEXT NOT NULL DEFAULT ''
            ) STRICT
            """
        )
        .execute(db)
        
        try #sql(
            """
            CREATE TABLE "achievements" (
             "id" INTEGER PRIMARY KEY AUTOINCREMENT,
             "title" TEXT NOT NULL DEFAULT '',
             "description" TEXT NOT NULL DEFAULT '',
             "icon" TEXT NOT NULL DEFAULT '',
             "type" INTEGER NOT NULL DEFAULT 0,
             "criteria" TEXT NOT NULL DEFAULT '',
             "isUnlocked" INTEGER NOT NULL DEFAULT 0,
             "unlockedDate" TEXT,
             "habitID" INTEGER REFERENCES "habits"("id") ON DELETE SET NULL
            ) STRICT
            """
        )
        .execute(db)
    }
    #if DEBUG
        migrator.registerMigration("Seed database") { db in
            try db.seed {
                HabitsDataStore.debugSeed
            }
        }
    #endif
    
    // Inserts the row only. Registering its notification is deliberately left to
    // `syncAllReminders()` at launch: a detached Task started here outlives the migration it
    // was written in and races every migration registered after it — it was reading a table
    // two migrations further down before that table existed.
    migrator.registerMigration("Add default daily reminder") { db in
        let defaultTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
        var defaultReminder = Reminder.Draft()
        defaultReminder.time = defaultTime
        try Reminder.upsert { defaultReminder }.execute(db)
    }
    
    migrator.registerMigration("Add achievements") { db in
        try Achievement.upsert { AchievementDefinitions.all }.execute(db)
    }

    // The "Brush & floss teeth" gallery habit shipped as 14 days each week, which a
    // 7-day week can never satisfy, so it was stuck at "n/14 this week" forever.
    // Repair any habit copied from the gallery before the seed data was corrected.
    migrator.registerMigration("Clamp weekly frequency to 7 days") { db in
        try #sql(
            """
            UPDATE "habits"
            SET "frequencyDetail" = '7'
            WHERE "frequency" = \(bind: HabitFrequency.nDaysEachWeek.rawValue)
             AND CAST("frequencyDetail" AS INTEGER) > 7
            """
        )
        .execute(db)
    }

    // Every habit-scoped lookup — the Today list, a habit's calendar, the achievement checks,
    // and the cascade when a habit is deleted — scanned the whole table without these.
    migrator.registerMigration("Index check-ins by habit and date") { db in
        try #sql(
            """
            CREATE INDEX IF NOT EXISTS "checkIns_habitID" ON "checkIns"("habitID")
            """
        )
        .execute(db)

        try #sql(
            """
            CREATE INDEX IF NOT EXISTS "checkIns_date" ON "checkIns"("date")
            """
        )
        .execute(db)
    }

    // Days the user has declared off. Streaks count through these rather than breaking on
    // them, so a deliberate rest day costs nothing.
    migrator.registerMigration("Add skipped days") { db in
        try #sql(
            """
            CREATE TABLE "skippedDays" (
             "id" INTEGER PRIMARY KEY AUTOINCREMENT,
             "date" TEXT NOT NULL DEFAULT '',
             "habitID" INTEGER REFERENCES "habits"("id") ON DELETE CASCADE
            ) STRICT
            """
        )
        .execute(db)

        // Every read of this table is "which days were off", either for one habit or for all
        // of them — the same two shapes the check-in indexes exist for.
        try #sql(
            """
            CREATE INDEX IF NOT EXISTS "skippedDays_date" ON "skippedDays"("date")
            """
        )
        .execute(db)

        try #sql(
            """
            CREATE INDEX IF NOT EXISTS "skippedDays_habitID" ON "skippedDays"("habitID")
            """
        )
        .execute(db)
    }

    // Guided programs. The programs themselves are defined in code; these record which ones
    // the user started, and which of their habits each one is tracking.
    migrator.registerMigration("Add programs") { db in
        try #sql(
            """
            CREATE TABLE "programEnrollments" (
             "id" INTEGER PRIMARY KEY AUTOINCREMENT,
             "programID" TEXT NOT NULL DEFAULT '',
             "startDate" TEXT NOT NULL DEFAULT '',
             "isArchived" INTEGER NOT NULL DEFAULT 0
            ) STRICT
            """
        )
        .execute(db)

        try #sql(
            """
            CREATE TABLE "programHabits" (
             "id" INTEGER PRIMARY KEY AUTOINCREMENT,
             "enrollmentID" INTEGER NOT NULL REFERENCES "programEnrollments"("id") ON DELETE CASCADE,
             "habitID" INTEGER NOT NULL REFERENCES "habits"("id") ON DELETE CASCADE
            ) STRICT
            """
        )
        .execute(db)

        try #sql(
            """
            CREATE INDEX IF NOT EXISTS "programHabits_enrollmentID" ON "programHabits"("enrollmentID")
            """
        )
        .execute(db)

        try #sql(
            """
            CREATE INDEX IF NOT EXISTS "programHabits_habitID" ON "programHabits"("habitID")
            """
        )
        .execute(db)
    }

    // Programs the user makes. Their habits are stored as JSON snapshots, not references:
    // a program is a plan to start (and start again), and starting it adds or reuses habits
    // the same way a guided program does.
    migrator.registerMigration("Add custom programs") { db in
        try #sql(
            """
            CREATE TABLE "customPrograms" (
             "id" INTEGER PRIMARY KEY AUTOINCREMENT,
             "title" TEXT NOT NULL DEFAULT '',
             "icon" TEXT NOT NULL DEFAULT '',
             "color" INTEGER NOT NULL DEFAULT 0,
             "durationDays" INTEGER NOT NULL DEFAULT 21,
             "summary" TEXT NOT NULL DEFAULT '',
             "weeklyFocus" TEXT NOT NULL DEFAULT '[]',
             "habits" TEXT NOT NULL DEFAULT '[]'
            ) STRICT
            """
        )
        .execute(db)
    }

    // The user's own order for their habits. Its own table rather than a column on `habits`;
    // `HabitPosition` explains why.
    migrator.registerMigration("Add habit positions") { db in
        try #sql(
            """
            CREATE TABLE "habitPositions" (
             "id" INTEGER PRIMARY KEY AUTOINCREMENT,
             "habitID" INTEGER NOT NULL UNIQUE REFERENCES "habits"("id") ON DELETE CASCADE,
             "position" INTEGER NOT NULL DEFAULT 0
            ) STRICT
            """
        )
        .execute(db)
    }

    try migrator.migrate(database)

    return database
}
