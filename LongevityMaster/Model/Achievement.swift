//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SharingGRDB

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
    
    var title: String {
        switch self {
        case .streak: return "Streak Master"
        case .totalCheckIns: return "Check-in Champion"
        case .perfectWeek: return "Perfect Week"
        case .perfectMonth: return "Perfect Month"
        case .categoryMaster: return "Category Master"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .consistency: return "Consistency King"
        case .variety: return "Variety Seeker"
        case .milestone: return "Milestone Reacher"
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
        }
    }
}

struct AchievementCriteria: Codable {
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
            title: "First Steps",
            description: "Complete a habit 3 days in a row",
            icon: "🔥",
            type: .streak,
            criteria: AchievementCriteria(targetValue: 3),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: "Week Warrior",
            description: "Maintain a 7-day streak",
            icon: "🔥",
            type: .streak,
            criteria: AchievementCriteria(targetValue: 7),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: "Month Master",
            description: "Maintain a 30-day streak",
            icon: "🔥",
            type: .streak,
            criteria: AchievementCriteria(targetValue: 30),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Total check-ins
        Achievement.Draft(
            title: "Getting Started",
            description: "Complete 10 total check-ins",
            icon: "✅",
            type: .totalCheckIns,
            criteria: AchievementCriteria(targetValue: 10),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: "Habit Builder",
            description: "Complete 50 total check-ins",
            icon: "✅",
            type: .totalCheckIns,
            criteria: AchievementCriteria(targetValue: 50),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: "Habit Master",
            description: "Complete 100 total check-ins",
            icon: "✅",
            type: .totalCheckIns,
            criteria: AchievementCriteria(targetValue: 100),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Perfect week/month
        Achievement.Draft(
            title: "Perfect Week",
            description: "Complete all scheduled habits for a week",
            icon: "⭐",
            type: .perfectWeek,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: "Perfect Month",
            description: "Complete all scheduled habits for a month",
            icon: "🏆",
            type: .perfectMonth,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Category achievements
        Achievement.Draft(
            title: "Diet Champion",
            description: "Complete 20 diet-related habits",
            icon: "👑",
            type: .categoryMaster,
            criteria: AchievementCriteria(targetValue: 20, category: .diet),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: "Fitness Fanatic",
            description: "Complete 20 exercise-related habits",
            icon: "👑",
            type: .categoryMaster,
            criteria: AchievementCriteria(targetValue: 20, category: .exercise),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: "Sleep Specialist",
            description: "Complete 20 sleep-related habits",
            icon: "👑",
            type: .categoryMaster,
            criteria: AchievementCriteria(targetValue: 20, category: .sleep),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: "Mental Health Guru",
            description: "Complete 20 mental health habits",
            icon: "👑",
            type: .categoryMaster,
            criteria: AchievementCriteria(targetValue: 20, category: .mentalHealth),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: "Health Guardian",
            description: "Complete 20 preventive health habits",
            icon: "👑",
            type: .categoryMaster,
            criteria: AchievementCriteria(targetValue: 20, category: .preventiveHealth),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Time-based achievements
        Achievement.Draft(
            title: "Early Bird",
            description: "Complete a habit before 8 AM",
            icon: "🌅",
            type: .earlyBird,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        Achievement.Draft(
            title: "Night Owl",
            description: "Complete a habit after 10 PM",
            icon: "🦉",
            type: .nightOwl,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Consistency achievements
        Achievement.Draft(
            title: "Consistent",
            description: "Complete habits 5 days in a row",
            icon: "📈",
            type: .consistency,
            criteria: AchievementCriteria(targetValue: 5),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Variety achievements
        Achievement.Draft(
            title: "Variety Seeker",
            description: "Complete habits from 3 different categories",
            icon: "🌈",
            type: .variety,
            criteria: AchievementCriteria(targetValue: 3),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        ),
        
        // Milestone achievements
        Achievement.Draft(
            title: "First Milestone",
            description: "Complete your first habit",
            icon: "🎯",
            type: .milestone,
            criteria: AchievementCriteria(targetValue: 1),
            isUnlocked: false,
            unlockedDate: nil,
            habitID: nil
        )
    ]
} 
