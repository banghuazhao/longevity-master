//
// Created by Banghua Zhao on 22/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import LongevityMaster

/// Checking habits in from Apple Health, with Health replaced by fixed totals.
@Suite("Apple Health check-ins")
struct HealthSyncTests {
    private let calendar = testCalendar()
    /// A Sunday morning.
    private let now = testDate("2026-11-22 09:30")

    /// A habit linked to steps with an 8,000 goal, due every day unless `days` says otherwise.
    private func linkedHabit(
        in database: any DatabaseWriter,
        days: String = "1,2,3,4,5,6,7",
        lastCheckInDay: Date? = nil
    ) async throws -> Habit.ID {
        try await database.write { db in
            let habitID = try Habit
                .upsert { testHabitDraft(name: "Walk", frequencyDetail: days, category: .exercise) }
                .returning(\.self)
                .fetchOne(db)!.id
            try HealthLink.insert {
                HealthLink.Draft(habitID: habitID, metric: .steps, goal: 8000, lastCheckInDay: lastCheckInDay)
            }
            .execute(db)
            return habitID
        }
    }

    private func checkIns(in database: any DatabaseWriter) async throws -> [CheckIn] {
        try await database.read { db in try CheckIn.order { $0.date }.fetchAll(db) }
    }

    @Test("Reaching the goal checks the habit in, once")
    func goalMetChecksIn() async throws {
        try await withTestDatabase { database in
            let habitID = try await linkedHabit(in: database)
            let today = calendar.startOfDay(for: now)

            let created = try await HealthSync.sync(database: database, now: now, calendar: calendar) { _, day in
                day == today ? 9500 : 0
            }
            #expect(created.count == 1)
            #expect(created.first?.habitID == habitID)
            #expect(created.first?.date == now)

            let again = try await HealthSync.sync(database: database, now: now, calendar: calendar) { _, _ in 9500 }
            #expect(again.isEmpty)
            #expect(try await checkIns(in: database).count == 1)
        }
    }

    @Test("Falling short checks nothing in, and today is looked at again later")
    func goalNotMet() async throws {
        try await withTestDatabase { database in
            _ = try await linkedHabit(in: database)
            let created = try await HealthSync.sync(database: database, now: now, calendar: calendar) { _, _ in 4000 }
            #expect(created.isEmpty)

            let later = try await HealthSync.sync(
                database: database,
                now: now.addingTimeInterval(8 * 3600),
                calendar: calendar
            ) { _, day in
                day == calendar.startOfDay(for: now) ? 8000 : 0
            }
            #expect(later.count == 1)
        }
    }

    @Test("A check-in the user takes back is not made again")
    func removedCheckInStaysRemoved() async throws {
        try await withTestDatabase { database in
            _ = try await linkedHabit(in: database)
            let today = calendar.startOfDay(for: now)
            let created = try await HealthSync.sync(database: database, now: now, calendar: calendar) { _, day in
                day == today ? 9000 : 0
            }
            #expect(created.count == 1)

            try await database.write { db in try CheckIn.all.delete().execute(db) }

            let again = try await HealthSync.sync(database: database, now: now, calendar: calendar) { _, _ in 9000 }
            #expect(again.isEmpty)
            #expect(try await checkIns(in: database).isEmpty)
        }
    }

    @Test("Yesterday's goal, met late in the evening, is checked in at midday yesterday")
    func yesterdayCounts() async throws {
        try await withTestDatabase { database in
            _ = try await linkedHabit(in: database)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
            let created = try await HealthSync.sync(database: database, now: now, calendar: calendar) { _, day in
                day == yesterday ? 12000 : 0
            }
            #expect(created.count == 1)
            #expect(created.first?.date == testDate("2026-11-21 12:00"))
        }
    }

    @Test("A habit not due today is left alone")
    func notDueIsSkipped() async throws {
        try await withTestDatabase { database in
            // Mondays only; the 22nd is a Sunday and the 21st a Saturday.
            _ = try await linkedHabit(in: database, days: "2")
            let created = try await HealthSync.sync(database: database, now: now, calendar: calendar) { _, _ in 20000 }
            #expect(created.isEmpty)
        }
    }

    @Test("A habit already checked in by hand gets no second check-in")
    func alreadyDoneByHand() async throws {
        try await withTestDatabase { database in
            let habitID = try await linkedHabit(in: database)
            try await database.write { db in
                try CheckIn.insert { CheckIn.Draft(date: testDate("2026-11-22 07:00"), habitID: habitID) }.execute(db)
                try CheckIn.insert { CheckIn.Draft(date: testDate("2026-11-21 07:00"), habitID: habitID) }.execute(db)
            }
            let created = try await HealthSync.sync(database: database, now: now, calendar: calendar) { _, _ in 20000 }
            #expect(created.isEmpty)
            #expect(try await checkIns(in: database).count == 2)
        }
    }

    @Test("Overlapping samples from two devices are counted once")
    func overlapsCountedOnce() {
        let start = testDate("2026-11-21 23:00")
        let intervals = [
            DateInterval(start: start, duration: 4 * 3600),
            DateInterval(start: start.addingTimeInterval(3600), duration: 4 * 3600),
            DateInterval(start: start.addingTimeInterval(6 * 3600), duration: 3600),
        ]
        #expect(HealthSync.mergedDuration(of: intervals) == 6 * 3600)
    }
}
