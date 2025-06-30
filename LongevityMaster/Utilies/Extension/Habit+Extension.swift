//
// Created by Banghua Zhao on 08/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

extension Habit {
    var borderColor: Color {
        Color(hex: color).blend(with: .black, amount: 0.2)
    }

    var frequencyDescription: String {
        switch frequency {
        case .fixedDaysInWeek:
            return daysOfWeek.isEmpty ? "No days set" : "Every \(daysOfWeek)"
        case .nDaysEachWeek:
            let days = Int(frequencyDetail)
            guard let days else { return "No days set" }
            if days == 1 {
                return "1 day each week"
            } else {
                return "\(days) days each week"
            }
        case .fixedDaysInMonth:
            return daysOfMonth.isEmpty ? "No days set" : "Every \(daysOfMonth) of month"
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

    var daysOfMonth: Set<Int> {
        guard case .fixedDaysInMonth = frequency else {
            return []
        }
        return Set(frequencyDetail.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
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
        id: Int = 0,
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
            name: name,
            category: category,
            frequency: frequency,
            frequencyDetail: frequencyDetail,
            antiAgingRating: antiAgingRating,
            icon: icon,
            color: color,
            note: note
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
    
    func toHabit(id: Int = 0) -> Habit {
        Habit(
            id: id,
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

    func toTodayHabit(
        id: Int = 0,
        isCompleted: Bool = true,
        streakDescription: String? = nil,
        frequencyDescription: String? = nil
    ) -> TodayHabit {
        TodayHabit(
            habit: toHabit(id: id),
            isCompleted: isCompleted,
            streakDescription: streakDescription,
            frequencyDescription: frequencyDescription
        )
    }
}
