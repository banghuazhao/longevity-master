//
// Created by Banghua Zhao on 03/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Observation

/// Screens opened from outside the view hierarchy — today, a tapped notification. The tap
/// arrives at the notification delegate, which has no view to present from, so it leaves the
/// destination here and `RootView` presents it.
@Observable
@MainActor
final class AppRouter {
    static let shared = AppRouter()

    enum Destination: Identifiable, Hashable {
        /// The week containing this date.
        case weeklyReview(weekOf: Date)
        case programCompletion(enrollmentID: ProgramEnrollment.ID)
        /// What the latest release added, shown once after updating.
        case whatsNew

        var id: Self { self }
    }

    var presented: Destination?

    /// A tab something outside the views wants shown, such as a Home Screen quick action.
    /// `RootView` switches to it and clears it.
    var requestedTab: AppTab?

    /// Set by the "New Habit" quick action; the Habits tab opens its form and clears it.
    var wantsNewHabit = false

    private init() {}

    /// Keys a notification's `userInfo` uses to say where its tap should lead.
    enum NotificationKey {
        static let destination = "destination"
        static let enrollmentID = "enrollmentID"
        static let weeklyReview = "weeklyReview"
        static let programCompletion = "programCompletion"
    }

    /// Where a notification's tap leads, if anywhere. Reminders lead nowhere in particular:
    /// opening the app on Today is already the right place for them.
    nonisolated static func destination(userInfo: [AnyHashable: Any], deliveredAt date: Date) -> Destination? {
        switch userInfo[NotificationKey.destination] as? String {
        case NotificationKey.weeklyReview:
            return .weeklyReview(weekOf: date)
        case NotificationKey.programCompletion:
            guard let id = userInfo[NotificationKey.enrollmentID] as? Int else { return nil }
            return .programCompletion(enrollmentID: id)
        default:
            return nil
        }
    }
}
