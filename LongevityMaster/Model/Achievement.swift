//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

@Table
struct Achievement: Identifiable {
    let id: Int
    var title: String
    var description: String
    var icon: String
    var type: AchievementType
    @Column(as: AchievementCriteria.JSONRepresentation.self)
    var criteria: AchievementCriteria
    var isUnlocked: Bool
    var unlockedDate: Date?
    var habitID: Int? // nil for global achievements
}

extension Achievement.Draft: Identifiable {}

enum AchievementType: Int, Codable, QueryBindable {
    case streak
    case totalCheckIns
    case perfectWeek
    case perfectMonth
    case categoryMaster
    case earlyBird
    case nightOwl
    case consistency
    case variety
    case milestone
    // Stored as their raw values, so new kinds only ever go on the end.
    /// Checking in again after `targetValue` days or more with no check-ins at all.
    case comeback
    /// Habits from `targetValue` different categories checked in on the same day.
    case balancedDay
    /// `targetValue` programs seen through to their last day.
    case programGraduate
    /// A longevity score of `targetValue` or more.
    case longevityRating
    /// Still checking in `targetValue` days after the first check-in.
    case anniversary
    /// A streak of `targetValue` days on a habit rated five stars.
    case topHabitStreak

    var title: String {
        switch self {
        case .streak: return String(localized: "Streak Master")
        case .totalCheckIns: return String(localized: "Check-in Champion")
        case .perfectWeek: return String(localized: "Perfect Week")
        case .perfectMonth: return String(localized: "Perfect Month")
        case .categoryMaster: return String(localized: "Category Master")
        case .earlyBird: return String(localized: "Early Bird")
        case .nightOwl: return String(localized: "Night Owl")
        case .consistency: return String(localized: "Consistency King")
        case .variety: return String(localized: "Variety Seeker")
        case .milestone: return String(localized: "Milestone Reacher")
        case .comeback: return String(localized: "Comeback Kid")
        case .balancedDay: return String(localized: "Balanced Day")
        case .programGraduate: return String(localized: "Program Graduate")
        case .longevityRating: return String(localized: "Rising Star")
        case .anniversary: return String(localized: "One Year Strong")
        case .topHabitStreak: return String(localized: "Five-Star Focus")
        }
    }

    var icon: String {
        switch self {
        case .streak: return "🔥"
        case .totalCheckIns: return "✅"
        case .perfectWeek: return "⭐"
        case .perfectMonth: return "🏆"
        case .categoryMaster: return "👑"
        case .earlyBird: return "🌅"
        case .nightOwl: return "🦉"
        case .consistency: return "📈"
        case .variety: return "🌈"
        case .milestone: return "🎯"
        case .comeback: return "💪"
        case .balancedDay: return "⚖️"
        case .programGraduate: return "🎓"
        case .longevityRating: return "🏅"
        case .anniversary: return "🎂"
        case .topHabitStreak: return "💎"
        }
    }
}

struct AchievementCriteria: Codable, Hashable {
    var targetValue: Int
    var timeFrame: TimeFrame?
    var category: HabitCategory?
    
    enum TimeFrame: String, Codable {
        case day = "day"
        case week = "week"
        case month = "month"
        case year = "year"
        case allTime = "allTime"
    }
    
    // Custom encoding/decoding for JSON storage in database
    func encode() -> String {
        let data = try? JSONEncoder().encode(self)
        return String(data: data ?? Data(), encoding: .utf8) ?? "{}"
    }
    
    static func decode(from string: String) -> AchievementCriteria? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AchievementCriteria.self, from: data)
    }
}

