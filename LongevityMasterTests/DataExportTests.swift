//
// Created by Banghua Zhao on 17/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import LongevityMaster

@Suite("Data export")
struct DataExportTests {
    let calendar = testCalendar()

    /// Shanghai is UTC+8 with no daylight saving, so a moment's local day is easy to predict.
    private var shanghai: Calendar {
        var calendar = testCalendar()
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }

    private func snapshot() -> DataExport.Snapshot {
        var draft = testHabitDraft(name: "Habit")
        draft.icon = "🥗"
        var habits = [
            Habit(id: 1, name: "Walk, then stretch", category: .exercise),
            Habit(id: 2, name: "Eat \"real\" food", category: .diet, isArchived: true),
        ]
        habits[0].note = "Line one\nLine two"
        return DataExport.Snapshot(
            habits: habits,
            positions: [HabitPosition(id: 1, habitID: 2, position: 0)],
            checkIns: [
                CheckIn(id: 3, date: testDate("2026-10-02 07:30"), habitID: 2),
                CheckIn(id: 1, date: testDate("2026-10-01 18:05"), habitID: 1),
                CheckIn(id: 2, date: testDate("2026-10-02 07:30"), habitID: 1),
            ],
            skippedDays: [
                SkippedDay(id: 1, date: testDate("2026-10-05"), habitID: nil),
                SkippedDay(id: 2, date: testDate("2026-10-06"), habitID: 1),
            ],
            reminders: [
                Reminder(id: 1, time: testDate("2026-10-01 20:15"), habitID: nil),
                Reminder(id: 2, title: "Walk", body: "Out the door", time: testDate("2026-10-01 07:00"), habitID: 1),
            ],
            customPrograms: [
                CustomProgram(id: 4, title: "My Plan", durationDays: 14, weeklyFocus: ["Start", "Keep going"], habits: [ProgramHabitTemplate(draft)])
            ],
            enrollments: [
                ProgramEnrollment(id: 7, programID: "custom-4", startDate: testDate("2026-09-30"))
            ],
            programHabits: [
                ProgramHabit(id: 1, enrollmentID: 7, habitID: 2),
                ProgramHabit(id: 2, enrollmentID: 7, habitID: 1),
            ]
        )
    }

    // MARK: - CSV

    @Test("A field is quoted only when it has to be, and its quotes are doubled")
    func csvEscaping() {
        #expect(DataExport.csvField("Walk") == "Walk")
        #expect(DataExport.csvField("🥗 沙拉") == "🥗 沙拉")
        #expect(DataExport.csvField("Walk, then stretch") == "\"Walk, then stretch\"")
        #expect(DataExport.csvField("Eat \"real\" food") == "\"Eat \"\"real\"\" food\"")
        #expect(DataExport.csvField("Line one\nLine two") == "\"Line one\nLine two\"")
        #expect(DataExport.csvField("") == "")
    }

