//
// Created by Banghua Zhao on 22/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import LongevityMaster

/// The achievements added in 1.10: comebacks, balanced days, five-star streaks, anniversaries
/// and finished programs.
@Suite("Unlocking the 1.10 achievements")
struct NewAchievementTests {
    private struct HabitPlan {
        var category: HabitCategory = .diet
        var antiAgingRating = 3
        var days: [Date]
    }

    /// Writes each habit's check-ins, judges the last check-in of the last habit, and hands
    /// back every achievement afterwards.
    private func unlocked(after plans: [HabitPlan]) async throws -> [Achievement] {
        var result: [Achievement] = []
        try await withTestDatabase { database in
            let service = AchievementService()
            var last: CheckIn?
            for (index, plan) in plans.enumerated() {
                let habitID = try await database.write { db -> Int in
                    try Habit
                        .upsert {
                            testHabitDraft(
                                name: "Habit \(index)",
                                antiAgingRating: plan.antiAgingRating,
                                category: plan.category
                            )
                        }
                        .returning(\.self)
                        .fetchOne(db)!.id
                }
                for day in plan.days {
                    last = try await database.write { db in
                        try CheckIn
                            .upsert { CheckIn.Draft(date: day, habitID: habitID) }
                            .returning(\.self)
                            .fetchOne(db)
                    }
                }
            }
            await service.checkAchievementsAndShow(for: try #require(last))
            result = try await database.read { db in try Achievement.all.fetchAll(db) }
        }
        return result
    }

    private func isUnlocked(_ title: String, in achievements: [Achievement]) throws -> Bool {
        try #require(Achievement.named(title, in: achievements)).isUnlocked
    }

    @Test("Coming back after a week with no check-ins earns the comeback")
    func comebackAfterAWeek() async throws {
        let achievements = try await unlocked(after: [
            HabitPlan(days: [localDate(daysAgo: 8), localDate(daysAgo: 0)]),
        ])
        #expect(try isUnlocked("Comeback Kid", in: achievements))
    }

    @Test("A few days off is not a comeback")
    func noComebackAfterAShortBreak() async throws {
        let achievements = try await unlocked(after: [
            HabitPlan(days: [localDate(daysAgo: 4), localDate(daysAgo: 0)]),
        ])
        #expect(try !isUnlocked("Comeback Kid", in: achievements))
    }

    @Test("Three categories in one day earn the balanced day, not the five-category one")
    func balancedDay() async throws {
        let achievements = try await unlocked(after: [
            HabitPlan(category: .diet, days: [localDate(daysAgo: 0)]),
            HabitPlan(category: .exercise, days: [localDate(daysAgo: 0)]),
            HabitPlan(category: .sleep, days: [localDate(daysAgo: 0)]),
        ])
        #expect(try isUnlocked("Balanced Day", in: achievements))
        #expect(try !isUnlocked("Whole-Body Day", in: achievements))
    }

    @Test("Categories spread over different days do not make a balanced day")
    func categoriesOnDifferentDays() async throws {
        let achievements = try await unlocked(after: [
            HabitPlan(category: .diet, days: [localDate(daysAgo: 2)]),
            HabitPlan(category: .exercise, days: [localDate(daysAgo: 1)]),
            HabitPlan(category: .sleep, days: [localDate(daysAgo: 0)]),
        ])
        #expect(try !isUnlocked("Balanced Day", in: achievements))
    }

    @Test("Thirty days running on a five-star habit earns five-star focus")
    func fiveStarStreak() async throws {
        let days = (0 ..< 30).reversed().map { localDate(daysAgo: $0) }
        let achievements = try await unlocked(after: [HabitPlan(antiAgingRating: 5, days: days)])
        #expect(try isUnlocked("Five-Star Focus", in: achievements))
    }

    @Test("The same streak on a three-star habit does not")
    func threeStarStreak() async throws {
        let days = (0 ..< 30).reversed().map { localDate(daysAgo: $0) }
        let achievements = try await unlocked(after: [HabitPlan(antiAgingRating: 3, days: days)])
        #expect(try !isUnlocked("Five-Star Focus", in: achievements))
    }

    @Test("Checking in a year after the first check-in earns the anniversary")
    func anniversary() async throws {
        let achievements = try await unlocked(after: [
            HabitPlan(days: [localDate(daysAgo: 366), localDate(daysAgo: 0)]),
        ])
        #expect(try isUnlocked("One Year Strong", in: achievements))
    }

    @Test("A fresh database has every definition exactly once")
    func definitionsInsertedOnce() async throws {
        try await withTestDatabase { database in
            let count = try await database.read { db in try Achievement.all.fetchCount(db) }
            #expect(count == AchievementDefinitions.all.count)
            try await database.write { db in try AchievementDefinitions.insertMissing(in: db) }
            let again = try await database.read { db in try Achievement.all.fetchCount(db) }
            #expect(again == count)
        }
    }

    @Test("An older database gains only the definitions it was missing")
    func missingDefinitionsAdded() async throws {
        try await withTestDatabase { database in
            try await database.write { db in
                try Achievement.where { $0.type.eq(AchievementType.comeback) }.delete().execute(db)
            }
            try await database.write { db in try AchievementDefinitions.insertMissing(in: db) }
            let count = try await database.read { db in try Achievement.all.fetchCount(db) }
            #expect(count == AchievementDefinitions.all.count)
        }
    }

    @Test("A program counts as finished once its last day has passed")
    func finishedPrograms() {
        let calendar = testCalendar()
        let program = ProgramsDataStore.strengthFoundations
        let now = testDate("2026-11-22 09:00")
        let started = { (daysAgo: Int) in
            ProgramEnrollment(
                id: daysAgo,
                programID: program.id,
                startDate: calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            )
        }
        let enrollments = [
            started(program.durationDays),
            started(program.durationDays - 1),
            ProgramEnrollment(id: 99, programID: "no-such-program", startDate: testDate("2025-01-01")),
        ]
        let finished = ProgramEnrollments.finishedCount(
            enrollments,
            customPrograms: [],
            now: now,
            calendar: calendar
        )
        #expect(finished == 1)
    }

    @Test("A program that finished while the app was away is awarded at the next launch")
    func graduateAtLaunch() async throws {
        try await withTestDatabase { database in
            let program = ProgramsDataStore.strengthFoundations
            try await database.write { db in
                let habitID = try Habit
                    .upsert { testHabitDraft(name: "Squats") }
                    .returning(\.self)
                    .fetchOne(db)!.id
                try CheckIn.insert { CheckIn.Draft(date: localDate(daysAgo: 1), habitID: habitID) }.execute(db)
                try ProgramEnrollment.insert {
                    ProgramEnrollment.Draft(
                        programID: program.id,
                        startDate: localDate(daysAgo: program.durationDays + 1)
                    )
                }
                .execute(db)
            }

            await AchievementService().checkAchievementsForLatestCheckIn()

            let achievements = try await database.read { db in try Achievement.all.fetchAll(db) }
            #expect(try isUnlocked("Program Graduate", in: achievements))
            #expect(try !isUnlocked("Program Collector", in: achievements))
        }
    }

    @Test("A rating reached through the achievements a check-in unlocks is awarded with them")
    func ratingReachedThroughNewAchievements() async throws {
        try await withTestDatabase { database in
            let last = try await database.write { db -> CheckIn in
                var habitIDs: [Int] = []
                for index in 0 ..< 29 {
                    habitIDs.append(
                        try Habit
                            .upsert { testHabitDraft(name: "Habit \(index)", antiAgingRating: 5) }
                            .returning(\.self)
                            .fetchOne(db)!.id
                    )
                }
                var last: CheckIn?
                for daysAgo in [2, 1, 0] {
                    last = try CheckIn
                        .upsert { CheckIn.Draft(date: localDate(daysAgo: daysAgo), habitID: habitIDs[0]) }
                        .returning(\.self)
                        .fetchOne(db)
                }
                return last!
            }

            // Short of a B on its own: only the achievements this check-in unlocks carry the
            // score past it.
            let (habits, checkIns) = try await database.read { db in
                (try Habit.all.fetchAll(db), try CheckIn.all.fetchAll(db))
            }
            let before = RatingService.score(
                habits: habits,
                unlockedAchievementCount: 0,
                checkIns: checkIns,
                skippedDays: [],
                calendar: .current
            ).totalScore
            #expect(before < 600)

            await AchievementService().checkAchievementsAndShow(for: last)

            let achievements = try await database.read { db in try Achievement.all.fetchAll(db) }
            #expect(try isUnlocked("First Milestone", in: achievements))
            #expect(try isUnlocked("Rising Star", in: achievements))
            #expect(try !isUnlocked("High Achiever", in: achievements))
        }
    }
}
