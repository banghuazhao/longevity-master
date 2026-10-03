//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

/// Where an enrollment stands: which day of the program it is, and how much of what was due
/// has been done.
struct ProgramProgress: Equatable {
    /// 1 on the day the program starts, capped at the program's length once it is over.
    let dayNumber: Int
    let durationDays: Int
    let isFinished: Bool
    /// Share of the due check-ins that were done, 0...1. `nil` until anything has fallen due —
    /// on the first morning there is nothing to have missed yet.
    let adherence: Double?
    /// Every check-in on the program's habits during the program, including extras beyond
    /// what was due.
    let checkInCount: Int
    /// The two sides of `adherence`, kept so results for separate habits can be added up into
    /// one figure — averaging the percentages would weigh a once-a-month habit the same as a
    /// daily one.
    var due: Double = 0
    var credited: Double = 0

    var daysLeft: Int {
        max(durationDays - dayNumber, 0)
    }

    var fractionElapsed: Double {
        Double(dayNumber) / Double(max(durationDays, 1))
    }

    var adherencePercent: Int? {
        adherence.map { Int(($0 * 100).rounded()) }
    }

    /// - Parameters:
    ///   - habits: the enrollment's habits. Anything else in `checkIns` is ignored.
    ///   - restDays: days off; nothing falls due on them.
    ///
    /// What falls due is judged per habit, per day: a fixed-day habit owes one check-in on each
    /// of its days, and a quota habit owes its quota spread evenly — three a week is 3/7 of a
    /// check-in each day. Each habit's credit is capped at what it owed, so ten check-ins on
    /// one habit cannot make up for skipping another.
    ///
    /// Today counts only once it helps: a habit done today adds today's share to both sides,
    /// but one not done yet is not held against the user before the day is out.
    static func make(
        durationDays: Int,
        startDate: Date,
        today: Date,
        habits: [Habit],
        checkIns: [CheckIn],
        restDays: RestDays,
        calendar: Calendar
    ) -> ProgramProgress {
        let start = calendar.startOfDay(for: startDate)
        let todayStart = calendar.startOfDay(for: today)
        let elapsedDays = calendar.dateComponents([.day], from: start, to: todayStart).day ?? 0
        let isFinished = elapsedDays >= durationDays
        let dayNumber = min(max(elapsedDays + 1, 1), durationDays)

        guard
            let lastDay = calendar.date(byAdding: .day, value: durationDays - 1, to: start),
            let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart)
        else {
            return ProgramProgress(dayNumber: dayNumber, durationDays: durationDays, isFinished: isFinished, adherence: nil, checkInCount: 0)
        }
        // The last day whose obligations are settled: yesterday, or the program's final day.
        let settledThrough = min(yesterday, lastDay)
        let todayIsInProgram = todayStart >= start && todayStart <= lastDay

        let habitIDs = Set(habits.map(\.id))
        var checkInDays: [Habit.ID: Set<Date>] = [:]
        for checkIn in checkIns where habitIDs.contains(checkIn.habitID) {
            let day = calendar.startOfDay(for: checkIn.date)
            guard day >= start, day <= lastDay else { continue }
            checkInDays[checkIn.habitID, default: []].insert(day)
        }

        var owed = 0.0
        var credited = 0.0
        var checkInCount = 0

        for habit in habits {
            let done = checkInDays[habit.id] ?? []
            let rested = restDays.forHabit(habit.id)
            checkInCount += done.count

            var habitOwed = 0.0
            var day = start
            while day <= settledThrough {
                if !rested.contains(day) {
                    habitOwed += share(of: habit, on: day, calendar: calendar)
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            var habitDone = Double(done.filter { $0 <= settledThrough }.count)

            if todayIsInProgram, done.contains(todayStart) {
                habitOwed += share(of: habit, on: todayStart, calendar: calendar)
                habitDone += 1
            }

            owed += habitOwed
            credited += min(habitDone, habitOwed)
        }

        return ProgramProgress(
            dayNumber: dayNumber,
            durationDays: durationDays,
            isFinished: isFinished,
            adherence: owed > 0 ? credited / owed : nil,
            checkInCount: checkInCount,
            due: owed,
            credited: credited
        )
    }

    /// How much of a check-in `habit` owes on `day`.
    private static func share(of habit: Habit, on day: Date, calendar: Calendar) -> Double {
        switch habit.frequency {
        case .fixedDaysInWeek:
            return habit.daysOfWeek.contains(calendar.component(.weekday, from: day)) ? 1 : 0
        case .fixedDaysInMonth:
            return habit.daysOfMonth.contains(calendar.component(.day, from: day)) ? 1 : 0
        case .nDaysEachWeek:
            return Double(min(habit.nDaysPerWeek, 7)) / 7
        case .nDaysEachMonth:
            return Double(min(habit.nDaysPerMonth, 28)) / 30
        }
    }
}

/// Starting and leaving programs. Kept apart from the screens so onboarding, the program page
/// and the tests all go through the same rules.
enum ProgramEnrollments {
    /// Enrolls the user in `program` from `date`, and returns the new enrollment.
    ///
    /// A program habit the user already has — matched by name, the way it was copied from the
    /// gallery — is reused rather than added twice, and brought back if it had been archived.
    /// Everything else is added as a new habit.
    @discardableResult
    static func start(
        _ program: Program,
        on date: Date,
        in db: Database
    ) throws -> ProgramEnrollment {
        let habitIDs = try resolveHabits(program.habits, in: db)

        let saved = try ProgramEnrollment
            .upsert { ProgramEnrollment.Draft(programID: program.id, startDate: date) }
            .returning(\.self)
            .fetchOne(db)
        guard let enrollment = saved else {
            throw ProgramEnrollmentError.notSaved
        }

        for habitID in habitIDs {
            try ProgramHabit
                .upsert { ProgramHabit.Draft(enrollmentID: enrollment.id, habitID: habitID) }
                .execute(db)
        }
        return enrollment
    }

