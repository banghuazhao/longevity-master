//
// Created by Banghua Zhao on 01/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SharingGRDB

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
        case .diet: return "Diet"
        case .exercise: return "Exercise"
        case .sleep: return "Sleep"
        case .preventiveHealth: return "Health"
        case .mentalHealth: return "Mental"
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
