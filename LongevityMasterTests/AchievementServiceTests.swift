//
// Created by Banghua Zhao on 25/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import LongevityMaster

/// Achievements are judged against a single snapshot of the database taken when a check-in is
/// written. These cover the criteria a user meets early on, which are the ones that actually
/// fire in practice.
@Suite("Unlocking achievements")
struct AchievementServiceTests {
    /// Writes `days` as check-ins against one habit, judges the last of them, and hands back
    /// every achievement afterwards.
    private func unlocked(
        after days: [Date],
        category: HabitCategory = .diet,
        extraHabits: [(HabitCategory, [Date])] = []
    ) async throws -> [Achievement] {
        var result: [Achievement] = []
        try await withTestDatabase { database in
            let service = AchievementService()

            let habitID = try await database.write { db -> Int in
                let habit = try Habit
                    .upsert { testHabitDraft(name: "Habit", category: category) }
                    .returning(\.self)
                    .fetchOne(db)
                return habit!.id
            }

            for (otherCategory, otherDays) in extraHabits {
                let otherID = try await database.write { db -> Int in
                    let habit = try Habit
                        .upsert { testHabitDraft(name: "Other \(otherCategory)", category: otherCategory) }
                        .returning(\.self)
                        .fetchOne(db)
                    return habit!.id
                }
                try await database.write { db in
                    for day in otherDays {
                        try CheckIn.upsert { CheckIn.Draft(date: day, habitID: otherID) }.execute(db)
                    }
                }
            }

            var last: CheckIn?
            for day in days {
                last = try await database.write { db in
                    try CheckIn
                        .upsert { CheckIn.Draft(date: day, habitID: habitID) }
                        .returning(\.self)
                        .fetchOne(db)
                }
            }

            let judged = try #require(last)
            await service.checkAchievementsAndShow(for: judged)
            result = try await database.read { db in try Achievement.all.fetchAll(db) }
        }
        return result
    }

    private func isUnlocked(_ title: String, in achievements: [Achievement]) throws -> Bool {
        let achievement = try #require(Achievement.named(title, in: achievements))
        return achievement.isUnlocked
    }

    @Test("A first check-in earns the first milestone")
    func firstCheckInEarnsAMilestone() async throws {
        let achievements = try await unlocked(after: [localDate(daysAgo: 0)])
        #expect(try isUnlocked("First Milestone", in: achievements))
    }

    @Test("Three days running earns the three-day streak")
    func threeDayStreak() async throws {
        let achievements = try await unlocked(after: [
            localDate(daysAgo: 2),
            localDate(daysAgo: 1),
            localDate(daysAgo: 0),
        ])
        #expect(try isUnlocked("First Steps", in: achievements))
    }

    @Test("Two days running does not")
    func twoDaysIsNotAStreak() async throws {
        let achievements = try await unlocked(after: [
            localDate(daysAgo: 1),
            localDate(daysAgo: 0),
        ])
        #expect(try isUnlocked("First Steps", in: achievements) == false)
    }

    @Test("A broken run does not count as a streak")
    func aGapBreaksTheStreak() async throws {
        let achievements = try await unlocked(after: [
            localDate(daysAgo: 4),
            localDate(daysAgo: 3),
            // Nothing on day 2.
            localDate(daysAgo: 1),
            localDate(daysAgo: 0),
        ])
        #expect(try isUnlocked("First Steps", in: achievements) == false)
    }

    @Test("A seven-day streak earns both the three- and seven-day awards at once")
    func longerStreaksEarnTheShorterOnesToo() async throws {
        let achievements = try await unlocked(after: (0 ... 6).reversed().map { localDate(daysAgo: $0) })
        #expect(try isUnlocked("First Steps", in: achievements))
        #expect(try isUnlocked("Week Warrior", in: achievements))
        #expect(try isUnlocked("Month Master", in: achievements) == false)
    }

    @Test("Checking in before eight in the morning earns the early bird")
    func earlyBird() async throws {
        let achievements = try await unlocked(after: [localDate(daysAgo: 0, hour: 6)])
        #expect(try isUnlocked("Early Bird", in: achievements))
        #expect(try isUnlocked("Night Owl", in: achievements) == false)
    }

    @Test("Checking in after ten at night earns the night owl")
    func nightOwl() async throws {
        let achievements = try await unlocked(after: [localDate(daysAgo: 0, hour: 23)])
        #expect(try isUnlocked("Night Owl", in: achievements))
        #expect(try isUnlocked("Early Bird", in: achievements) == false)
    }

    @Test("Eight in the morning is neither early nor late")
    func eightIsNeither() async throws {
        let achievements = try await unlocked(after: [localDate(daysAgo: 0, hour: 8)])
        #expect(try isUnlocked("Early Bird", in: achievements) == false)
        #expect(try isUnlocked("Night Owl", in: achievements) == false)
    }

    @Test("Ten check-ins earn the ten-check-in award, nine do not")
    func totalCheckIns() async throws {
        let nine = try await unlocked(after: (1 ... 9).map { localDate(daysAgo: $0 * 2) })
        #expect(try isUnlocked("Getting Started", in: nine) == false)

        let ten = try await unlocked(after: (1 ... 10).map { localDate(daysAgo: $0 * 2) })
        #expect(try isUnlocked("Getting Started", in: ten))
    }

    @Test("Habits from three categories earn the variety award")
    func variety() async throws {
        let achievements = try await unlocked(
            after: [localDate(daysAgo: 0)],
            category: .diet,
            extraHabits: [
                (.exercise, [localDate(daysAgo: 1)]),
                (.sleep, [localDate(daysAgo: 2)]),
            ]
        )
        #expect(try isUnlocked("Variety Seeker", in: achievements))
        #expect(try isUnlocked("Category Explorer", in: achievements) == false)
    }

    @Test("Two categories are not enough for the variety award")
    func twoCategoriesIsNotVariety() async throws {
        let achievements = try await unlocked(
            after: [localDate(daysAgo: 0)],
            category: .diet,
            extraHabits: [(.exercise, [localDate(daysAgo: 1)])]
        )
        #expect(try isUnlocked("Variety Seeker", in: achievements) == false)
    }

    @Test("An unlocked achievement keeps the date it was first earned")
    func unlockingIsNotRepeated() async throws {
        try await withTestDatabase { database in
            let service = AchievementService()
            let habitID = try await database.write { db -> Int in
                let habit = try Habit.upsert { testHabitDraft(name: "Habit") }.returning(\.self).fetchOne(db)
                return habit!.id
            }

            func checkIn(daysAgo: Int) async throws -> CheckIn {
                try await database.write { db in
                    try CheckIn
                        .upsert { CheckIn.Draft(date: localDate(daysAgo: daysAgo), habitID: habitID) }
                        .returning(\.self)
                        .fetchOne(db)!
                }
            }

            await service.checkAchievementsAndShow(for: try await checkIn(daysAgo: 1))
            let first = try await database.read { db in try Achievement.all.fetchAll(db) }
            let firstDate = try #require(Achievement.named("First Milestone", in: first)?.unlockedDate)

            await service.checkAchievementsAndShow(for: try await checkIn(daysAgo: 0))
            let second = try await database.read { db in try Achievement.all.fetchAll(db) }
            let secondDate = try #require(Achievement.named("First Milestone", in: second)?.unlockedDate)

            #expect(firstDate == secondDate)
        }
    }
}
