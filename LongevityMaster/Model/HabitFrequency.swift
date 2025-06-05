//
// Created by Banghua Zhao on 01/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//


import SharingGRDB

enum HabitFrequency: Int, QueryBindable {
    case fixedDaysInWeek
    case nDaysEachWeek
    case fixedDaysInMonth
    case nDaysEachMonth
    
    static var allCases: [HabitFrequency] = [
        .fixedDaysInWeek,
        .nDaysEachWeek,
        .fixedDaysInMonth,
        .nDaysEachMonth
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
    
    /// Serializes the frequency type and its associated value into a string.
//    var rawValue: String {
//        switch self {
//        case .fixedDaysInWeek(let days):
//            return "fixedDaysInWeek,\(days.sorted().map { String($0) }.joined(separator: ","))"
//        case .nDaysEachWeek(let days):
//            return "nDaysEachWeek,\(days)"
//        case .fixedDaysInMonth(let days):
//            return "fixedDaysInMonth,\(days.sorted().map { String($0) }.joined(separator: ","))"
//        case .nDaysEachMonth(let days):
//            return "nDaysEachMonth,\(days)"
//        }
//    }
    
    /// Initializes a frequency type from a raw string value.
    ///
    /// - Parameter rawValue: A string in the format "type,details" (e.g., "fixedDaysInWeek,1,3,5").
    /// - Returns: A `HabitFrequency` instance if the raw value is valid, otherwise `nil`.
//    init?(rawValue: String) {
//        let components = rawValue.split(separator: ",", maxSplits: 1)
//        guard components.count == 2 else { return nil }
//        let type = String(components[0])
//        let details = String(components[1])
//        
//        switch type {
//        case "fixedDaysInWeek":
//            let days = Set(details.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
//            self = .fixedDaysInWeek(days.filter { $0 >= 1 && $0 <= 7 })
//        case "nDaysEachWeek":
//            self = .nDaysEachWeek(Int(details) ?? 1)
//        case "fixedDaysInMonth":
//            let days = Set(details.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
//            self = .fixedDaysInMonth(days.filter { $0 >= 1 && $0 <= 28 })
//        case "nDaysEachMonth":
//            self = .nDaysEachMonth(Int(details) ?? 1)
//        default:
//            return nil
//        }
//    }
}
