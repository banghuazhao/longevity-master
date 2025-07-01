//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SharingGRDB

@Table
struct Reminder: Identifiable {
    let id: Int
    var title: String = "Log Longevity Master"
    var body: String = "Time to check in on your habit!"
    var time: Date = Date()
    var habitID: Habit.ID?
    var notificationID: String = "reminder_\(UUID().uuidString)"
}

extension Reminder.Draft: Identifiable {}
