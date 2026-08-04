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

func appDatabase() throws -> any DatabaseWriter {
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
    case .live:
        let path = liveDatabaseURL().path()
        logger.info("open \(path)")
        database = try DatabasePool(path: path, configuration: configuration)
    case .preview, .test:
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
                HabitsDataStore.all
            }
        }
    #endif
    
    migrator.registerMigration("Add default daily reminder") { db in
        let defaultTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
        var defaultReminder = Reminder.Draft()
        defaultReminder.time = defaultTime
        let reminder = try Reminder.upsert { defaultReminder }.returning(\.self).fetchOne(db)
        if let reminder {
            Task {
                await NotificationService.shared.scheduleReminder(reminder)
            }
        }
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

    try migrator.migrate(database)

    return database
}
