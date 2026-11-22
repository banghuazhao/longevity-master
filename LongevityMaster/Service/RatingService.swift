//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData
import SwiftUI
import Sharing

@Observable
class RatingService {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    @ObservationIgnored
    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true
    
    var userCalendar: Calendar {
        .userPreferred(startWeekOnMonday: startWeekOnMonday)
    }
    
    @ObservationIgnored
    @FetchAll(Habit.all, animation: .default) var allHabits
    
    @ObservationIgnored
    @FetchAll(Achievement.all, animation: .default) var allAchievements
    
    @ObservationIgnored
    @FetchAll(CheckIn.all, animation: .default) var allCheckIns

    @ObservationIgnored
    @FetchAll(SkippedDay.all, animation: .default) var allSkippedDays
    
    func calculateLongevityScore() -> LongevityScoreBreakdown {
        Self.score(
            habits: allHabits,
            unlockedAchievementCount: allAchievements.count(where: \.isUnlocked),
            checkIns: allCheckIns,
            skippedDays: allSkippedDays,
            calendar: userCalendar
        )
    }

    /// The score worked out from the data alone, so the achievement checks — which read their
    /// own snapshot rather than this service's observed copies — arrive at the same number.
    static func score(
        habits: [Habit],
        unlockedAchievementCount: Int,
        checkIns: [CheckIn],
        skippedDays: [SkippedDay],
        calendar: Calendar
    ) -> LongevityScoreBreakdown {
        let activeHabits = habits.filter { !$0.isArchived }

        // 10 points per active habit, max 300 points (30 habits).
        let habitsScore = min(activeHabits.count * 10, ScoreCategory.activeHabits.maxScore)

        // 2 points per anti-aging star across the active habits, max 300 points.
        let totalAntiAgingRating = activeHabits.reduce(0) { $0 + $1.antiAgingRating }
        let antiAgingScore = min(totalAntiAgingRating * 2, ScoreCategory.antiAgingRating.maxScore)

        // 10 points per unlocked achievement.
        let achievementsScore = min(unlockedAchievementCount * 10, ScoreCategory.achievements.maxScore)

        // 2 points per check-in, max 200 points (100 check-ins).
        let checkInsScore = min(checkIns.count * 2, ScoreCategory.totalCheckIns.maxScore)

        // Longest run of consecutive days carrying a check-in against any habit, counting
        // through days taken off from every habit.
        let activeDays = Set(checkIns.map { $0.date.startOfDay(for: calendar) })
        let restDays = RestDays(skippedDays, in: calendar).everyHabit
        let streakScore = min(
            calendar.longestDayStreak(in: activeDays, skipping: restDays) * 2,
            ScoreCategory.longestStreak.maxScore
        )

        return LongevityScoreBreakdown(
            totalScore: habitsScore + antiAgingScore + achievementsScore + checkInsScore + streakScore,
            habitsScore: habitsScore,
            antiAgingScore: antiAgingScore,
            achievementsScore: achievementsScore,
            checkInsScore: checkInsScore,
            streakScore: streakScore
        )
    }
    
    /// Takes the breakdown rather than building its own: computing one walks every habit,
    /// achievement and check-in, and callers already have the result in hand.
    func getScoreBreakdown(from breakdown: LongevityScoreBreakdown) -> [ScoreBreakdownItem] {
        [
            ScoreBreakdownItem(
                category: .activeHabits,
                score: breakdown.habitsScore
            ),
            ScoreBreakdownItem(
                category: .antiAgingRating,
                score: breakdown.antiAgingScore
            ),
            ScoreBreakdownItem(
                category: .achievements,
                score: breakdown.achievementsScore
            ),
            ScoreBreakdownItem(
                category: .totalCheckIns,
                score: breakdown.checkInsScore
            ),
            ScoreBreakdownItem(
                category: .longestStreak,
                score: breakdown.streakScore
            )
        ]
    }
}



// Dependency injection
extension DependencyValues {
    var ratingService: RatingService {
        get { self[RatingServiceKey.self] }
        set { self[RatingServiceKey.self] = newValue }
    }
}

private enum RatingServiceKey: DependencyKey {
    static let liveValue = RatingService()
} 
