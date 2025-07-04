//
// Created by Banghua Zhao on 01/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SharingGRDB
import SwiftUI

@Table
struct Habit: Identifiable {
    let id: Int
    var name: String = ""
    var category: HabitCategory = .diet
    var frequency: HabitFrequency = .fixedDaysInWeek
    var frequencyDetail: String = "1,2,3,4,5,6,7"
    var antiAgingRating: Int = 2
    var icon: String = "🥑"
    var color: Int = 0x2ECC71CC
    var note: String = ""
    var isFavorite: Bool = false
    var isArchived: Bool = false
}
extension Habit.Draft: Identifiable {}

enum HabitCategory: Int, Codable, QueryBindable {
    case diet
    case exercise
    case sleep
    case preventiveHealth
    case mentalHealth

    static var allCases: [HabitCategory] = [.diet, .exercise, .sleep, .preventiveHealth, .mentalHealth]

    var title: String {
        switch self {
        case .diet: return "🍎 Diet"
        case .exercise: return "🏋️ Exercise"
        case .sleep: return "😴 Sleep"
        case .preventiveHealth: return "🩺 Preventive Health"
        case .mentalHealth: return "🧘 Mental Health"
        }
    }
    
    var briefTitle: String {
        switch self {
        case .diet: return "🍎 Diet"
        case .exercise: return "🏋️ Exercise"
        case .sleep: return "😴 Sleep"
        case .preventiveHealth: return "🩺 Health"
        case .mentalHealth: return "🧘 Mental"
        }
    }
    
    var icon: String {
        switch self {
        case .diet: return "🥑"
        case .exercise: return "🏋️"
        case .sleep: return "😴"
        case .preventiveHealth: return "🩺"
        case .mentalHealth: return "🧘"
        }
    }
}

enum HabitFrequency: Int, QueryBindable {
    case fixedDaysInWeek
    case nDaysEachWeek
    case fixedDaysInMonth
    case nDaysEachMonth

    static var allCases: [HabitFrequency] = [
        .fixedDaysInWeek,
        .nDaysEachWeek,
        .fixedDaysInMonth,
        .nDaysEachMonth,
    ]

    var title: String {
        switch self {
        case .fixedDaysInWeek: return "Fixed Days in a Week"
        case .nDaysEachWeek: return "N Days Each Week"
        case .fixedDaysInMonth: return "Fixed Days in a Month"
        case .nDaysEachMonth: return "N Days Each Month"
        }
    }

    var maxDays: Int {
        switch self {
        case .fixedDaysInWeek, .nDaysEachWeek: return 7
        case .fixedDaysInMonth, .nDaysEachMonth: return 28
        }
    }
}

extension Habit {
    var truncatedName: String {
        name.count > 20 ? name.prefix(20) + "…" : name
    }
    
    var borderColor: Color {
        Color(hex: color).blend(with: .black, amount: 0.2)
    }

    var frequencyDescription: String {
        switch frequency {
        case .fixedDaysInWeek:
            return daysOfWeek.isEmpty ? "No days set" : "Every \(daysOfWeekString) of week"
        case .nDaysEachWeek:
            let days = Int(frequencyDetail)
            guard let days else { return "No days set" }
            if days == 1 {
                return "1 day each week"
            } else {
                return "\(days) days each week"
            }
        case .fixedDaysInMonth:
            return daysOfMonth.isEmpty ? "No days set" : "Every \(daysOfMonthString) of month"
        case .nDaysEachMonth:
            let days = Int(frequencyDetail)
            guard let days else { return "No days set" }
            if days == 1 {
                return "1 day each month"
            } else {
                return "\(days) days each month"
            }
        }
    }

    var daysOfWeek: Set<Int> {
        guard case .fixedDaysInWeek = frequency else {
            return []
        }
        return Set(frequencyDetail.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
    }
    
    var daysOfWeekString: String {
        daysOfWeek.map { "\($0)" }.sorted().joined(separator: ", ")
    }

    var daysOfMonth: Set<Int> {
        guard case .fixedDaysInMonth = frequency else {
            return []
        }
        return Set(frequencyDetail.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
    }
    
    var daysOfMonthString: String {
        daysOfMonth.map { "\($0)" }.sorted().joined(separator: ", ")
    }

    var nDaysPerWeek: Int {
        guard case .nDaysEachWeek = frequency else {
            return 0
        }
        return Int(frequencyDetail.replacingOccurrences(of: " ", with: "")) ?? 0
    }

    var nDaysPerMonth: Int {
        guard case .nDaysEachMonth = frequency else {
            return 0
        }
        return Int(frequencyDetail.replacingOccurrences(of: " ", with: "")) ?? 0
    }

    func toTodayHabit(
        isCompleted: Bool = true,
        streakDescription: String? = nil,
        frequencyDescription: String? = nil
    ) -> TodayHabit {
        TodayHabit(
            habit: self,
            isCompleted: isCompleted,
            streakDescription: streakDescription,
            frequencyDescription: frequencyDescription
        )
    }

    var newHabitDraft: Habit.Draft {
        Habit.Draft(
            self
        )
    }
}

extension Habit.Draft {
    var borderColor: Color {
        Color(hex: color).blend(with: .black, amount: 0.2)
    }

    var daysOfWeek: Set<Int> {
        guard case .fixedDaysInWeek = frequency else {
            return []
        }
        return Set(frequencyDetail.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
    }

    var daysOfMonth: Set<Int> {
        guard case .fixedDaysInMonth = frequency else {
            return []
        }
        return Set(frequencyDetail.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
    }

    var nDaysPerWeek: Int {
        guard case .nDaysEachWeek = frequency else {
            return 1
        }
        return Int(frequencyDetail.replacingOccurrences(of: " ", with: "")) ?? 1
    }

    var nDaysPerMonth: Int {
        guard case .nDaysEachMonth = frequency else {
            return 1
        }
        return Int(frequencyDetail.replacingOccurrences(of: " ", with: "")) ?? 1
    }
    
    var toMock: Habit {
        Habit(
            id: 0,
            name: name,
            category: category,
            frequency: frequency,
            frequencyDetail: frequencyDetail,
            antiAgingRating: antiAgingRating,
            icon: icon,
            color: color,
            note: note,
            isFavorite: isFavorite,
            isArchived: isArchived
        )
    }
    
    func toTodayDraftHabit(
        isCompleted: Bool = true,
        streakDescription: String? = nil,
        frequencyDescription: String? = nil
    ) -> TodayDraftHabit {
        TodayDraftHabit(
            habit: self,
            isCompleted: isCompleted,
            streakDescription: streakDescription,
            frequencyDescription: frequencyDescription
        )
    }
}

extension Habit.Draft: Hashable {
    
}