// Achievement definitions
struct AchievementDefinitions {
    static let all: [Achievement.Draft] = [
        // Streak achievements
        Achievement.Draft(
            title: String(localized: "First Steps"),
            description: String(localized: "Complete a habit 3 days in a row"),
            icon: "🔥",
            type: .streak,
            criteria: AchievementCriteria(targetValue: 3),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Week Warrior"),
            description: String(localized: "Maintain a 7-day streak"),
            icon: "🔥",
            type: .streak,
            criteria: AchievementCriteria(targetValue: 7),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Month Master"),
            description: String(localized: "Maintain a 30-day streak"),
            icon: "🔥",
            type: .streak,
            criteria: AchievementCriteria(targetValue: 30),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Total check-ins
        Achievement.Draft(
            title: String(localized: "Getting Started"),
            description: String(localized: "Complete 10 total check-ins"),
            icon: "✅",
            type: .totalCheckIns,
            criteria: AchievementCriteria(targetValue: 10),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Habit Builder"),
            description: String(localized: "Complete 50 total check-ins"),
            icon: "✅",
            type: .totalCheckIns,
            criteria: AchievementCriteria(targetValue: 50),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Habit Master"),
            description: String(localized: "Complete 100 total check-ins"),
            icon: "✅",
            type: .totalCheckIns,
            criteria: AchievementCriteria(targetValue: 100),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Perfect week/month
        Achievement.Draft(
            title: String(localized: "Perfect Week"),
            description: String(localized: "Complete all scheduled habits for a week"),
            icon: "⭐",
            type: .perfectWeek,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Perfect Month"),
            description: String(localized: "Complete all scheduled habits for a month"),
            icon: "🏆",
            type: .perfectMonth,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Category achievements
        Achievement.Draft(
            title: String(localized: "Diet Champion"),
            description: String(localized: "Complete 20 diet-related habits"),
            icon: "👑",
            type: .categoryMaster,
            criteria: AchievementCriteria(targetValue: 20, category: .diet),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Fitness Fanatic"),
            description: String(localized: "Complete 20 exercise-related habits"),
            icon: "👑",
            type: .categoryMaster,
            criteria: AchievementCriteria(targetValue: 20, category: .exercise),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Sleep Specialist"),
            description: String(localized: "Complete 20 sleep-related habits"),
            icon: "👑",
            type: .categoryMaster,
            criteria: AchievementCriteria(targetValue: 20, category: .sleep),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Mental Health Guru"),
            description: String(localized: "Complete 20 mental health habits"),
            icon: "👑",
            type: .categoryMaster,
            criteria: AchievementCriteria(targetValue: 20, category: .mentalHealth),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Health Guardian"),
            description: String(localized: "Complete 20 preventive health habits"),
            icon: "👑",
            type: .categoryMaster,
            criteria: AchievementCriteria(targetValue: 20, category: .preventiveHealth),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Time-based achievements
        Achievement.Draft(
            title: String(localized: "Early Bird"),
            description: String(localized: "Complete a habit before 8 AM"),
            icon: "🌅",
            type: .earlyBird,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Night Owl"),
            description: String(localized: "Complete a habit after 10 PM"),
            icon: "🦉",
            type: .nightOwl,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Consistency achievements
        Achievement.Draft(
            title: String(localized: "Consistent"),
            description: String(localized: "Complete habits 5 days in a row"),
            icon: "📈",
            type: .consistency,
            criteria: AchievementCriteria(targetValue: 5),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Variety achievements
        Achievement.Draft(
            title: String(localized: "Variety Seeker"),
            description: String(localized: "Complete habits from 3 different categories"),
            icon: "🌈",
            type: .variety,
            criteria: AchievementCriteria(targetValue: 3),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Milestone achievements
        Achievement.Draft(
            title: String(localized: "First Milestone"),
            description: String(localized: "Complete your first habit"),
            icon: "🎯",
            type: .milestone,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Additional streak achievements
        Achievement.Draft(
            title: String(localized: "Century Streak"),
            description: String(localized: "Maintain a 100-day streak"),
            icon: "🔥",
            type: .streak,
            criteria: AchievementCriteria(targetValue: 100),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Additional total check-ins
        Achievement.Draft(
            title: String(localized: "Habit Legend"),
            description: String(localized: "Complete 500 total check-ins"),
            icon: "✅",
            type: .totalCheckIns,
            criteria: AchievementCriteria(targetValue: 500),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Habit Grandmaster"),
            description: String(localized: "Complete 1000 total check-ins"),
            icon: "✅",
            type: .totalCheckIns,
            criteria: AchievementCriteria(targetValue: 1000),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Additional consistency achievements
        Achievement.Draft(
            title: String(localized: "Super Consistent"),
            description: String(localized: "Complete habits 10 days in a row"),
            icon: "📈",
            type: .consistency,
            criteria: AchievementCriteria(targetValue: 10),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Ultra Consistent"),
            description: String(localized: "Complete habits 20 days in a row"),
            icon: "📈",
            type: .consistency,
            criteria: AchievementCriteria(targetValue: 20),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Additional variety achievements
        Achievement.Draft(
            title: String(localized: "Category Explorer"),
            description: String(localized: "Complete habits from all 5 categories"),
            icon: "🌈",
            type: .variety,
            criteria: AchievementCriteria(targetValue: 5),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),

        // Added in 1.10. Existing databases get these from the "Add achievements for 1.10"
        // migration, which inserts whichever definitions are missing.
        Achievement.Draft(
            title: String(localized: "Comeback Kid"),
            description: String(localized: "Check in again after a week away"),
            icon: "💪",
            type: .comeback,
            criteria: AchievementCriteria(targetValue: 7),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Balanced Day"),
            description: String(localized: "Complete habits from 3 categories in one day"),
            icon: "⚖️",
            type: .balancedDay,
            criteria: AchievementCriteria(targetValue: 3),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Whole-Body Day"),
            description: String(localized: "Complete habits from all 5 categories in one day"),
            icon: "⚖️",
            type: .balancedDay,
            criteria: AchievementCriteria(targetValue: 5),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Program Graduate"),
            description: String(localized: "Finish a program"),
            icon: "🎓",
            type: .programGraduate,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Program Collector"),
            description: String(localized: "Finish 3 programs"),
            icon: "🎓",
            type: .programGraduate,
            criteria: AchievementCriteria(targetValue: 3),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Rising Star"),
            description: String(localized: "Reach a B longevity rating"),
            icon: "🏅",
            type: .longevityRating,
            criteria: AchievementCriteria(targetValue: 600),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "High Achiever"),
            description: String(localized: "Reach an A longevity rating"),
            icon: "🏅",
            type: .longevityRating,
            criteria: AchievementCriteria(targetValue: 800),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Longevity Expert"),
            description: String(localized: "Reach an S longevity rating"),
            icon: "🏅",
            type: .longevityRating,
            criteria: AchievementCriteria(targetValue: 900),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "Five-Star Focus"),
            description: String(localized: "Keep a 30-day streak on a 5-star habit"),
            icon: "💎",
            type: .topHabitStreak,
            criteria: AchievementCriteria(targetValue: 30),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: String(localized: "One Year Strong"),
            description: String(localized: "Still checking in a year after your first check-in"),
            icon: "🎂",
            type: .anniversary,
            criteria: AchievementCriteria(targetValue: 365),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
    ]

    /// Adds every definition the database does not have yet, matched by type and criteria
    /// rather than by title, which is stored in whatever language the app was in.
    static func insertMissing(in db: Database) throws {
        let existing = Set(try Achievement.all.fetchAll(db).map(AchievementIdentity.init))
        let missing = all.filter { draft in
            !existing.contains(
                AchievementIdentity(
                    kind: draft.type.rawValue,
                    target: draft.criteria.targetValue,
                    category: draft.criteria.category?.rawValue
                )
            )
        }
        guard !missing.isEmpty else { return }
        try Achievement.insert { missing }.execute(db)
    }
}

// MARK: - Showing an achievement in the current language

extension Achievement {
    /// Achievements are stored with the text they were first written with, in whatever
    /// language the app was running then — and the language picker can change that since. So
    /// the text shown comes from the definitions, which are always in the current language.
    var localizedTitle: String {
        AchievementDefinitions.definition(type: type, criteria: criteria)?.title ?? title
    }

    var localizedDescription: String {
        AchievementDefinitions.definition(type: type, criteria: criteria)?.description ?? description
    }
}

extension AchievementDefinitions {
    private struct Key: Hashable {
        let type: AchievementType
        let criteria: AchievementCriteria
    }

    private static let byKey = Dictionary(
        all.map { (Key(type: $0.type, criteria: $0.criteria), $0) },
        uniquingKeysWith: { first, _ in first }
    )

    /// The definition an achievement was created from. A type and its criteria identify one
    /// uniquely; the tests hold the definitions to that.
    static func definition(type: AchievementType, criteria: AchievementCriteria) -> Achievement.Draft? {
        byKey[Key(type: type, criteria: criteria)]
    }
}
