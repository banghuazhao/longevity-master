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
