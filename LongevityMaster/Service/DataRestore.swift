//
// Created by Banghua Zhao on 19/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

/// Puts back everything a `DataExport` backup holds, in place of what the app has now.
///
/// Done in two steps so that a bad file can never cost the user anything: `plan(from:)` reads
/// and checks the whole file and turns it into rows without touching the database, and only
/// then does `replaceAll(with:in:)` swap them in, inside one transaction — if any part of it
/// fails, the database is left exactly as it was.
enum DataRestore {
    enum Failure: Error, Equatable {
        /// Not JSON, or not a Longevity Master backup.
        case notABackup
        /// Written by a later version of the app, in a shape this one does not know.
        case newerVersion
        /// A backup, but with values that do not hold together: a check-in for a habit the
        /// file does not have, a date that is not a date. Restoring part of it would leave
        /// the user with data that is wrong in ways they cannot see, so none of it is.
        case damaged
    }

    /// Everything the backup holds, as rows ready to insert, and what to tell the user
    /// about it before they agree.
    struct Plan {
        var habits: [Habit] = []
        var positions: [HabitPosition.Draft] = []
        var checkIns: [CheckIn.Draft] = []
        var skippedDays: [SkippedDay.Draft] = []
        var reminders: [Reminder.Draft] = []
        var customPrograms: [CustomProgram] = []
        var programRuns: [ProgramRun] = []
        /// The achievements the backup has unlocked, and when.
        var unlockedAchievements: [UnlockedAchievement] = []
        /// When the backup was made, if the file says.
        var exportedAt: Date?

        struct UnlockedAchievement: Equatable {
            var title: String
            /// `nil` from a version 1 backup, which has only the title to go on.
            var identity: AchievementIdentity?
            var date: Date
        }

        struct ProgramRun {
            var enrollment: ProgramEnrollment.Draft
            var habitIDs: [Habit.ID]
        }
    }

    /// Reads a backup file and checks every part of it.
    static func plan(from data: Data, calendar: Calendar, now: Date) throws -> Plan {
        // The format is checked before the rest is decoded, so a newer backup is reported as
        // newer rather than as damaged when its shape has moved on.
        struct Header: Decodable {
            var format: String
            var version: Int
        }
        guard let header = try? JSONDecoder().decode(Header.self, from: data),
              header.format == DataExport.formatName,
              header.version >= 1
        else { throw Failure.notABackup }
        guard header.version <= DataExport.formatVersion else { throw Failure.newerVersion }

        guard let backup = try? JSONDecoder().decode(DataExport.Backup.self, from: data) else {
            throw Failure.damaged
        }
        return try plan(from: backup, calendar: calendar, now: now)
    }

    static func plan(from backup: DataExport.Backup, calendar: Calendar, now: Date) throws -> Plan {
        let days = formatter("yyyy-MM-dd", calendar)
        let times = formatter("HH:mm", calendar)
        let moments = ISO8601DateFormatter()
        moments.formatOptions = [.withInternetDateTime]

        func day(_ string: String) throws -> Date {
            guard let date = days.date(from: string) else { throw Failure.damaged }
            return calendar.startOfDay(for: date)
        }
        func moment(_ string: String) throws -> Date {
            guard let date = moments.date(from: string) else { throw Failure.damaged }
            return date
        }

        var plan = Plan()
        plan.exportedAt = moments.date(from: backup.exportedAt)

        // Habits keep their ids: check-ins, reminders and program runs in the file refer to
        // them by it.
        var habitIDs = Set<Habit.ID>()
        for record in backup.habits {
            guard habitIDs.insert(record.id).inserted,
                  let category = HabitCategory(rawValue: record.category),
                  let frequency = HabitFrequency(rawValue: record.frequency)
            else { throw Failure.damaged }
            plan.habits.append(Habit(
                id: record.id,
                name: record.name,
                category: category,
                frequency: frequency,
                frequencyDetail: record.frequencyDetail,
                antiAgingRating: record.antiAgingRating,
                icon: record.icon,
                color: record.color,
                note: record.note,
                isFavorite: record.isFavorite,
                isArchived: record.isArchived
            ))
            if let position = record.position {
                plan.positions.append(HabitPosition.Draft(habitID: record.id, position: position))
            }
        }

        func habitID(_ id: Int) throws -> Habit.ID {
            guard habitIDs.contains(id) else { throw Failure.damaged }
            return id
        }

        // The moment is the record; its day is only there for people reading the file.
        plan.checkIns = try backup.checkIns.map { record in
            CheckIn.Draft(date: try moment(record.time), habitID: try habitID(record.habitID))
        }

        plan.skippedDays = try backup.restDays.map { record in
            SkippedDay.Draft(
                date: TimeOff.storedDate(for: try day(record.day), calendar: calendar),
                habitID: try record.habitID.map(habitID)
            )
        }

        // Only the time of day matters to a reminder. Each gets a new notification id, so
        // nothing still registered for the data being replaced can be mistaken for it.
        plan.reminders = try backup.reminders.map { record in
            guard let clock = times.date(from: record.time) else { throw Failure.damaged }
            let parts = calendar.dateComponents([.hour, .minute], from: clock)
            guard let hour = parts.hour, let minute = parts.minute,
                  let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)
            else { throw Failure.damaged }
            return Reminder.Draft(
                title: record.title,
                body: record.body,
                time: time,
                habitID: try record.habitID.map(habitID)
            )
        }

