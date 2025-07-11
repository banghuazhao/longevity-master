//
// Created by Banghua Zhao on 05/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SharingGRDB
import Foundation

@Table
struct CheckIn {
    let id: Int
    @Column(as: Date.self)
    var date: Date
    var habitID: Habit.ID
}

@Selection
struct CheckInHistory {
    let checkIn: CheckIn
    let habitName: String
    let habitIcon: String
}
