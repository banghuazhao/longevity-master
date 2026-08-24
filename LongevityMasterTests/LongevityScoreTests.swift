//
// Created by Banghua Zhao on 25/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import LongevityMaster

/// The score the Rating tab is built around, and the grade it turns into.
@Suite("The longevity score")
struct LongevityScoreTests {
    // MARK: - Grades

    @Test(
        "Each hundred points is the next grade up",
        arguments: [
            (0, LongevityRating.f),
            (99, .f),
            (100, .dMinus),
            (250, .d),
            (400, .c),
            (899, .a),
            (1000, .ss),
            (1100, .sss),
            (5000, .sss),
        ]
    )
    func gradeForScore(score: Int, expected: LongevityRating) {
        #expect(LongevityRating.fromScore(score) == expected)
    }

    @Test("The points still to earn are the points to the next grade's floor")
    func pointsToTheNextGrade() {
        let breakdown = LongevityScoreBreakdown(
            totalScore: 446,
            habitsScore: 240,
            antiAgingScore: 188,
            achievementsScore: 10,
            checkInsScore: 6,
            streakScore: 2
        )
        #expect(breakdown.rating == .c)
        #expect(breakdown.nextRating == .bMinus)
        #expect(breakdown.scoreToNextRating == 54)
    }

    @Test("The top grade has nothing above it")
    func theTopGradeIsTheEnd() {
        let breakdown = LongevityScoreBreakdown(
            totalScore: 1200,
            habitsScore: 0,
            antiAgingScore: 0,
            achievementsScore: 0,
            checkInsScore: 0,
            streakScore: 0
        )
        #expect(breakdown.rating == .sss)
        #expect(breakdown.nextRating == nil)
        #expect(breakdown.scoreToNextRating == 0)
    }

    // MARK: - Scoring

    @Test("Every part of the score is counted, and the total is their sum")
    func scoreAddsUp() async throws {
        try await withTestDatabase { database in
            let service = RatingService()
            try await database.write { db in
                // Two active habits rated 5 and 3, one archived habit that should count for
                // neither the habit nor the anti-aging score.
                try Habit.upsert { testHabitDraft(name: "A", antiAgingRating: 5) }.execute(db)
                try Habit.upsert { testHabitDraft(name: "B", antiAgingRating: 3) }.execute(db)
                try Habit.upsert { testHabitDraft(name: "C", antiAgingRating: 5, isArchived: true) }.execute(db)
            }
            let habitIDs = try await database.read { db in try Habit.all.fetchAll(db).map(\.id) }
            let first = try #require(habitIDs.first)

            try await database.write { db in
                // Three days running, so a longest streak of 3.
                for day in ["2026-08-23", "2026-08-24", "2026-08-25"] {
                    try CheckIn.upsert { CheckIn.Draft(date: testDate(day), habitID: first) }.execute(db)
                }
            }

            try await service.reload()
            let breakdown = service.calculateLongevityScore()

            #expect(breakdown.habitsScore == 20)      // 2 active habits × 10
            #expect(breakdown.antiAgingScore == 16)   // (5 + 3) × 2, the archived habit excluded
            #expect(breakdown.checkInsScore == 6)     // 3 check-ins × 2
            #expect(breakdown.streakScore == 6)       // a 3-day streak × 2
            #expect(breakdown.achievementsScore == 0) // nothing unlocked
            #expect(breakdown.totalScore == 48)
        }
    }

    @Test("An empty database scores nothing rather than failing")
    func emptyDatabaseScoresZero() async throws {
        try await withTestDatabase { _ in
            let service = RatingService()
            try await service.reload()
            let breakdown = service.calculateLongevityScore()
            #expect(breakdown.totalScore == 0)
            #expect(breakdown.rating == .f)
        }
    }

    @Test("Each part of the score stops at its ceiling")
    func scoresAreCapped() async throws {
        try await withTestDatabase { database in
            let service = RatingService()
            try await database.write { db in
                // Well past the 30-habit ceiling on the habits score.
                for index in 0 ..< 40 {
                    try Habit.upsert { testHabitDraft(name: "H\(index)", antiAgingRating: 5) }.execute(db)
                }
            }
            try await service.reload()
            let breakdown = service.calculateLongevityScore()

            #expect(breakdown.habitsScore == ScoreCategory.activeHabits.maxScore)
            #expect(breakdown.antiAgingScore == ScoreCategory.antiAgingRating.maxScore)
        }
    }
}
