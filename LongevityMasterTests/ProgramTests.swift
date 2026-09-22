//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import LongevityMaster

@Suite("Program data")
struct ProgramDataTests {
    @Test("Gallery habit names are unique, since the gallery uses them as identity")
    func galleryNamesAreUnique() {
        let names = HabitsDataStore.all.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test("Every program is built from gallery habits")
    func programHabitsComeFromTheGallery() {
        let gallery = Set(HabitsDataStore.all)
        for program in ProgramsDataStore.all {
            for habit in program.habits {
                #expect(gallery.contains(habit), "\(program.id): \(habit.name)")
            }
        }
    }

    @Test("Program ids are unique and each week has a focus")
    func programsAreWellFormed() {
        let ids = ProgramsDataStore.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        for program in ProgramsDataStore.all {
            #expect(program.weeklyFocus.count == program.durationWeeks, "\(program.id)")
            #expect(!program.sources.isEmpty, "\(program.id)")
            #expect(Set(program.habits).count == program.habits.count, "\(program.id)")
            #expect(program.sources.allSatisfy { $0.url != nil }, "\(program.id)")
        }
    }

    @Test("Weekly quotas in the gallery fit in a week")
    func quotasFit() {
        for habit in HabitsDataStore.all where habit.frequency == .nDaysEachWeek {
            #expect((1...7).contains(habit.nDaysPerWeek), "\(habit.name)")
        }
    }
}

@Suite("Program progress")
struct ProgramProgressTests {
    let calendar = testCalendar()

    private func habit(_ id: Int, frequency: HabitFrequency = .fixedDaysInWeek, detail: String = "1,2,3,4,5,6,7") -> Habit {
        Habit(id: id, name: "Habit \(id)", frequency: frequency, frequencyDetail: detail)
    }

    private func checkIns(_ habitID: Int, _ days: [String]) -> [CheckIn] {
        days.enumerated().map { index, day in
            CheckIn(id: habitID * 1000 + index, date: testDate(day + " 09:00"), habitID: habitID)
        }
    }

    private func progress(
        start: String,
        today: String,
        duration: Int = 21,
        habits: [Habit],
        checkIns: [CheckIn],
        skipped: [SkippedDay] = []
    ) -> ProgramProgress {
        ProgramProgress.make(
            durationDays: duration,
            startDate: testDate(start + " 08:00"),
            today: testDate(today + " 18:00"),
            habits: habits,
            checkIns: checkIns,
            restDays: RestDays(skipped, in: calendar),
            calendar: calendar
        )
    }

    @Test("Nothing is owed on the first morning")
    func firstDayOwesNothing() {
        let result = progress(start: "2026-09-01", today: "2026-09-01", habits: [habit(1)], checkIns: [])
        #expect(result.dayNumber == 1)
        #expect(result.adherence == nil)
        #expect(!result.isFinished)
    }

    @Test("A daily habit done 7 of the last 10 days is 70% on track")
    func dailyAdherence() {
        let done = checkIns(1, ["2026-09-01", "2026-09-02", "2026-09-03", "2026-09-05", "2026-09-06", "2026-09-08", "2026-09-10"])
        let result = progress(start: "2026-09-01", today: "2026-09-11", habits: [habit(1)], checkIns: done)
        #expect(result.dayNumber == 11)
        #expect(result.daysLeft == 10)
        #expect(result.adherencePercent == 70)
        #expect(result.checkInCount == 7)
    }

    @Test("Today counts once it is done, and not before")
    func todayOnlyHelps() {
        let past = ["2026-09-01", "2026-09-02"]
        let notYet = progress(start: "2026-09-01", today: "2026-09-03", habits: [habit(1)], checkIns: checkIns(1, past))
        #expect(notYet.adherencePercent == 100)

        let done = progress(start: "2026-09-01", today: "2026-09-03", habits: [habit(1)], checkIns: checkIns(1, past + ["2026-09-03"]))
        #expect(done.adherencePercent == 100)
        #expect(done.checkInCount == 3)
    }

