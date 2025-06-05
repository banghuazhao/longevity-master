//
// Created by Banghua Zhao on 01/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB

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
}
