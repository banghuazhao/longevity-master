//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import WidgetKit

struct TodayHabitsEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabit]
    /// Distinguishes "nothing scheduled today" from "the app has never run", which need
    /// different things said to the user.
    let isDataAvailable: Bool

    var completedCount: Int { habits.filter(\.isCompleted).count }

    static let unavailable = TodayHabitsEntry(date: Date(), habits: [], isDataAvailable: false)
}

struct WidgetHabit: Identifiable, Hashable {
    let id: Int
    let name: String
    let icon: String
    let colorHex: Int
    let isCompleted: Bool
    /// "2/5 this week" for quota habits; nil for habits fixed to particular days.
    let detail: String?
}

struct TodayHabitsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayHabitsEntry {
        TodayHabitsEntry(date: Date(), habits: WidgetHabit.samples, isDataAvailable: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayHabitsEntry) -> Void) {
        // The gallery preview runs before the user has picked anything, and reading a real
        // database there would show an empty box to anyone browsing widgets.
        if context.isPreview {
            completion(TodayHabitsEntry(date: Date(), habits: WidgetHabit.samples, isDataAvailable: true))
        } else {
            completion(currentEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayHabitsEntry>) -> Void) {
        // Today's list is only valid until midnight; the app reloads the timeline itself
        // whenever habits or check-ins change, so this is just the backstop.
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(24 * 60 * 60))
        completion(Timeline(entries: [currentEntry()], policy: .after(midnight)))
    }

    private func currentEntry() -> TodayHabitsEntry {
        do {
            let scheduled = try WidgetDatabase.habitsDue(on: Date())
            return TodayHabitsEntry(
                date: Date(),
                habits: scheduled.map { scheduled in
                    WidgetHabit(
                        id: scheduled.habit.id,
                        name: scheduled.habit.name,
                        icon: scheduled.habit.icon,
                        colorHex: scheduled.habit.color,
                        isCompleted: scheduled.isCompleted,
                        detail: scheduled.frequencyDescription
                    )
                },
                isDataAvailable: true
            )
        } catch {
            return .unavailable
        }
    }
}

extension WidgetHabit {
    /// Only ever shown in the widget gallery and in Xcode previews.
    static let samples: [WidgetHabit] = [
        WidgetHabit(id: -1, name: String(localized: "Eat berries"), icon: "🍓", colorHex: 0xA084E899, isCompleted: true, detail: String(localized: "2/5 this week")),
        WidgetHabit(id: -2, name: String(localized: "Brisk walking"), icon: "🚶", colorHex: 0xBFD8B899, isCompleted: false, detail: String(localized: "1/5 this week")),
        WidgetHabit(id: -3, name: String(localized: "Meditate"), icon: "🧘‍♀️", colorHex: 0x4DD0AE99, isCompleted: false, detail: nil),
        WidgetHabit(id: -4, name: String(localized: "Sleep 7–9 hours"), icon: "😴", colorHex: 0xFFD18C99, isCompleted: false, detail: nil),
    ]
}
