//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SharingGRDB
import Observation

@Observable
class AchievementService {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    @ObservationIgnored
    @FetchAll(Achievement.all, animation: .default) var allAchievements
    
    @ObservationIgnored
    @FetchAll(CheckIn.all, animation: .default) var allCheckIns
    
    @ObservationIgnored
    @FetchAll(Habit.all, animation: .default) var allHabits
    
    @ObservationIgnored
    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true

    var userCalendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = startWeekOnMonday ? 2 : 1 // 2 = Monday, 1 = Sunday
        return cal
    }
    
    var unlockedAchievements: [Achievement] {
        allAchievements.filter { $0.isUnlocked }
    }
    
    var lockedAchievements: [Achievement] {
        allAchievements.filter { !$0.isUnlocked }
    }
    
    var achievementToShow: Achievement?

    init() {
        // Initialize achievements if they don't exist
        Task {
            await initializeAchievements()
        }
    }
    
    private func initializeAchievements() async {
        await withErrorReporting {
            try await database.write { db in
                let existingCount = try Achievement.all.fetchCount(db)
                if existingCount == 0 {
                    // Insert all achievement definitions
                    for achievementDraft in AchievementDefinitions.all {
                        try Achievement.upsert(achievementDraft).execute(db)
                    }
                }
            }
        }
    }
    
    func checkAchievementsAndShow(for checkIn: CheckIn) async {
        var newlyUnlocked: [Achievement] = []
        
        await withErrorReporting {
            for achievement in allAchievements where !achievement.isUnlocked {
                if await checkAchievementCriteria(achievement, for: checkIn) {
                    let updatedAchievement = try await database.write { db in
                        var updatedAchievement = achievement
                        updatedAchievement.isUnlocked = true
                        updatedAchievement.unlockedDate = Date()
                        return try Achievement.update(updatedAchievement).returning(\.self).fetchOne(db)
                    }
                    if let updatedAchievement {
                        newlyUnlocked.append(updatedAchievement)
                    }
                }
            }
        }
        
        if !newlyUnlocked.isEmpty {
            let toShow = newlyUnlocked.first
            await MainActor.run {
                achievementToShow = toShow
            }
        }
    }
    
    private func checkAchievementCriteria(_ achievement: Achievement, for checkIn: CheckIn) async -> Bool {
        // Decode criteria from string
        guard let criteria = AchievementCriteria.decode(from: achievement.criteria.encode()) else {
            return false
        }
        
        switch achievement.type {
        case .streak:
            return await checkStreakAchievement(achievement, criteria: criteria, for: checkIn)
        case .totalCheckIns:
            return await checkTotalCheckInsAchievement(achievement, criteria: criteria, for: checkIn)
        case .perfectWeek:
            return await checkPerfectWeekAchievement(achievement, criteria: criteria, for: checkIn)
        case .perfectMonth:
            return await checkPerfectMonthAchievement(achievement, criteria: criteria, for: checkIn)
        case .categoryMaster:
            return await checkCategoryMasterAchievement(achievement, criteria: criteria, for: checkIn)
        case .earlyBird:
            return await checkEarlyBirdAchievement(achievement, criteria: criteria, for: checkIn)
        case .nightOwl:
            return await checkNightOwlAchievement(achievement, criteria: criteria, for: checkIn)
        case .consistency:
            return await checkConsistencyAchievement(achievement, criteria: criteria, for: checkIn)
        case .variety:
            return await checkVarietyAchievement(achievement, criteria: criteria, for: checkIn)
        case .milestone:
            return await checkMilestoneAchievement(achievement, criteria: criteria, for: checkIn)
        }
    }
    
    private func checkStreakAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        let targetStreak = criteria.targetValue
        let habitID = achievement.habitID ?? checkIn.habitID
    
        let checkIns = try? await database.read { db in
            try CheckIn
                .where { $0.habitID.eq(habitID) }
                .order { $0.date.desc() }
                .fetchAll(db)
        }
        
        guard let checkIns = checkIns, !checkIns.isEmpty else {
            return false
        }
        
        var currentStreak = 0
        var currentDate = checkIn.date
        
        for _ in 0..<targetStreak {
            let startOfDay = currentDate.startOfDay(for: userCalendar)
            let endOfDay = currentDate.endOfDay(for: userCalendar)
            
            let hasCheckIn = checkIns.contains { checkIn in
                checkIn.date >= startOfDay && checkIn.date <= endOfDay
            }
            
            if hasCheckIn {
                currentStreak += 1
                currentDate = userCalendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return currentStreak >= targetStreak
    }
    
    private func checkTotalCheckInsAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        let targetCount = criteria.targetValue
        let habitID = achievement.habitID ?? checkIn.habitID
        
        let totalCheckIns = await withErrorReporting {
            try await database.read { db in
                try CheckIn
                    .where { $0.habitID.eq(habitID) }
                    .order { $0.date.desc() }
                    .fetchAll(db)
            }
        }
        
        guard let totalCheckIns else { return false }
        
        return totalCheckIns.count >= targetCount
    }
    
    private func checkPerfectWeekAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        let weekStart = checkIn.date.startOfWeek(for: userCalendar)
        let weekEnd = checkIn.date.endOfWeek(for: userCalendar)
        
        let habits = allHabits
            .filter { !$0.isArchived }
            
        for habit in habits {
            let checkInsForHabit = allCheckIns
                .filter { $0.habitID == habit.id }
                .filter { $0.date >= weekStart && $0.date <= weekEnd }
            
            // Check if habit was scheduled for this week and completed
            let scheduledDays = getScheduledDays(for: habit, in: weekStart...weekEnd)
            let completedDays = Set(checkInsForHabit.map { userCalendar.component(.weekday, from: $0.date) })
            
            if !scheduledDays.isSubset(of: completedDays) {
                return false
            }
        }
        
        return true
    }
    
    private func checkPerfectMonthAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        let monthStart = checkIn.date.startOfMonth(for: userCalendar)
        let monthEnd = checkIn.date.endOfMonth(for: userCalendar)
        
        let habits = allHabits
            .filter { !$0.isArchived }
        
        for habit in habits {
            let checkInsForHabit = allCheckIns
                .filter { $0.habitID == habit.id }
                .filter { $0.date >= monthStart && $0.date <= monthEnd }
            
            // Check if habit was scheduled for this month and completed
            let scheduledDays = getScheduledDays(for: habit, in: monthStart...monthEnd)
            let completedDays = Set(checkInsForHabit.map { userCalendar.component(.day, from: $0.date) })
            
            if !scheduledDays.isSubset(of: completedDays) {
                return false
            }
        }
        
        return true
    }
    
    private func checkCategoryMasterAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        guard let targetCategory = criteria.category else { return false }
        let targetCount = criteria.targetValue
        
        var categoryCheckIns = 0
        for checkIn in allCheckIns  {
            for habit in allHabits where habit.id == checkIn.habitID {
                if habit.category == targetCategory {
                    categoryCheckIns += 1
                }
            }
        }
        
        return categoryCheckIns >= targetCount
    }
    
    private func checkEarlyBirdAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        let hour = userCalendar.component(.hour, from: checkIn.date)
        return hour < 8
    }
    
    private func checkNightOwlAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        let hour = userCalendar.component(.hour, from: checkIn.date)
        return hour >= 22
    }
    
    private func checkConsistencyAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        let targetDays = criteria.targetValue
        var currentDate = checkIn.date
        var consecutiveDays = 0
        
        for _ in 0..<targetDays {
            let startOfDay = currentDate.startOfDay(for: userCalendar)
            let endOfDay = currentDate.endOfDay(for: userCalendar)
            
            let hasAnyCheckIn = allCheckIns
                .filter { $0.date >= startOfDay && $0.date <= endOfDay }
                .count > 0
            
            if hasAnyCheckIn {
                consecutiveDays += 1
                currentDate = userCalendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return consecutiveDays >= targetDays
    }
    
    private func checkVarietyAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        let targetCategories = criteria.targetValue
        
        var uniqueCategories = Set<HabitCategory>()
        for checkIn in allCheckIns  {
            for habit in allHabits where habit.id == checkIn.habitID {
                uniqueCategories.insert(habit.category)
            }
        }
        
        return uniqueCategories.count >= targetCategories
    }
    
    private func checkMilestoneAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        return allCheckIns.count >= criteria.targetValue
    }
    
    private func getScheduledDays(for habit: Habit, in dateRange: ClosedRange<Date>) -> Set<Int> {
        var scheduledDays: Set<Int> = []
        
        switch habit.frequency {
        case .fixedDaysInWeek:
            scheduledDays = habit.daysOfWeek
        case .fixedDaysInMonth:
            scheduledDays = habit.daysOfMonth
        case .nDaysEachWeek, .nDaysEachMonth:
            // For these types, we consider all days as potentially scheduled
            scheduledDays = Set(1...31)
        }
        
        return scheduledDays
    }
} 


// Dependency injection
extension DependencyValues {
    var achievementService: AchievementService {
        get { self[AchievementServiceKey.self] }
        set { self[AchievementServiceKey.self] = newValue }
    }
}

private enum AchievementServiceKey: DependencyKey {
    static let liveValue = AchievementService()
}
