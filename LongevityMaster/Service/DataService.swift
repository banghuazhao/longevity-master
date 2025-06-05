//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import OSLog
import SharingGRDB

private let logger = Logger(subsystem: "Reminders", category: "Database")

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

    switch context {
    case .live:
        let path = URL.documentsDirectory.appending(component: "db.sqlite").path()
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
             "note" TEXT NOT NULL DEFAULT '' 
            ) STRICT 
            """
        )
        .execute(db)

        try #sql(
            """
            CREATE TABLE "checkInDates" ( 
             "id" INTEGER PRIMARY KEY AUTOINCREMENT, 
             "date" TEXT NOT NULL DEFAULT '', 
             "habitID" INTEGER NOT NULL DEFAULT 0 REFERENCES "habits"("id") ON DELETE CASCADE 
            ) STRICT
            """
        )
        .execute(db)
    }
    #if DEBUG
        migrator.registerMigration("Seed database") { db in
            try db.seed {
                for habit in HabitsDataStore.all {
                    habit
                }
            }
        }
    #endif

    try migrator.migrate(database)

    return database
}