    @Test("Check-ins are listed oldest first, one per row, under a header")
    func csvRows() {
        let csv = DataExport.checkInsCSV(snapshot(), calendar: calendar)
        #expect(csv.hasPrefix("\u{FEFF}"))

        let lines = csv.dropFirst().components(separatedBy: "\r\n")
        #expect(lines == [
            "Date,Time,Habit,Category",
            "2026-10-01,18:05,\"Walk, then stretch\",Exercise",
            "2026-10-02,07:30,\"Walk, then stretch\",Exercise",
            "2026-10-02,07:30,\"Eat \"\"real\"\" food\",Diet",
            "",
        ])
    }

    @Test("Days and times are the user's own, not UTC's")
    func csvUsesLocalTime() {
        var data = snapshot()
        data.checkIns = [CheckIn(id: 1, date: testDate("2026-10-16 20:00"), habitID: 1)]
        let csv = DataExport.checkInsCSV(data, calendar: shanghai)
        #expect(csv.contains("2026-10-17,04:00,"))
    }

    @Test("A check-in whose habit is missing is left out rather than written half-empty")
    func csvSkipsOrphans() {
        var data = snapshot()
        data.checkIns.append(CheckIn(id: 9, date: testDate("2026-10-03 09:00"), habitID: 99))
        let lines = DataExport.checkInsCSV(data, calendar: calendar).components(separatedBy: "\r\n")
        #expect(lines.count == 5)
    }

    @Test("No check-ins still gives a header, so the file opens as a table")
    func csvEmpty() {
        let csv = DataExport.checkInsCSV(DataExport.Snapshot(), calendar: calendar)
        #expect(csv == "\u{FEFF}Date,Time,Habit,Category\r\n")
    }

    // MARK: - JSON

    @Test("The backup reads back as everything that went into it")
    func backupRoundTrip() throws {
        let now = testDate("2026-10-17 09:30")
        let data = try DataExport.backupJSON(snapshot(), now: now, calendar: calendar, appVersion: "1.8.0")
        let backup = try JSONDecoder().decode(DataExport.Backup.self, from: data)

        #expect(backup.format == DataExport.formatName)
        #expect(backup.version == DataExport.formatVersion)
        #expect(backup.exportedAt == "2026-10-17T09:30:00Z")
        #expect(backup.timeZone == "GMT")
        #expect(backup.appVersion == "1.8.0")

        #expect(backup.habits.map(\.id) == [1, 2])
        #expect(backup.habits[0].name == "Walk, then stretch")
        #expect(backup.habits[0].note == "Line one\nLine two")
        #expect(backup.habits[0].category == HabitCategory.exercise.rawValue)
        #expect(backup.habits[0].position == nil)
        #expect(backup.habits[1].isArchived)
        #expect(backup.habits[1].position == 0)

        #expect(backup.checkIns == [
            DataExport.CheckInRecord(habitID: 1, day: "2026-10-01", time: "2026-10-01T18:05:00Z"),
            DataExport.CheckInRecord(habitID: 1, day: "2026-10-02", time: "2026-10-02T07:30:00Z"),
            DataExport.CheckInRecord(habitID: 2, day: "2026-10-02", time: "2026-10-02T07:30:00Z"),
        ])
        #expect(backup.restDays == [
            DataExport.RestDayRecord(day: "2026-10-05", habitID: nil),
            DataExport.RestDayRecord(day: "2026-10-06", habitID: 1),
        ])
        #expect(backup.reminders.map(\.time) == ["20:15", "07:00"])
        #expect(backup.reminders[0].habitID == nil)
        #expect(backup.reminders[1].title == "Walk")

        #expect(backup.customPrograms.count == 1)
        #expect(backup.customPrograms[0].weeklyFocus == ["Start", "Keep going"])
        #expect(backup.customPrograms[0].habits.map(\.icon) == ["🥗"])
        #expect(backup.programRuns == [
            DataExport.ProgramRunRecord(programID: "custom-4", startDay: "2026-09-30", isArchived: false, habitIDs: [1, 2])
        ])
    }

    @Test("Moments carry the user's UTC offset")
    func backupUsesLocalOffset() throws {
        var data = snapshot()
        data.checkIns = [CheckIn(id: 1, date: testDate("2026-10-16 20:00"), habitID: 1)]
        let backup = DataExport.backup(data, now: testDate("2026-10-17 01:00"), calendar: shanghai, appVersion: "")
        #expect(backup.checkIns == [
            DataExport.CheckInRecord(habitID: 1, day: "2026-10-17", time: "2026-10-17T04:00:00+08:00")
        ])
        #expect(backup.exportedAt == "2026-10-17T09:00:00+08:00")
    }

    @Test("The same data always writes the same file")
    func backupIsDeterministic() throws {
        let now = testDate("2026-10-17 09:30")
        let first = try DataExport.backupJSON(snapshot(), now: now, calendar: calendar, appVersion: "1.8.0")
        var shuffled = snapshot()
        shuffled.checkIns.reverse()
        shuffled.habits.reverse()
        let second = try DataExport.backupJSON(shuffled, now: now, calendar: calendar, appVersion: "1.8.0")
        #expect(first == second)
    }

    // MARK: - Database and files

    @Test("A snapshot reads every table, and only the achievements earned")
    func snapshotFromDatabase() async throws {
        try await withTestDatabase { database in
            try await database.write { db in
                let habit = try Habit.upsert { testHabitDraft(name: "Walk") }.returning(\.self).fetchOne(db)!
                try CheckIn.upsert { CheckIn.Draft(date: testDate("2026-10-01 09:00"), habitID: habit.id) }.execute(db)
                try SkippedDay.upsert { SkippedDay.Draft(date: testDate("2026-10-02"), habitID: nil) }.execute(db)
                var first = try Achievement.all.fetchAll(db)[0]
                first.isUnlocked = true
                first.unlockedDate = testDate("2026-10-01 09:00")
                try Achievement.update(first).execute(db)
            }

            let snapshot = try await database.read { db in
                try DataExport.Snapshot.fetch(db)
            }
            #expect(snapshot.habits.map(\.name) == ["Walk"])
            #expect(snapshot.checkIns.count == 1)
            #expect(snapshot.skippedDays.count == 1)
            // The default evening reminder every install starts with.
            #expect(snapshot.reminders.count == 1)
            #expect(snapshot.achievements.map(\.isUnlocked) == [true])
        }
    }

    @Test("Writing leaves exactly the two new files behind")
    func writeFiles() throws {
        let directory = URL.temporaryDirectory.appending(component: "DataExportTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }

        // Left over from an earlier export; it should not survive the next one.
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("old".utf8).write(to: directory.appending(component: "stale.csv"))

        let files = try DataExport.write(
            snapshot(),
            now: testDate("2026-10-17 09:30"),
            calendar: calendar,
            appVersion: "1.8.0",
            to: directory
        )
        #expect(files.checkInsCSV.lastPathComponent == "LongevityMaster-CheckIns-2026-10-17.csv")
        #expect(files.backupJSON.lastPathComponent == "LongevityMaster-Backup-2026-10-17.json")
        #expect(files.habitCount == 2)
        #expect(files.checkInCount == 3)

        let contents = try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))
        #expect(Set(contents) == [files.checkInsCSV.lastPathComponent, files.backupJSON.lastPathComponent])

        let csv = try String(contentsOf: files.checkInsCSV, encoding: .utf8)
        #expect(csv.contains("Walk, then stretch"))
        let backup = try JSONDecoder().decode(DataExport.Backup.self, from: Data(contentsOf: files.backupJSON))
        #expect(backup.checkIns.count == 3)
    }
}
