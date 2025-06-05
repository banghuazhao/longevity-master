//
// Created by Banghua Zhao on 05/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SharingGRDB
import Foundation

@Table
struct CheckInDate {
    let id: Int
    @Column(as: Date.self)
    var date: Date
    var habitID: Habit.ID
}

