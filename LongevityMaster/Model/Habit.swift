//
// Created by Banghua Zhao on 01/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SharingGRDB

@Table
struct Habit: Identifiable {
    let id: Int
    var name: String
    var category: HabitCategory
    var frequency: HabitFrequency
    var frequencyDetail: String
    var antiAgingRating: Int
    var icon: String
    var color: String
    var note: String = ""
}
