//
// Created by Banghua Zhao on 19/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import LongevityMaster

@Suite("Data restore")
struct DataRestoreTests {
    let calendar = testCalendar()
    let now = testDate("2026-10-19 09:30")

    /// The rows' types are not `Equatable`; every field shows in their description.
    private func described<T>(_ rows: [T]) -> [String] {
        rows.map { String(describing: $0) }
    }

    /// A little of everything the backup holds, written through the app's own schema.
    private func fillDatabase(_ database: any DatabaseWriter) async throws {
        try await database.write { db in
            try Reminder.all.delete().execute(db)
            let walk = try Habit.upsert { testHabitDraft(name: "Walk, then stretch", category: .exercise) }
                .returning(\.self).fetchOne(db)!
            var archived = testHabitDraft(name: "Eat \"real\" food", isArchived: true)
            archived.note = "Line one\nLine two"
            archived.isFavorite = true
            let food = try Habit.upsert { archived }.returning(\.self).fetchOne(db)!

            try HabitPosition.insert { HabitPosition.Draft(habitID: food.id, position: 0) }.execute(db)
            try CheckIn.insert { CheckIn.Draft(date: testDate("2026-10-01 18:05"), habitID: walk.id) }.execute(db)
            try CheckIn.insert { CheckIn.Draft(date: testDate("2026-10-02 07:30"), habitID: walk.id) }.execute(db)
            try CheckIn.insert { CheckIn.Draft(date: testDate("2026-10-02 07:30"), habitID: food.id) }.execute(db)
            try SkippedDay.insert { SkippedDay.Draft(date: testDate("2026-10-05 12:00"), habitID: nil) }.execute(db)
            try SkippedDay.insert { SkippedDay.Draft(date: testDate("2026-10-06 12:00"), habitID: walk.id) }.execute(db)
            try Reminder.insert { Reminder.Draft(time: testDate("2026-10-01 20:15"), habitID: nil) }.execute(db)
            try Reminder.insert {
                Reminder.Draft(title: "Walk", body: "Out the door", time: testDate("2026-10-01 07:00"), habitID: walk.id)
            }.execute(db)

            let program = try CustomProgram.insert {
                CustomProgram.Draft(title: "My Plan", durationDays: 14, weeklyFocus: ["Start", "Keep going"])
            }.returning(\.self).fetchOne(db)!
            let run = try ProgramEnrollment.insert {
                ProgramEnrollment.Draft(programID: Program.id(forCustom: program.id), startDate: testDate("2026-09-30 10:00"))
            }.returning(\.self).fetchOne(db)!
            try ProgramHabit.insert { ProgramHabit.Draft(enrollmentID: run.id, habitID: walk.id) }.execute(db)
            try ProgramHabit.insert { ProgramHabit.Draft(enrollmentID: run.id, habitID: food.id) }.execute(db)

            var first = try Achievement.all.order(by: \.id).fetchAll(db)[0]
            first.isUnlocked = true
            first.unlockedDate = testDate("2026-10-02 07:30")
            first.habitID = walk.id
            try Achievement.update(first).execute(db)
        }
    }

    private func backupJSON(_ database: any DatabaseWriter) async throws -> Data {
        let snapshot = try await database.read { db in try DataExport.Snapshot.fetch(db) }
        return try DataExport.backupJSON(snapshot, now: now, calendar: calendar, appVersion: "1.9.0")
    }

    private func restore(_ data: Data, into database: any DatabaseWriter) async throws {
        let plan = try DataRestore.plan(from: data, calendar: calendar, now: now)
        try await database.write { db in
            try DataRestore.replaceAll(with: plan, in: db)
        }
    }

    // MARK: - Round trip

