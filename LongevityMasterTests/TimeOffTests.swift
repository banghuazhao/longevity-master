//
// Created by Banghua Zhao on 10/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import LongevityMaster

@Suite("Planning time off")
struct TimeOffTests {
    let calendar = testCalendar()

    @Test("A range covers every day from start to end, inclusive")
    func daysInRange() {
        let days = TimeOff.days(from: testDate("2026-10-30 18:00"), through: testDate("2026-11-02 08:00"), calendar: calendar)
        #expect(Set(days) == testDays(["2026-10-30", "2026-10-31", "2026-11-01", "2026-11-02"]))
    }

    @Test("An end before the start is no range at all")
    func backwardsRange() {
        #expect(TimeOff.days(from: testDate("2026-10-12"), through: testDate("2026-10-11"), calendar: calendar).isEmpty)
    }

    @Test("A range is capped, so a slip of the picker cannot write years of rows")
    func cappedRange() {
        let days = TimeOff.days(from: testDate("2026-01-01"), through: testDate("2030-01-01"), calendar: calendar)
        #expect(days.count == TimeOff.maxDays)
    }

    @Test("Days already off, and days the habit was done, are left as they are")
    func skipsExistingDays() {
        let days = TimeOff.days(from: testDate("2026-10-10"), through: testDate("2026-10-14"), calendar: calendar)
        let skipped = [
            SkippedDay(id: 1, date: testDate("2026-10-11 12:00"), habitID: 7),
            // Another habit's, and one from everything: neither covers habit 7's own.
            SkippedDay(id: 2, date: testDate("2026-10-12 12:00"), habitID: 8),
            SkippedDay(id: 3, date: testDate("2026-10-13 12:00"), habitID: nil),
        ]
        let checkIns = [
            CheckIn(id: 1, date: testDate("2026-10-14 07:00"), habitID: 7),
            CheckIn(id: 2, date: testDate("2026-10-10 07:00"), habitID: 8),
        ]
        let toAdd = TimeOff.daysToAdd(days, habitID: 7, skippedDays: skipped, checkIns: checkIns, calendar: calendar)
        #expect(Set(toAdd) == testDays(["2026-10-10", "2026-10-12", "2026-10-13"]))
    }

    @Test("Time off from everything ignores check-ins, as a rest day on Today does")
    func everyHabitIgnoresCheckIns() {
        let days = TimeOff.days(from: testDate("2026-10-10"), through: testDate("2026-10-11"), calendar: calendar)
        let checkIns = [CheckIn(id: 1, date: testDate("2026-10-10 07:00"), habitID: 7)]
        let toAdd = TimeOff.daysToAdd(days, habitID: nil, skippedDays: [], checkIns: checkIns, calendar: calendar)
        #expect(toAdd.count == 2)
    }

    @Test("Upcoming time off joins neighbouring days and leaves out what has passed")
    func upcomingRanges() {
        let skipped = [
            SkippedDay(id: 1, date: testDate("2026-10-08 12:00"), habitID: nil),
            SkippedDay(id: 2, date: testDate("2026-10-12 12:00"), habitID: nil),
            SkippedDay(id: 3, date: testDate("2026-10-13 12:00"), habitID: nil),
            SkippedDay(id: 4, date: testDate("2026-10-14 12:00"), habitID: nil),
            SkippedDay(id: 5, date: testDate("2026-10-20 12:00"), habitID: nil),
            SkippedDay(id: 6, date: testDate("2026-10-21 12:00"), habitID: 3),
        ]
        let ranges = TimeOff.upcoming(skipped, habitID: nil, asOf: testDate("2026-10-10 09:00"), calendar: calendar)
        #expect(ranges == [
            testDate("2026-10-12") ... testDate("2026-10-14"),
            testDate("2026-10-20") ... testDate("2026-10-20"),
        ])
    }

    @Test("Adding and removing time off touches only its own scope")
    func addAndRemove() async throws {
        let calendar = Calendar.current
        try await withTestDatabase { database in
            let habitID = try await database.write { db in
                try Habit.upsert { testHabitDraft(name: "Walk") }.returning(\.id).fetchOne(db)!
            }
            let start = localDate(daysAgo: -2)
            let end = localDate(daysAgo: -6)

            try await database.write { db in
                try SkippedDay.insert { SkippedDay.Draft(date: localDate(daysAgo: -3), habitID: nil) }.execute(db)
                try TimeOff.add(from: start, through: end, habitID: habitID, calendar: calendar, in: db)
                // Twice over: nothing is filed for a day already off.
                try TimeOff.add(from: start, through: end, habitID: habitID, calendar: calendar, in: db)
            }
            var rows = try await database.read { db in try SkippedDay.all.fetchAll(db) }
            #expect(rows.filter { $0.habitID == habitID }.count == 5)

            try await database.write { db in
                try TimeOff.remove(start ... end, habitID: habitID, calendar: calendar, in: db)
            }
            rows = try await database.read { db in try SkippedDay.all.fetchAll(db) }
            #expect(rows.count == 1)
            #expect(rows.first?.habitID == nil)
        }
    }
}
