//
// Created by Banghua Zhao on 17/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

/// Everything the user has recorded, written out as files they can keep: a CSV of check-ins
/// to open in a spreadsheet, and a JSON backup of every table holding their own data, complete
/// enough for an import to rebuild it from.
///
/// Read-only by design. Nothing here writes to the database, so an export can never be the
/// thing that loses data.
enum DataExport {
    /// The rows an export is built from, read in one transaction so the two files agree.
    struct Snapshot {
        var habits: [Habit] = []
        var positions: [HabitPosition] = []
        var checkIns: [CheckIn] = []
        var skippedDays: [SkippedDay] = []
        var reminders: [Reminder] = []
        var customPrograms: [CustomProgram] = []
        var enrollments: [ProgramEnrollment] = []
        var programHabits: [ProgramHabit] = []
        var achievements: [Achievement] = []

        static func fetch(_ db: Database) throws -> Snapshot {
            Snapshot(
                habits: try Habit.all.fetchAll(db),
                positions: try HabitPosition.all.fetchAll(db),
                checkIns: try CheckIn.all.fetchAll(db),
                skippedDays: try SkippedDay.all.fetchAll(db),
                reminders: try Reminder.all.fetchAll(db),
                customPrograms: try CustomProgram.all.fetchAll(db),
                enrollments: try ProgramEnrollment.all.fetchAll(db),
                programHabits: try ProgramHabit.all.fetchAll(db),
                achievements: try Achievement.where { $0.isUnlocked }.fetchAll(db)
            )
        }
    }

    /// The two files of one export, and what went into them.
    struct Files: Equatable {
        let checkInsCSV: URL
        let backupJSON: URL
        let habitCount: Int
        let checkInCount: Int
    }

    /// Writes both files into `directory`, replacing whatever an earlier export left there.
    static func write(
        _ snapshot: Snapshot,
        now: Date,
        calendar: Calendar,
        appVersion: String,
        to directory: URL
    ) throws -> Files {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: directory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let stamp = dayFormatter(calendar).string(from: now)
        let csvURL = directory.appending(component: "LongevityMaster-CheckIns-\(stamp).csv")
        let jsonURL = directory.appending(component: "LongevityMaster-Backup-\(stamp).json")

        try Data(checkInsCSV(snapshot, calendar: calendar).utf8).write(to: csvURL, options: .atomic)
        try backupJSON(snapshot, now: now, calendar: calendar, appVersion: appVersion)
            .write(to: jsonURL, options: .atomic)

        return Files(
            checkInsCSV: csvURL,
            backupJSON: jsonURL,
            habitCount: snapshot.habits.count,
            checkInCount: snapshot.checkIns.count
        )
    }

    // MARK: - CSV

