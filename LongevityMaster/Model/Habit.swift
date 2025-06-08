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
    var antiAgingRating: Int = 3
    var icon: String = "🥑"
    var color: Int = 0xffffff
    var note: String = ""
}
