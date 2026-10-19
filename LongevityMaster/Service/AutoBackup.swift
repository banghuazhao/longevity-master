//
// Created by Banghua Zhao on 20/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

/// A full backup written once a day without being asked, keeping the last week of them.
///
/// Restore from Backup only helps someone who exported a file beforehand, and most people
/// never do. These are what there is to go back to when they have not: after a mistake, or
/// when the database itself will not open. They are the same files Export Data writes, kept
/// in the app's own Application Support, which is part of the device's backup but separate
/// from the database file.
enum AutoBackup {
    static let keepCount = 7
    private static let prefix = "LongevityMaster-AutoBackup-"

    static var directory: URL {
        URL.applicationSupportDirectory.appending(component: "AutoBackups", directoryHint: .isDirectory)
    }

    struct Entry: Equatable, Identifiable {
        let url: URL
        /// The day it was written for, at its start.
        let day: Date
        var id: URL { url }
    }

    /// The backups on hand, newest first.
    static func entries(in directory: URL = directory, calendar: Calendar = .current) -> [Entry] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))) ?? []
        let days = dayFormatter(calendar)
        return names
            .compactMap { name -> Entry? in
                guard name.hasPrefix(prefix), name.hasSuffix(".json"),
                      let day = days.date(from: String(name.dropFirst(prefix.count).dropLast(".json".count)))
                else { return nil }
                return Entry(url: directory.appending(component: name), day: day)
            }
            .sorted { $0.day > $1.day }
    }

    /// Writes today's backup unless there already is one, then lets the oldest go beyond
    /// `keepCount`. Returns whether it wrote one.
    ///
    /// Nothing is written while there are no habits: a week of empty backups would push out
    /// the very ones someone who has just lost their habits needs.
    @discardableResult
    static func saveIfDue(
        _ snapshot: DataExport.Snapshot,
        now: Date,
        calendar: Calendar,
        appVersion: String,
        in directory: URL = directory
    ) throws -> Bool {
        guard !snapshot.habits.isEmpty else { return false }
        let today = calendar.startOfDay(for: now)
        let existing = entries(in: directory, calendar: calendar)
        guard !existing.contains(where: { calendar.isDate($0.day, inSameDayAs: today) }) else { return false }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(component: prefix + dayFormatter(calendar).string(from: today) + ".json")
        try DataExport.backupJSON(snapshot, now: now, calendar: calendar, appVersion: appVersion)
            .write(to: url, options: .atomic)

        // Only once the new one is safely written.
        for old in entries(in: directory, calendar: calendar).dropFirst(keepCount) {
            try? FileManager.default.removeItem(at: old.url)
        }
        return true
    }

    /// Reads the database and writes today's backup if it is due, away from the main thread.
    /// Failing is quiet: this runs on its own, and tomorrow is another try.
    static func runIfDue(database: any DatabaseWriter) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // The cheap check first, so most trips to the foreground read nothing at all.
        guard !entries(calendar: calendar).contains(where: { calendar.isDate($0.day, inSameDayAs: today) }) else { return }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        do {
            let snapshot = try await database.read { db in try DataExport.Snapshot.fetch(db) }
            _ = try await Task.detached(priority: .utility) {
                try saveIfDue(snapshot, now: Date(), calendar: calendar, appVersion: appVersion)
            }.value
        } catch {
            debugLog("automatic backup failed: \(error)")
        }
    }

    /// The same fixed, POSIX day format the backups themselves use.
    private static func dayFormatter(_ calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
