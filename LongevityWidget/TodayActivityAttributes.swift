//
// Created by Banghua Zhao on 22/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

// Compiled into the app, which starts and updates the activity, and into the widget
// extension, which draws it. The Mac has no Live Activities.
#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
import Foundation

/// Today's progress on the Lock Screen and in the Dynamic Island.
struct TodayActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var done: Int
        var total: Int
        /// The next habit still to do, as "🧘 Meditate"; nil once everything is done.
        var nextHabit: String?

        var fraction: Double {
            total > 0 ? Double(done) / Double(total) : 0
        }

        var isAllDone: Bool {
            total > 0 && done >= total
        }
    }

    /// The day the activity is about. A new day gets a new activity.
    var day: Date
    /// The user's theme colour, packed as 0xRRGGBBAA.
    var accentColorHex: Int
}
#endif