    /// One row per check-in, oldest first, in the user's own time zone — what someone opening
    /// it in Numbers or Excel expects to read.
    ///
    /// Starts with a byte-order mark: without one, Excel reads UTF-8 as the system's legacy
    /// encoding and every emoji and Chinese habit name comes out garbled.
    static func checkInsCSV(_ snapshot: Snapshot, calendar: Calendar) -> String {
        let habitsByID = Dictionary(snapshot.habits.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let days = dayFormatter(calendar)
        let times = timeFormatter(calendar)

        var rows = [
            csvRow([
                String(localized: "Date"),
                String(localized: "Time"),
                String(localized: "Habit"),
                String(localized: "Category"),
            ])
        ]
        for checkIn in snapshot.checkIns.sorted(by: { ($0.date, $0.id) < ($1.date, $1.id) }) {
            guard let habit = habitsByID[checkIn.habitID] else { continue }
            rows.append(csvRow([
                days.string(from: checkIn.date),
                times.string(from: checkIn.date),
                habit.name,
                habit.category.plainTitle,
            ]))
        }
        return "\u{FEFF}" + rows.joined(separator: "\r\n") + "\r\n"
    }

    /// RFC 4180: a field holding a comma, a quote or a line break is quoted, and quotes inside
    /// it are doubled. Habit names and notes are free text, so any of these can turn up.
    static func csvField(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func csvRow(_ fields: [String]) -> String {
        fields.map(csvField).joined(separator: ",")
    }

    // MARK: - JSON

    static let formatName = "longevity-master-backup"
    /// 2 added which achievement each unlocked one is, beside its title. Version 1 files have
    /// titles only, and restore still reads them.
    static let formatVersion = 2

    /// The backup file. Its own types rather than the tables', so the file keeps its shape
    /// when the schema moves on. Values are stored the way the database stores them —
    /// categories and frequencies as their numbers — so an import has nothing to translate.
    /// Days are written as local calendar dates, since that is what a day off or a check-in's
    /// day means; moments carry their UTC offset.
    struct Backup: Codable, Equatable {
        var format: String
        var version: Int
        var exportedAt: String
        var timeZone: String
        var appVersion: String
        var habits: [HabitRecord]
        var checkIns: [CheckInRecord]
        var restDays: [RestDayRecord]
        var reminders: [ReminderRecord]
        var customPrograms: [CustomProgramRecord]
        var programRuns: [ProgramRunRecord]
        var achievements: [AchievementRecord]
    }

    struct HabitRecord: Codable, Equatable {
        var id: Int
        var name: String
        var icon: String
        var category: Int
        var frequency: Int
        var frequencyDetail: String
        var antiAgingRating: Int
        var color: Int
        var note: String
        var isFavorite: Bool
        var isArchived: Bool
        /// Where the user put it in their own order, if they ever rearranged.
        var position: Int?
    }

    struct CheckInRecord: Codable, Equatable {
        var habitID: Int
        var day: String
        var time: String
    }

    struct RestDayRecord: Codable, Equatable {
        var day: String
        /// Absent for a day off from every habit.
        var habitID: Int?
    }

    struct ReminderRecord: Codable, Equatable {
        /// Absent for the general reminder that is not about any one habit.
        var habitID: Int?
        var title: String
        var body: String
        /// `HH:mm`, local.
        var time: String
    }

    struct CustomProgramRecord: Codable, Equatable {
        var id: Int
        var title: String
        var icon: String
        var color: Int
        var durationDays: Int
        var summary: String
        var weeklyFocus: [String]
        var habits: [ProgramHabitTemplate]
    }

    struct ProgramRunRecord: Codable, Equatable {
        var programID: String
        var startDay: String
        var isArchived: Bool
        var habitIDs: [Int]
    }

    struct AchievementRecord: Codable, Equatable {
        /// In the language the app was in when the achievements were first set up.
        var title: String
        var unlockedAt: String?
        /// Which achievement this is, whatever its title is in: its `AchievementType` and the
        /// criteria's target and category, which between them tell all of them apart. Absent
        /// in version 1 files.
        var kind: Int? = nil
        var target: Int? = nil
        var category: Int? = nil
    }

    static func backup(_ snapshot: Snapshot, now: Date, calendar: Calendar, appVersion: String) -> Backup {
        let days = dayFormatter(calendar)
        let times = timeFormatter(calendar)
        let moments = ISO8601DateFormatter()
        moments.timeZone = calendar.timeZone
        moments.formatOptions = [.withInternetDateTime]

        let positionByHabit = Dictionary(
            snapshot.positions.map { ($0.habitID, $0.position) },
            uniquingKeysWith: { first, _ in first }
        )
        let habitIDsByRun = Dictionary(grouping: snapshot.programHabits, by: \.enrollmentID)

        return Backup(
            format: formatName,
            version: formatVersion,
            exportedAt: moments.string(from: now),
            timeZone: calendar.timeZone.identifier,
            appVersion: appVersion,
            habits: snapshot.habits.sorted { $0.id < $1.id }.map { habit in
                HabitRecord(
                    id: habit.id,
                    name: habit.name,
                    icon: habit.icon,
                    category: habit.category.rawValue,
                    frequency: habit.frequency.rawValue,
                    frequencyDetail: habit.frequencyDetail,
                    antiAgingRating: habit.antiAgingRating,
                    color: habit.color,
                    note: habit.note,
                    isFavorite: habit.isFavorite,
                    isArchived: habit.isArchived,
                    position: positionByHabit[habit.id]
                )
            },
            checkIns: snapshot.checkIns.sorted { ($0.date, $0.id) < ($1.date, $1.id) }.map { checkIn in
                CheckInRecord(
                    habitID: checkIn.habitID,
                    day: days.string(from: checkIn.date),
                    time: moments.string(from: checkIn.date)
                )
            },
            restDays: snapshot.skippedDays.sorted { ($0.date, $0.id) < ($1.date, $1.id) }.map { skipped in
                RestDayRecord(day: days.string(from: skipped.date), habitID: skipped.habitID)
            },
            reminders: snapshot.reminders.sorted { $0.id < $1.id }.map { reminder in
                ReminderRecord(
                    habitID: reminder.habitID,
                    title: reminder.title,
                    body: reminder.body,
                    time: times.string(from: reminder.time)
                )
            },
            customPrograms: snapshot.customPrograms.sorted { $0.id < $1.id }.map { program in
                CustomProgramRecord(
                    id: program.id,
                    title: program.title,
                    icon: program.icon,
                    color: program.color,
                    durationDays: program.durationDays,
                    summary: program.summary,
                    weeklyFocus: program.weeklyFocus,
                    habits: program.habits
                )
            },
            programRuns: snapshot.enrollments.sorted { $0.id < $1.id }.map { enrollment in
                ProgramRunRecord(
                    programID: enrollment.programID,
                    startDay: days.string(from: enrollment.startDate),
                    isArchived: enrollment.isArchived,
                    habitIDs: (habitIDsByRun[enrollment.id] ?? []).map(\.habitID).sorted()
                )
            },
            achievements: snapshot.achievements.sorted { $0.id < $1.id }.map { achievement in
                AchievementRecord(
                    title: achievement.title,
                    unlockedAt: achievement.unlockedDate.map(moments.string(from:)),
                    kind: achievement.type.rawValue,
                    target: achievement.criteria.targetValue,
                    category: achievement.criteria.category?.rawValue
                )
            }
        )
    }

    static func backupJSON(_ snapshot: Snapshot, now: Date, calendar: Calendar, appVersion: String) throws -> Data {
        let encoder = JSONEncoder()
        // Sorted so the same data always writes the same file.
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(backup(snapshot, now: now, calendar: calendar, appVersion: appVersion))
    }

    // MARK: - Formatting

    private static func dayFormatter(_ calendar: Calendar) -> DateFormatter {
        formatter("yyyy-MM-dd", calendar)
    }

    private static func timeFormatter(_ calendar: Calendar) -> DateFormatter {
        formatter("HH:mm", calendar)
    }

    /// Fixed-format and POSIX, whatever the device's language and calendar: a file is read by
    /// other software, which wants 2026-10-17 rather than 17/10/2026 or a Buddhist-era year.
    private static func formatter(_ format: String, _ calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }
}

extension HabitCategory {
    /// The category's name without its emoji: what a spreadsheet sorts and filters on, and
    /// what reads cleanly beside an icon that is already showing.
    ///
    /// Kept in the app target rather than with `title` in `Habit.swift`, which the widget
    /// compiles too and has no use for this.
    var plainTitle: String {
        switch self {
        case .diet: return String(localized: "Diet")
        case .exercise: return String(localized: "Exercise")
        case .sleep: return String(localized: "Sleep")
        case .preventiveHealth: return String(localized: "Preventive Health")
        case .mentalHealth: return String(localized: "Mental Health")
        }
    }
}
