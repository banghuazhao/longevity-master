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
        let habitsScore = calculateHabitsScore()
        let antiAgingScore = calculateAntiAgingScore()
        let achievementsScore = calculateAchievementsScore()
        let checkInsScore = calculateCheckInsScore()
        let streakScore = calculateLongestStreakScore()
        
        let totalScore = habitsScore + antiAgingScore + achievementsScore + checkInsScore + streakScore
        
        return LongevityScoreBreakdown(
            totalScore: totalScore,
            habitsScore: habitsScore,
            antiAgingScore: antiAgingScore,
            achievementsScore: achievementsScore,
            checkInsScore: checkInsScore,
            streakScore: streakScore
        )
    }
    
    private func calculateHabitsScore() -> Int {
        let habits = allHabits.filter { !$0.isArchived }
        
        // Score based on number of active habits
        // 10 points per habit, max 300 points (30 habits)
        return min(habits.count * 10, ScoreCategory.activeHabits.maxScore)
    }
    
    private func calculateAntiAgingScore() -> Int {
        let habits = allHabits.filter { !$0.isArchived }
        
        // Score based on total anti-aging rating of all habits
        // Each habit has antiAgingRating from 1-5
        let totalAntiAgingRating = habits.reduce(0) { $0 + $1.antiAgingRating }
        
        // 2 points per anti-aging rating point, max 300 points
        return min(totalAntiAgingRating * 2, ScoreCategory.antiAgingRating.maxScore)
    }
    
    private func calculateAchievementsScore() -> Int {
        let achievements = allAchievements
            .filter { $0.isUnlocked }
        
        // Score based on number of unlocked achievements
        // 10 points per achievement
        return min(achievements.count * 10, ScoreCategory.achievements.maxScore)
    }
    
    private func calculateCheckInsScore() -> Int {
        // Score based on total number of check-ins
        // 2 points per check-in, max 200 points (100 check-ins)
        return min(allCheckIns.count * 2, ScoreCategory.totalCheckIns.maxScore)
    }
    
    private func calculateLongestStreakScore() -> Int {
        // Longest run of consecutive days carrying a check-in against any habit, counting
        // through days taken off from every habit. `userCalendar` builds a Calendar and reads
        // UserDefaults on every access, so it is taken once.
        let calendar = userCalendar
        let activeDays = Set(allCheckIns.map { $0.date.startOfDay(for: calendar) })
        let restDays = RestDays(allSkippedDays, in: calendar).everyHabit
        return min(
            calendar.longestDayStreak(in: activeDays, skipping: restDays) * 2,
            ScoreCategory.longestStreak.maxScore
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
