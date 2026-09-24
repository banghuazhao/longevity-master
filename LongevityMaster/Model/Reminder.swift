//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

@Table
struct Reminder: Identifiable {
    let id: Int
    var title: String = Reminder.storedDefaultTitle
    var body: String = Reminder.storedDefaultBody
    var time: Date = Date()
    var habitID: Habit.ID?
    var notificationID: String = "reminder_\(UUID().uuidString)"
}

extension Reminder.Draft: Identifiable {}

extension Reminder {
    /// What every reminder is stored with until something more specific is written. These are
    /// English whatever language the app runs in, so they are never shown as they are.
    static let storedDefaultTitle = "Log Longevity Master"
    static let storedDefaultBody = "Time to check in on your habit!"

    /// A habit's reminder is titled with the habit itself; the general one gets its title here,
    /// in the current language.
    var displayTitle: String {
        title == Self.storedDefaultTitle ? String(localized: "Time to check in") : title
    }

    var displayBody: String {
        guard body == Self.storedDefaultBody else { return body }
        return habitID == nil
            ? String(localized: "See what's still on today's list.")
            : String(localized: "Time to check in on your habit!")
    }
}