    @Test("Restoring a backup over other data gives back exactly what was exported")
    func roundTrip() async throws {
        try await withTestDatabase { database in
            try await fillDatabase(database)
            let before = try await database.read { db in try DataExport.Snapshot.fetch(db) }
            let data = try await backupJSON(database)

            // What the device holds by the time the backup comes back: something else entirely.
            try await database.write { db in
                try Habit.all.delete().execute(db)
                try ProgramEnrollment.all.delete().execute(db)
                try CustomProgram.all.delete().execute(db)
                try Reminder.all.delete().execute(db)
                try SkippedDay.all.delete().execute(db)
                let other = try Habit.upsert { testHabitDraft(name: "Something else") }.returning(\.self).fetchOne(db)!
                try CheckIn.insert { CheckIn.Draft(date: testDate("2026-10-18 08:00"), habitID: other.id) }.execute(db)
                try Reminder.insert { Reminder.Draft(time: testDate("2026-10-18 06:00"), habitID: other.id) }.execute(db)
            }

            try await restore(data, into: database)
            let after = try await database.read { db in try DataExport.Snapshot.fetch(db) }

            #expect(described(after.habits) == described(before.habits))
            #expect(after.positions.map { [$0.habitID, $0.position] } == before.positions.map { [$0.habitID, $0.position] })
            #expect(Set(after.checkIns.map { "\($0.habitID) \($0.date)" }) == Set(before.checkIns.map { "\($0.habitID) \($0.date)" }))
            #expect(
                Set(after.skippedDays.map { "\(String(describing: $0.habitID)) \(calendar.startOfDay(for: $0.date))" })
                    == Set(before.skippedDays.map { "\(String(describing: $0.habitID)) \(calendar.startOfDay(for: $0.date))" })
            )
            #expect(after.reminders.map(\.title) == before.reminders.map(\.title))
            #expect(after.reminders.map(\.body) == before.reminders.map(\.body))
            #expect(after.reminders.map(\.habitID) == before.reminders.map(\.habitID))
            #expect(
                after.reminders.map { calendar.dateComponents([.hour, .minute], from: $0.time) }
                    == before.reminders.map { calendar.dateComponents([.hour, .minute], from: $0.time) }
            )
            #expect(described(after.customPrograms) == described(before.customPrograms))
            #expect(after.enrollments.map(\.programID) == before.enrollments.map(\.programID))
            #expect(after.enrollments.map(\.startDate) == [testDate("2026-09-30")])
            #expect(Set(after.programHabits.map(\.habitID)) == Set(before.programHabits.map(\.habitID)))
            #expect(after.achievements.map(\.title) == before.achievements.map(\.title))
            #expect(after.achievements.map(\.unlockedDate) == before.achievements.map(\.unlockedDate))

