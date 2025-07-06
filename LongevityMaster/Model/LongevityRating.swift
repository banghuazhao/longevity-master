//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SwiftUI

enum LongevityRating: String, CaseIterable {
    case f = "F"
    case dMinus = "D-"
    case d = "D"
    case cMinus = "C-"
    case c = "C"
    case bMinus = "B-"
    case b = "B"
    case aMinus = "A-"
    case a = "A"
    case s = "S"
    case ss = "SS"
    case sss = "SSS"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .f: return .gray
        case .dMinus: return .green
        case .d: return .green
        case .cMinus: return .cyan
        case .c: return .cyan
        case .bMinus: return .blue
        case .b: return .blue
        case .aMinus: return .purple
        case .a: return .purple
        case .s: return .yellow
        case .ss: return .yellow
        case .sss: return .red
        }
    }
    
    var description: String {
        switch self {
        case .f: return String(localized: "Beginner")
        case .dMinus: return String(localized: "Novice")
        case .d: return String(localized: "Novice+")
        case .cMinus: return String(localized: "Apprentice")
        case .c: return String(localized: "Apprentice+")
        case .bMinus: return String(localized: "Intermediate")
        case .b: return String(localized: "Intermediate+")
        case .aMinus: return String(localized: "Advanced")
        case .a: return String(localized: "Advanced+")
        case .s: return String(localized: "Expert")
        case .ss: return String(localized: "Master")
        case .sss: return String(localized: "Legend")
        }
    }
    
    static func fromScore(_ score: Int) -> LongevityRating {
        switch score {
        case 0..<100: return .f
        case 100..<200: return .dMinus
        case 200..<300: return .d
        case 300..<400: return .cMinus
        case 400..<500: return .c
        case 500..<600: return .bMinus
        case 600..<700: return .b
        case 700..<800: return .aMinus
        case 800..<900: return .a
        case 900..<1000: return .s
        case 1000..<1100: return .ss
        default: return .sss
        }
    }
}

enum ScoreCategory: String, CaseIterable {
    case activeHabits = "Active Habits"
    case antiAgingRating = "Anti-Aging Rating"
    case achievements = "Achievements"
    case totalCheckIns = "Total Check-ins"
    case longestStreak = "Longest Streak"
    
    var localizedTitle: String {
        switch self {
        case .activeHabits: return String(localized: "Active Habits")
        case .antiAgingRating: return String(localized: "Anti-Aging Rating")
        case .achievements: return String(localized: "Achievements")
        case .totalCheckIns: return String(localized: "Total Check-ins")
        case .longestStreak: return String(localized: "Longest Streak")
        }
    }
    
    var maxScore: Int {
        switch self {
        case .activeHabits: return 300
        case .antiAgingRating: return 300
        case .achievements: return AchievementDefinitions.all.count * 10
        case .totalCheckIns: return 200
        case .longestStreak: return 250
        }
    }
    
    var icon: String {
        switch self {
        case .activeHabits: return "list.bullet"
        case .antiAgingRating: return "heart.fill"
        case .achievements: return "trophy.fill"
        case .totalCheckIns: return "checkmark.circle.fill"
        case .longestStreak: return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .activeHabits: return .blue
        case .antiAgingRating: return .red
        case .achievements: return .yellow
        case .totalCheckIns: return .green
        case .longestStreak: return .orange
        }
    }
    
    var calculationExplanation: String {
        switch self {
        case .activeHabits:
            return String(localized: "10 points per active habit, up to 30 habits (300 points max). Only non-archived habits count.")
        case .antiAgingRating:
            return String(localized: "2 points per anti-aging rating point. Each habit has a rating from 1-5. Maximum 300 points.")
        case .achievements:
            return String(localized: "10 points per unlocked achievement. Currently \(AchievementDefinitions.all.count) achievements available.")
        case .totalCheckIns:
            return String(localized: "2 points per check-in, up to 100 check-ins (200 points max). All check-ins across all habits count.")
        case .longestStreak:
            return String(localized: "2 points per day in your longest consecutive streak. Maximum 125 days (250 points).")
        }
    }
}

struct LongevityScoreBreakdown {
    let totalScore: Int
    let habitsScore: Int
    let antiAgingScore: Int
    let achievementsScore: Int
    let checkInsScore: Int
    let streakScore: Int
    
    var rating: LongevityRating {
        return LongevityRating.fromScore(totalScore)
    }
    
    var nextRating: LongevityRating? {
        let currentIndex = LongevityRating.allCases.firstIndex(of: rating) ?? 0
        let nextIndex = currentIndex + 1
        return nextIndex < LongevityRating.allCases.count ? LongevityRating.allCases[nextIndex] : nil
    }
    
    var scoreToNextRating: Int {
        guard let nextRating = nextRating else { return 0 }
        let currentScore = totalScore
        let nextScore = scoreForRating(nextRating)
        return max(0, nextScore - currentScore)
    }
    
    private func scoreForRating(_ rating: LongevityRating) -> Int {
        switch rating {
        case .f: return 0
        case .dMinus: return 100
        case .d: return 200
        case .cMinus: return 300
        case .c: return 400
        case .bMinus: return 500
        case .b: return 600
        case .aMinus: return 700
        case .a: return 800
        case .s: return 900
        case .ss: return 1000
        case .sss: return 1100
        }
    }
}

struct ScoreBreakdownItem {
    let category: ScoreCategory
    let score: Int
    
    var maxScore: Int {
        return category.maxScore
    }
    
    var icon: String {
        return category.icon
    }
    
    var color: Color {
        return category.color
    }
    
    var title: String {
        return category.localizedTitle
    }
    
    var percentage: Double {
        return Double(score) / Double(maxScore)
    }
    
    var explanation: String {
        return category.calculationExplanation
    }
} 
