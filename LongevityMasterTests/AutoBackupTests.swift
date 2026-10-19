//
// Created by Banghua Zhao on 20/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData
import Testing
@testable import LongevityMaster

@Suite("Automatic backups")
struct AutoBackupTests {
    let calendar = testCalendar()

    private func temporaryDirectory() -> URL {
        URL.temporaryDirectory.appending(component: "AutoBackupTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    private func snapshot() -> DataExport.Snapshot {
        DataExport.Snapshot(
            habits: [Habit(id: 1, name: "Walk")],
            checkIns: [CheckIn(id: 1, date: testDate("2026-10-01 07:30"), habitID: 1)]
        )
    }

    @Test("One backup a day, however often the app comes forward")
    func oncePerDay() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(try AutoBackup.saveIfDue(snapshot(), now: testDate("2026-10-20 08:00"), calendar: calendar, appVersion: "1.9.0", in: directory))
        #expect(try !AutoBackup.saveIfDue(snapshot(), now: testDate("2026-10-20 21:00"), calendar: calendar, appVersion: "1.9.0", in: directory))
        #expect(try AutoBackup.saveIfDue(snapshot(), now: testDate("2026-10-21 06:00"), calendar: calendar, appVersion: "1.9.0", in: directory))

        let entries = AutoBackup.entries(in: directory, calendar: calendar)
        #expect(entries.map(\.day) == [testDate("2026-10-21"), testDate("2026-10-20")])
    }

    @Test("A backup restores like any exported one")
    func restorable() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try AutoBackup.saveIfDue(snapshot(), now: testDate("2026-10-20 08:00"), calendar: calendar, appVersion: "1.9.0", in: directory)
        let entry = try #require(AutoBackup.entries(in: directory, calendar: calendar).first)
        let plan = try DataRestore.plan(from: Data(contentsOf: entry.url), calendar: calendar, now: testDate("2026-10-20 09:00"))
        #expect(plan.habits.map(\.name) == ["Walk"])
        #expect(plan.checkIns.count == 1)
    }

    @Test("Only the newest seven are kept")
    func keepsAWeek() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        for day in 1...10 {
            let now = calendar.date(byAdding: .day, value: day, to: testDate("2026-10-01 08:00"))!
            try AutoBackup.saveIfDue(snapshot(), now: now, calendar: calendar, appVersion: "", in: directory)
        }
        let entries = AutoBackup.entries(in: directory, calendar: calendar)
        #expect(entries.count == AutoBackup.keepCount)
        #expect(entries.first?.day == testDate("2026-10-11"))
        #expect(entries.last?.day == testDate("2026-10-05"))
    }

    @Test("Nothing is written with no habits, so empty backups never push out good ones")
    func skipsEmpty() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(try !AutoBackup.saveIfDue(DataExport.Snapshot(), now: testDate("2026-10-20 08:00"), calendar: calendar, appVersion: "", in: directory))
        #expect(AutoBackup.entries(in: directory, calendar: calendar).isEmpty)
    }

    @Test("Other files in the folder are neither listed nor pruned")
    func ignoresOtherFiles() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let other = directory.appending(component: "notes.json")
        try Data("{}".utf8).write(to: other)

        try AutoBackup.saveIfDue(snapshot(), now: testDate("2026-10-20 08:00"), calendar: calendar, appVersion: "", in: directory)
        #expect(AutoBackup.entries(in: directory, calendar: calendar).count == 1)
        #expect(FileManager.default.fileExists(atPath: other.path(percentEncoded: false)))
    }

    // MARK: - Rebuilding a database that will not open

    private func damagedFiles(in directory: URL) throws -> [URL] {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try ["db.sqlite", "db.sqlite-wal"].map { name in
            let url = directory.appending(component: name)
            try Data("damaged \(name)".utf8).write(to: url)
            return url
        }
    }

    @Test("Rebuilding keeps the damaged files aside, never deletes them")
    func rebuildKeepsDamagedFiles() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let files = try damagedFiles(in: directory)
        let plan = try DataRestore.plan(
            from: DataExport.backupJSON(snapshot(), now: testDate("2026-10-20 08:00"), calendar: calendar, appVersion: ""),
            calendar: calendar,
            now: testDate("2026-10-20 08:00")
        )

        let rebuilt = try appDatabase()
        try DatabaseRecovery.rebuild(from: plan, now: Date(timeIntervalSince1970: 1_000), files: files, open: { rebuilt })

        let names = Set(try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false)))
        #expect(names == ["db.sqlite.damaged-1000", "db.sqlite-wal.damaged-1000"])
        let habits = try await rebuilt.read { db in try Habit.all.fetchAll(db) }
        #expect(habits.map(\.name) == ["Walk"])
    }

    @Test("A rebuild that fails puts the damaged files back exactly as they were")
    func rebuildFailurePutsBack() throws {
        struct CannotOpen: Error {}
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let files = try damagedFiles(in: directory)

        #expect(throws: CannotOpen.self) {
            try DatabaseRecovery.rebuild(from: DataRestore.Plan(), files: files, open: { throw CannotOpen() })
        }
        let names = Set(try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false)))
        #expect(names == ["db.sqlite", "db.sqlite-wal"])
        #expect(try String(contentsOf: files[0], encoding: .utf8) == "damaged db.sqlite")
    }
}