        // Custom programs keep their ids too: a program run names its program as
        // "custom-<id>".
        var programIDs = Set<CustomProgram.ID>()
        plan.customPrograms = try backup.customPrograms.map { record in
            guard programIDs.insert(record.id).inserted else { throw Failure.damaged }
            return CustomProgram(
                id: record.id,
                title: record.title,
                icon: record.icon,
                color: record.color,
                durationDays: record.durationDays,
                summary: record.summary,
                weeklyFocus: record.weeklyFocus,
                habits: record.habits
            )
        }

        // The file keeps a run's first day, not the moment it was started. The start of that
        // day counts the whole of it, which is what the program's progress is measured from.
        plan.programRuns = try backup.programRuns.map { record in
            Plan.ProgramRun(
                enrollment: ProgramEnrollment.Draft(
                    programID: record.programID,
                    startDate: try day(record.startDay),
                    isArchived: record.isArchived
                ),
                habitIDs: try record.habitIDs.map(habitID)
            )
        }

        plan.unlockedAchievements = try backup.achievements.map { record in
            let identity = record.kind.flatMap { kind in
                record.target.map { AchievementIdentity(kind: kind, target: $0, category: record.category) }
            }
            return Plan.UnlockedAchievement(
                title: record.title,
                identity: identity,
                date: try record.unlockedAt.map(moment) ?? now
            )
        }

        return plan
    }

    /// Replaces everything the user has recorded with `plan`. Run it inside one write so a
    /// failure part-way through rolls the whole thing back.
    ///
    /// Achievements are matched by what they are — their kind, target and category — so a
    /// backup made with the app in another language still finds them. A version 1 backup has
    /// only their titles, which are in the language the app was in when they were first set
    /// up; one this device has under another title stays locked here, and is earned again by
    /// the next check-in that meets it.
    static func replaceAll(with plan: Plan, in db: Database) throws {
        try ProgramHabit.all.delete().execute(db)
        try ProgramEnrollment.all.delete().execute(db)
        try CustomProgram.all.delete().execute(db)
        try HabitPosition.all.delete().execute(db)
        try SkippedDay.all.delete().execute(db)
        try CheckIn.all.delete().execute(db)
        try Reminder.all.delete().execute(db)
        try Habit.all.delete().execute(db)

        for habit in plan.habits {
            try Habit.insert { habit }.execute(db)
        }
        for position in plan.positions {
            try HabitPosition.insert { position }.execute(db)
        }
        for checkIn in plan.checkIns {
            try CheckIn.insert { checkIn }.execute(db)
        }
        for skippedDay in plan.skippedDays {
            try SkippedDay.insert { skippedDay }.execute(db)
        }
        for reminder in plan.reminders {
            try Reminder.insert { reminder }.execute(db)
        }
        for program in plan.customPrograms {
            try CustomProgram.insert { program }.execute(db)
        }
        for run in plan.programRuns {
            let saved = try ProgramEnrollment
                .insert { run.enrollment }
                .returning(\.self)
                .fetchOne(db)
            guard let enrollment = saved else { throw Failure.damaged }
            for habitID in run.habitIDs {
                try ProgramHabit.insert { ProgramHabit.Draft(enrollmentID: enrollment.id, habitID: habitID) }.execute(db)
            }
        }

        let byIdentity = Dictionary(
            plan.unlockedAchievements.compactMap { unlock in unlock.identity.map { ($0, unlock.date) } },
            uniquingKeysWith: { first, _ in first }
        )
        let byTitle = Dictionary(
            plan.unlockedAchievements.filter { $0.identity == nil }.map { ($0.title, $0.date) },
            uniquingKeysWith: { first, _ in first }
        )
        for var achievement in try Achievement.all.fetchAll(db) {
            let unlockedDate = byIdentity[AchievementIdentity(achievement)] ?? byTitle[achievement.title]
            guard achievement.isUnlocked || unlockedDate != nil else { continue }
            achievement.isUnlocked = unlockedDate != nil
            achievement.unlockedDate = unlockedDate
            // Which habit earned it is not in the backup.
            achievement.habitID = nil
            try Achievement.update(achievement).execute(db)
        }
    }

    /// The same fixed format `DataExport` writes with.
    private static func formatter(_ format: String, _ calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }
}

/// What makes an achievement the one it is, independent of the language its title was stored
/// in. No two of `AchievementDefinitions.all` share one.
struct AchievementIdentity: Hashable {
    var kind: Int
    var target: Int
    var category: Int?
}

extension AchievementIdentity {
    init(_ achievement: Achievement) {
        self.init(
            kind: achievement.type.rawValue,
            target: achievement.criteria.targetValue,
            category: achievement.criteria.category?.rawValue
        )
    }
}
