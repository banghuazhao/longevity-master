//
// Created by Banghua Zhao on 01/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//


/// An enumeration representing the frequency settings of a habit with associated values.
enum HabitFrequency: Codable {
    /// Habit scheduled on specific days of the week (1 = Mon, ..., 7 = Sun).
    case fixedDaysInWeek(Set<Int>)
    
    /// Habit scheduled for a fixed number of days each week.
    case nDaysEachWeek(Int)
    
    /// Habit scheduled on specific days of the month (1-28).
    case fixedDaysInMonth(Set<Int>)
    
    /// Habit scheduled for a fixed number of days each month.
    case nDaysEachMonth(Int)
    
    /// All possible frequency types with default associated values.
    static var allCases: [HabitFrequency] = [
        .fixedDaysInWeek(Set(1...7)),
        .nDaysEachWeek(1),
        .fixedDaysInMonth(Set(1...28)),
        .nDaysEachMonth(1)
    ]
    
    /// The human-readable title for the frequency type.
    var title: String {
        switch self {
        case .fixedDaysInWeek: return "Fixed Days in a Week"
        case .nDaysEachWeek: return "N Days Each Week"
        case .fixedDaysInMonth: return "Fixed Days in a Month"
        case .nDaysEachMonth: return "N Days Each Month"
        }
    }
    
    /// The maximum number of days allowed for this frequency type.
    var maxDays: Int {
        switch self {
        case .fixedDaysInWeek, .nDaysEachWeek: return 7
        case .fixedDaysInMonth, .nDaysEachMonth: return 28
        }
    }
    
    /// Serializes the frequency type and its associated value into a string.
    var rawValue: String {
        switch self {
        case .fixedDaysInWeek(let days):
            return "fixedDaysInWeek,\(days.sorted().map { String($0) }.joined(separator: ","))"
        case .nDaysEachWeek(let days):
            return "nDaysEachWeek,\(days)"
        case .fixedDaysInMonth(let days):
            return "fixedDaysInMonth,\(days.sorted().map { String($0) }.joined(separator: ","))"
        case .nDaysEachMonth(let days):
            return "nDaysEachMonth,\(days)"
        }
    }
    
    /// Initializes a frequency type from a raw string value.
    ///
    /// - Parameter rawValue: A string in the format "type,details" (e.g., "fixedDaysInWeek,1,3,5").
    /// - Returns: A `HabitFrequency` instance if the raw value is valid, otherwise `nil`.
    init?(rawValue: String) {
        let components = rawValue.split(separator: ",", maxSplits: 1)
        guard components.count == 2 else { return nil }
        let type = String(components[0])
        let details = String(components[1])
        
        switch type {
        case "fixedDaysInWeek":
            let days = Set(details.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
            self = .fixedDaysInWeek(days.filter { $0 >= 1 && $0 <= 7 })
        case "nDaysEachWeek":
            self = .nDaysEachWeek(Int(details) ?? 1)
        case "fixedDaysInMonth":
            let days = Set(details.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
            self = .fixedDaysInMonth(days.filter { $0 >= 1 && $0 <= 28 })
        case "nDaysEachMonth":
            self = .nDaysEachMonth(Int(details) ?? 1)
        default:
            return nil
        }
    }
}
