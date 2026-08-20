//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData
import Observation
import Sharing

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
                        try Achievement.upsert { achievementDraft }.execute(db)
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
                        updatedAchievement.habitID = checkIn.habitID
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
        let date = checkIn.date
        return everyHabitMetItsTarget(
            in: date.startOfWeek(for: userCalendar) ... date.endOfWeek(for: userCalendar),
            period: .week
        )
    }

    private func checkPerfectMonthAchievement(_ achievement: Achievement, criteria: AchievementCriteria, for checkIn: CheckIn) async -> Bool {
        let date = checkIn.date
        return everyHabitMetItsTarget(
            in: date.startOfMonth(for: userCalendar) ... date.endOfMonth(for: userCalendar),
            period: .month
        )
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
    
    /// Which period a "perfect" run is being judged over.
    private enum PerfectPeriod {
        case week
        case month
    }

    /// True when every active habit did what it owed over `range`.
    ///
    /// Fixed-schedule habits must have a check-in on each day they came due; days still ahead
    /// are not held against the user. Quota habits ("5 times a week") must have met the count.
    /// A habit whose quota period outlasts `range` — a monthly quota judged over one week —
    /// cannot be settled here and is passed over; a weekly quota judged over a month has to
    /// have been met in every whole week the month contains.
    ///
    /// Returns false when nothing could be judged at all, so a user with no habits does not
    /// get handed a perfect week.
    private func everyHabitMetItsTarget(in range: ClosedRange<Date>, period: PerfectPeriod) -> Bool {
        let habits = allHabits.filter { !$0.isArchived }
        guard !habits.isEmpty else { return false }

        let checkInsByHabit = Dictionary(grouping: allCheckIns, by: \.habitID)
        let now = Date()
        var judgedAnything = false

        for habit in habits {
            let checkIns = (checkInsByHabit[habit.id] ?? []).filter { range.contains($0.date) }

            switch habit.frequency {
            case .fixedDaysInWeek, .fixedDaysInMonth:
                let due = scheduledDays(for: habit, in: range).filter { $0 <= now }
                guard !due.isEmpty else { continue }
                judgedAnything = true
                let checkedDays = Set(checkIns.map { $0.date.startOfDay(for: userCalendar) })
                guard Set(due).isSubset(of: checkedDays) else { return false }

            case .nDaysEachWeek:
                judgedAnything = true
                switch period {
                case .week:
                    guard checkIns.count >= habit.nDaysPerWeek else { return false }
                case .month:
                    for week in wholeWeeks(in: range) where week.upperBound <= now {
                        let met = checkIns.filter { week.contains($0.date) }.count
                        guard met >= habit.nDaysPerWeek else { return false }
                    }
                }

            case .nDaysEachMonth:
                guard period == .month else { continue }
                judgedAnything = true
                guard checkIns.count >= habit.nDaysPerMonth else { return false }
            }
        }

        return judgedAnything
    }

    /// The days inside `range` on which a fixed-schedule habit came due. Empty for quota
    /// habits, which owe a count over the period rather than any particular day.
    private func scheduledDays(for habit: Habit, in range: ClosedRange<Date>) -> [Date] {
        let days: Set<Int>
        let unit: Calendar.Component
        switch habit.frequency {
        case .fixedDaysInWeek:
            days = habit.daysOfWeek
            unit = .weekday
        case .fixedDaysInMonth:
            days = habit.daysOfMonth
            unit = .day
        case .nDaysEachWeek, .nDaysEachMonth:
            return []
        }
        guard !days.isEmpty else { return [] }

        var result: [Date] = []
        var day = range.lowerBound.startOfDay(for: userCalendar)
        while day <= range.upperBound {
            if days.contains(userCalendar.component(unit, from: day)) {
                result.append(day)
            }
            guard let next = userCalendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// The weeks lying wholly inside `range`, so judging a weekly quota over a month does not
    /// fail on the part-weeks hanging off either end.
    private func wholeWeeks(in range: ClosedRange<Date>) -> [ClosedRange<Date>] {
        var weeks: [ClosedRange<Date>] = []
        var start = range.lowerBound.startOfWeek(for: userCalendar)
        while start <= range.upperBound {
            let end = start.endOfWeek(for: userCalendar)
            if start >= range.lowerBound, end <= range.upperBound {
                weeks.append(start ... end)
            }
            guard let next = userCalendar.date(byAdding: .weekOfYear, value: 1, to: start) else { break }
            start = next
        }
        return weeks
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
