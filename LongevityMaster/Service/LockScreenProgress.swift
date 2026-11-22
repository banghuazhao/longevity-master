//
// Created by Banghua Zhao on 22/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import UIKit
#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
#endif

/// Today's progress as a Live Activity on the Lock Screen and in the Dynamic Island, while the
/// setting for it is on.
///
/// The app is the only thing that can start or change the activity, so it is brought up to
/// date whenever the app changes today's list (through `WidgetRefresher.reload()`) and when it
/// comes to the foreground — which also starts a fresh one on a new day, and replaces one the
/// system ended after its eight hours.
enum LockScreenProgress {
    static let isEnabledKey = "showsLockScreenProgress"

    /// iPhone only: the Mac has no Live Activities, and iPads do not show them.
    static var isSupported: Bool {
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
            return UIDevice.current.userInterfaceIdiom == .phone
        #else
            return false
        #endif
    }

    /// Whether Live Activities are allowed for the app in the system Settings.
    static var isAllowedBySystem: Bool {
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
            return ActivityAuthorizationInfo().areActivitiesEnabled
        #else
            return false
        #endif
    }

    /// Updates run one after another: two started together would both find no activity and
    /// both request one.
    @MainActor private static var queue: Task<Void, Never>?

    @MainActor
    static func refresh() {
        guard isSupported else { return }
        let isEnabled = UserDefaults.standard.bool(forKey: isEnabledKey)
        let previous = queue
        queue = Task {
            await previous?.value
            await update(isEnabled: isEnabled)
        }
    }

    #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        private static func update(isEnabled: Bool) async {
            let activities = Activity<TodayActivityAttributes>.activities
            guard isEnabled, isAllowedBySystem else {
                for activity in activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
                return
            }

            let calendar = Calendar.userPreferred(startWeekOnMonday: AppGroup.startWeekOnMonday)
            let now = Date()
            let today = calendar.startOfDay(for: now)
            guard let scheduled = try? WidgetDatabase.habitsDue(on: now) else { return }

            let state = TodayActivityAttributes.ContentState(
                done: scheduled.count(where: \.isCompleted),
                total: scheduled.count,
                nextHabit: scheduled.first { !$0.isCompleted }.map { "\($0.habit.icon) \($0.habit.name)" }
            )
            // Past midnight it is yesterday's news, and the system dims it.
            let content = ActivityContent(
                state: state,
                staleDate: calendar.date(byAdding: .day, value: 1, to: today)
            )
            let accent = AppGroup.accentColorHex

            // Keep today's activity if there is one in the current colour; end anything else.
            var current: Activity<TodayActivityAttributes>?
            for activity in activities {
                let isToday = calendar.isDate(activity.attributes.day, inSameDayAs: today)
                if current == nil, isToday, activity.attributes.accentColorHex == accent,
                   activity.activityState == .active {
                    current = activity
                } else {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }

            if let current {
                await current.update(content)
            } else {
                do {
                    _ = try Activity.request(
                        attributes: TodayActivityAttributes(day: today, accentColorHex: accent),
                        content: content
                    )
                } catch {
                    // Only possible from the foreground; the next trip there tries again.
                    debugLog("Live Activity not started: \(error)")
                }
            }
        }
    #else
        private static func update(isEnabled: Bool) async {}
    #endif
}