    /// The user's habit for each draft: an existing one of the same name, restored from the
    /// archive if need be, or a new one.
    static func resolveHabits(_ drafts: [Habit.Draft], in db: Database) throws -> [Habit.ID] {
        var habitIDs: [Habit.ID] = []
        for draft in drafts {
            let matches = try Habit.where { $0.name.eq(draft.name) }.fetchAll(db)
            if let existing = matches.first(where: { !$0.isArchived }) ?? matches.first {
                if existing.isArchived {
                    var restored = existing
                    restored.isArchived = false
                    try Habit.update(restored).execute(db)
                }
                habitIDs.append(existing.id)
            } else {
                let created = try Habit.upsert { draft }.returning(\.self).fetchOne(db)
                if let created {
                    habitIDs.append(created.id)
                }
            }
        }
        return habitIDs
    }

    /// Stops following a program. Its habits stay: by now they are the user's own.
    static func leave(_ enrollmentID: ProgramEnrollment.ID, in db: Database) throws {
        try ProgramEnrollment.where { $0.id.eq(enrollmentID) }.delete().execute(db)
    }

    /// Takes a finished program off the Today tab. It stays on the program's page as a result.
    static func archive(_ enrollmentID: ProgramEnrollment.ID, in db: Database) throws {
        try ProgramEnrollment
            .where { $0.id.eq(enrollmentID) }
            .update { $0.isArchived = true }
            .execute(db)
    }
}

enum ProgramEnrollmentError: Error {
    case notSaved
}

/// Saving and deleting the programs users make themselves.
enum CustomPrograms {
    /// Saves `draft` — new, or an edit of an existing program — and returns it.
    ///
    /// Editing a program that is under way carries the change to its habits into the run:
    /// a habit added to the plan starts being tracked, and one taken out stops. Habits are
    /// told apart by name, and only the ones whose names actually left the plan are dropped,
    /// so a habit the user renamed since starting stays counted.
    @discardableResult
    static func save(_ draft: CustomProgram.Draft, in db: Database) throws -> CustomProgram {
        let previousNames: Set<String>
        if let id = draft.id, let previous = try CustomProgram.find(id).fetchOne(db) {
            previousNames = Set(previous.habits.map(\.name))
        } else {
            previousNames = []
        }

        guard let saved = try CustomProgram.upsert { draft }.returning(\.self).fetchOne(db) else {
            throw ProgramEnrollmentError.notSaved
        }
        guard draft.id != nil else { return saved }

        let currentNames = Set(saved.habits.map(\.name))
        let removed = previousNames.subtracting(currentNames)
        let added = saved.habits.filter { !previousNames.contains($0.name) }.map(\.draft)
        guard !removed.isEmpty || !added.isEmpty else { return saved }

        // Runs still under way, by the same day count `ProgramProgress` uses to call one
        // finished.
        let program = Program(custom: saved)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let runs = try ProgramEnrollment
            .where { $0.programID.eq(program.id) && !$0.isArchived }
            .fetchAll(db)
            .filter { enrollment in
                let start = calendar.startOfDay(for: enrollment.startDate)
                let elapsed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
                return elapsed < program.durationDays
            }
        guard !runs.isEmpty else { return saved }

        let addedIDs = try ProgramEnrollments.resolveHabits(added, in: db)
        for run in runs {
            let linked = try ProgramHabit.where { $0.enrollmentID.eq(run.id) }.fetchAll(db)
            let linkedHabits = try Habit.where { $0.id.in(linked.map(\.habitID)) }.fetchAll(db)
            let dropped = Set(linkedHabits.filter { removed.contains($0.name) }.map(\.id))
            if !dropped.isEmpty {
                try ProgramHabit
                    .where { $0.enrollmentID.eq(run.id) && $0.habitID.in(Array(dropped)) }
                    .delete()
                    .execute(db)
            }
            let alreadyLinked = Set(linked.map(\.habitID))
            for habitID in addedIDs where !alreadyLinked.contains(habitID) {
                try ProgramHabit
                    .upsert { ProgramHabit.Draft(enrollmentID: run.id, habitID: habitID) }
                    .execute(db)
            }
        }
        return saved
    }

    /// Deletes the program and every run of it. The habits it added stay.
    static func delete(_ id: CustomProgram.ID, in db: Database) throws {
        try ProgramEnrollment
            .where { $0.programID.eq(Program.id(forCustom: id)) }
            .delete()
            .execute(db)
        try CustomProgram.where { $0.id.eq(id) }.delete().execute(db)
    }
}
