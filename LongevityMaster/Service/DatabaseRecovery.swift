//
// Created by Banghua Zhao on 20/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

/// Starting over from a backup when the database itself will not open.
///
/// The files that would not open are moved aside rather than deleted — renamed in place, so
/// it costs no space and needs nothing but the folder — and a new database is built and
/// filled from the backup. If any of that fails, the new files go and the old ones are put
/// back exactly where they were, so trying can never leave things worse.
enum DatabaseRecovery {
    enum Failure: Error {
        case couldNotMoveAside
    }

    /// Replaces the database that would not open with one rebuilt from `plan`. The app has
    /// to be restarted afterwards: everything running is still on the stand-in.
    ///
    /// `files` and `open` are the live database's unless a test says otherwise.
    static func rebuild(
        from plan: DataRestore.Plan,
        now: Date = Date(),
        files: [URL] = liveDatabaseFiles(),
        open: () throws -> any DatabaseWriter = { try appDatabase() }
    ) throws {
        let fileManager = FileManager.default
        let stamp = Int(now.timeIntervalSince1970)
        var moved: [(original: URL, aside: URL)] = []

        func putBack() {
            for (original, _) in moved {
                try? fileManager.removeItem(at: original)
            }
            // Anything else the attempt left beside them, such as a log the new database
            // started that the damaged one never had.
            if let main = moved.first?.original {
                for suffix in ["-wal", "-shm"] {
                    try? fileManager.removeItem(at: URL(filePath: main.path(percentEncoded: false) + suffix))
                }
            }
            for (original, aside) in moved {
                try? fileManager.moveItem(at: aside, to: original)
            }
        }

        for file in files {
            let aside = URL(filePath: file.path(percentEncoded: false) + ".damaged-\(stamp)")
            do {
                try fileManager.moveItem(at: file, to: aside)
                moved.append((file, aside))
            } catch {
                putBack()
                throw Failure.couldNotMoveAside
            }
        }

        do {
            // Closed again as soon as this block ends; the app opens it afresh when it is
            // next started.
            let database = try open()
            try database.write { db in
                try DataRestore.replaceAll(with: plan, in: db)
            }
        } catch {
            putBack()
            throw error
        }
    }
}