    @Test("Extra check-ins on one habit do not cover for another")
    func creditIsCappedPerHabit() {
        let everyDay = ["2026-09-01", "2026-09-02", "2026-09-03", "2026-09-04"]
        let quota = habit(2, frequency: .nDaysEachWeek, detail: "2")
        let result = progress(
            start: "2026-09-01",
            today: "2026-09-05",
            habits: [habit(1), quota],
            checkIns: checkIns(1, everyDay) + checkIns(2, everyDay)
        )
        // Habit 1 owes 4 and did 4; habit 2 owes 4 × 2/7 and did more than that.
        #expect(result.adherencePercent == 100)

        let lopsided = progress(
            start: "2026-09-01",
            today: "2026-09-05",
            habits: [habit(1), habit(3)],
            checkIns: checkIns(1, everyDay)
        )
        #expect(lopsided.adherencePercent == 50)
    }

    @Test("Nothing falls due on a rest day")
    func restDaysOweNothing() {
        let done = checkIns(1, ["2026-09-01", "2026-09-02", "2026-09-04"])
        let rest = [SkippedDay(id: 1, date: testDate("2026-09-03 12:00"), habitID: nil)]
        let result = progress(start: "2026-09-01", today: "2026-09-05", habits: [habit(1)], checkIns: done, skipped: rest)
        #expect(result.adherencePercent == 100)
    }

    @Test("A finished program stops counting at its last day")
    func finishedProgram() {
        let days = (1...9).map { String(format: "2026-09-%02d", $0) }
        let result = progress(start: "2026-09-01", today: "2026-09-20", duration: 7, habits: [habit(1)], checkIns: checkIns(1, days))
        #expect(result.isFinished)
        #expect(result.dayNumber == 7)
        #expect(result.daysLeft == 0)
        #expect(result.checkInCount == 7)
        #expect(result.adherencePercent == 100)
    }

    @Test("Fixed days owe only on their own weekdays")
    func fixedWeekdays() {
        // 2026-09-07 is a Monday; weekday 2 in Calendar's numbering.
        let mondays = habit(1, detail: "2")
        let result = progress(start: "2026-09-07", today: "2026-09-21", habits: [mondays], checkIns: checkIns(1, ["2026-09-07"]))
        #expect(result.adherencePercent == 50)
    }
}

@Suite("Starting and leaving programs")
struct ProgramEnrollmentTests {
    @Test("Starting reuses a habit the user already has, and brings it back from the archive")
    func startReusesExistingHabits() async throws {
        let program = ProgramsDataStore.sleepReset
        try await withTestDatabase { database in
            var archived = program.habits[0]
            archived.isArchived = true
            try await database.write { db in
                try Habit.upsert { archived }.execute(db)
            }

            let enrollment = try await database.write { db in
                try ProgramEnrollments.start(program, on: Date(), in: db)
            }

            let (habits, links) = try await database.read { db in
                (try Habit.all.fetchAll(db), try ProgramHabit.all.fetchAll(db))
            }
            #expect(habits.count == program.habits.count)
            #expect(habits.allSatisfy { !$0.isArchived })
            #expect(links.count == program.habits.count)
            #expect(links.allSatisfy { $0.enrollmentID == enrollment.id })
            #expect(enrollment.programID == program.id)
        }
    }

    @Test("Leaving a program keeps its habits")
    func leaveKeepsHabits() async throws {
        let program = ProgramsDataStore.cardioBase
        try await withTestDatabase { database in
            let enrollment = try await database.write { db in
                try ProgramEnrollments.start(program, on: Date(), in: db)
            }
            try await database.write { db in
                try ProgramEnrollments.leave(enrollment.id, in: db)
            }
            let (habits, enrollments, links) = try await database.read { db in
                (try Habit.all.fetchAll(db), try ProgramEnrollment.all.fetchAll(db), try ProgramHabit.all.fetchAll(db))
            }
            #expect(habits.count == program.habits.count)
            #expect(enrollments.isEmpty)
            #expect(links.isEmpty)
        }
    }

    @Test("Archiving takes a finished program off Today without deleting it")
    func archiveKeepsTheResult() async throws {
        try await withTestDatabase { database in
            let enrollment = try await database.write { db in
                try ProgramEnrollments.start(ProgramsDataStore.calmMind, on: Date(), in: db)
            }
            try await database.write { db in
                try ProgramEnrollments.archive(enrollment.id, in: db)
            }
            let stored = try await database.read { db in try ProgramEnrollment.all.fetchAll(db) }
            #expect(stored.count == 1)
            #expect(stored.first?.isArchived == true)
        }
    }
}