            // And a backup of the restored data is the same file, apart from nothing.
            #expect(try await backupJSON(database) == data)
        }
    }

    @Test("Restored reminders get notification ids of their own")
    func freshNotificationIDs() async throws {
        try await withTestDatabase { database in
            try await fillDatabase(database)
            let before = try await database.read { db in try Reminder.all.fetchAll(db) }
            try await restore(try await backupJSON(database), into: database)
            let after = try await database.read { db in try Reminder.all.fetchAll(db) }
            #expect(after.count == before.count)
            #expect(Set(after.map(\.notificationID)).isDisjoint(with: before.map(\.notificationID)))
        }
    }

    @Test("An achievement earned here but not in the backup is locked again")
    func achievementsFollowTheBackup() async throws {
        try await withTestDatabase { database in
            let data = try await backupJSON(database)
            try await database.write { db in
                var first = try Achievement.all.order(by: \.id).fetchAll(db)[0]
                first.isUnlocked = true
                first.unlockedDate = now
                try Achievement.update(first).execute(db)
            }
            try await restore(data, into: database)
            let unlocked = try await database.read { db in
                try Achievement.where { $0.isUnlocked }.fetchCount(db)
            }
            #expect(unlocked == 0)
        }
    }

    @Test("Achievements are found by what they are, whatever language their titles are in")
    func achievementsAcrossLanguages() async throws {
        try await withTestDatabase { database in
            try await fillDatabase(database)
            let data = try await backupJSON(database)
            // As if this device had set its achievements up in another language.
            try await database.write { db in
                for var achievement in try Achievement.all.fetchAll(db) {
                    achievement.title = "译 " + achievement.title
                    achievement.isUnlocked = false
                    achievement.unlockedDate = nil
                    try Achievement.update(achievement).execute(db)
                }
            }
            try await restore(data, into: database)
            let unlocked = try await database.read { db in
                try Achievement.where { $0.isUnlocked }.fetchAll(db)
            }
            #expect(unlocked.count == 1)
            #expect(unlocked.first?.unlockedDate == testDate("2026-10-02 07:30"))
        }
    }

    @Test("A version 1 backup still finds achievements by title")
    func versionOneAchievements() async throws {
        try await withTestDatabase { database in
            try await fillDatabase(database)
            var backup = try JSONDecoder().decode(DataExport.Backup.self, from: try await backupJSON(database))
            backup.version = 1
            for index in backup.achievements.indices {
                backup.achievements[index].kind = nil
                backup.achievements[index].target = nil
                backup.achievements[index].category = nil
            }
            try await database.write { db in
                try Achievement.update { $0.isUnlocked = false }.execute(db)
            }
            try await restore(try JSONEncoder().encode(backup), into: database)
            let unlocked = try await database.read { db in
                try Achievement.where { $0.isUnlocked }.fetchCount(db)
            }
            #expect(unlocked == 1)
        }
    }

    // MARK: - Files that are not backups

    @Test("A file that is not a backup is turned away as one")
    func notABackup() {
        for text in ["", "hello", "[1, 2, 3]", #"{"format": "something-else", "version": 1}"#, #"{"format": "longevity-master-backup", "version": 0}"#] {
            #expect(throws: DataRestore.Failure.notABackup) {
                try DataRestore.plan(from: Data(text.utf8), calendar: calendar, now: now)
            }
        }
    }

    @Test("A backup from a later version says so, even when its shape has moved on")
    func newerVersion() {
        let text = #"{"format": "longevity-master-backup", "version": 99, "everything": "different"}"#
        #expect(throws: DataRestore.Failure.newerVersion) {
            try DataRestore.plan(from: Data(text.utf8), calendar: calendar, now: now)
        }
    }

    private func backup() -> DataExport.Backup {
        DataExport.Backup(
            format: DataExport.formatName,
            version: DataExport.formatVersion,
            exportedAt: "2026-10-19T09:30:00Z",
            timeZone: "GMT",
            appVersion: "1.9.0",
            habits: [
                DataExport.HabitRecord(
                    id: 1, name: "Walk", icon: "🚶", category: 1, frequency: 0, frequencyDetail: "1,2,3,4,5,6,7",
                    antiAgingRating: 3, color: 0, note: "", isFavorite: false, isArchived: false, position: nil
                )
            ],
            checkIns: [DataExport.CheckInRecord(habitID: 1, day: "2026-10-01", time: "2026-10-01T18:05:00Z")],
            restDays: [DataExport.RestDayRecord(day: "2026-10-05", habitID: nil)],
            reminders: [DataExport.ReminderRecord(habitID: 1, title: "Walk", body: "Go", time: "07:00")],
            customPrograms: [],
            programRuns: [],
            achievements: []
        )
    }

    @Test("A sound backup reads as its rows")
    func soundBackup() throws {
        let plan = try DataRestore.plan(from: backup(), calendar: calendar, now: now)
        #expect(plan.habits.map(\.name) == ["Walk"])
        #expect(plan.checkIns.map(\.date) == [testDate("2026-10-01 18:05")])
        #expect(plan.skippedDays.map(\.date) == [testDate("2026-10-05 12:00")])
        #expect(plan.reminders.map(\.time) == [testDate("2026-10-19 07:00")])
        #expect(plan.exportedAt == now)
    }

    @Test("A backup that does not hold together is refused whole", arguments: [
        "check-in for a missing habit",
        "rest day for a missing habit",
        "reminder for a missing habit",
        "program run with a missing habit",
        "unknown category",
        "unknown frequency",
        "habit listed twice",
        "check-in time that is not a time",
        "rest day that is not a day",
        "reminder time that is not a time",
    ])
    func damaged(_ damage: String) {
        var backup = backup()
        switch damage {
        case "check-in for a missing habit": backup.checkIns[0].habitID = 9
        case "rest day for a missing habit": backup.restDays[0].habitID = 9
        case "reminder for a missing habit": backup.reminders[0].habitID = 9
        case "program run with a missing habit":
            backup.programRuns = [DataExport.ProgramRunRecord(programID: "custom-1", startDay: "2026-10-01", isArchived: false, habitIDs: [9])]
        case "unknown category": backup.habits[0].category = 42
        case "unknown frequency": backup.habits[0].frequency = 42
        case "habit listed twice": backup.habits.append(backup.habits[0])
        case "check-in time that is not a time": backup.checkIns[0].time = "yesterday"
        case "rest day that is not a day": backup.restDays[0].day = "2026-13-45"
        case "reminder time that is not a time": backup.reminders[0].time = "7am"
        default: Issue.record("no such damage: \(damage)")
        }
        #expect(throws: DataRestore.Failure.damaged) {
            try DataRestore.plan(from: backup, calendar: calendar, now: now)
        }
    }

    @Test("A restore that fails part-way leaves the database as it was")
    func failureRollsBack() async throws {
        try await withTestDatabase { database in
            try await fillDatabase(database)
            let before = try await database.read { db in try DataExport.Snapshot.fetch(db) }

            // Past the checks `plan(from:)` makes, so only the database can catch it.
            var plan = try DataRestore.plan(from: backup(), calendar: calendar, now: now)
            plan.checkIns.append(CheckIn.Draft(date: now, habitID: 999))

            await #expect(throws: (any Error).self) {
                try await database.write { db in
                    try DataRestore.replaceAll(with: plan, in: db)
                }
            }

            let after = try await database.read { db in try DataExport.Snapshot.fetch(db) }
            #expect(described(after.habits) == described(before.habits))
            #expect(after.checkIns.count == before.checkIns.count)
            #expect(after.reminders.map(\.notificationID) == before.reminders.map(\.notificationID))
            #expect(after.achievements.map(\.title) == before.achievements.map(\.title))
        }
    }
}
