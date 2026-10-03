//
// Created by Banghua Zhao on 03/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AppIntents
import Foundation

/// What Siri and Spotlight offer without the user setting anything up. Phrases are translated
/// in `AppShortcuts.xcstrings`, and every one has to name the app.
struct LongevityShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckInHabitIntent(),
            phrases: [
                "Check in \(\.$habit) in \(.applicationName)",
                "Log \(\.$habit) in \(.applicationName)",
                "Check in a habit in \(.applicationName)",
            ],
            shortTitle: "Check In Habit",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: TodayProgressIntent(),
            phrases: [
                "How am I doing in \(.applicationName)",
                "Show today's progress in \(.applicationName)",
            ],
            shortTitle: "Today's Progress",
            systemImageName: "chart.bar.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor = .orange
}

/// "Check in Meditate in Longevity Master." Only ever checks in — saying it twice must not
/// undo the first time, the way a second tap on the widget does.
struct CheckInHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Check In a Habit"
    static var description = IntentDescription("Mark one of your habits as done for today.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Habit", requestValueDialog: IntentDialog("Which habit did you do?"))
    var habit: HabitEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Check in \(\.$habit)")
    }

    init() {}

    init(habit: HabitEntity) {
        self.habit = habit
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let now = Date()
        let changed = try WidgetDatabase.setCheckIn(habitID: habit.id, on: now, done: true)
        guard changed else {
            return .result(dialog: "\(habit.name) is already checked in for today.")
        }

        let today = (try? WidgetDatabase.habitsDue(on: now)) ?? []
        let done = today.filter(\.isCompleted).count
        if !today.isEmpty, done == today.count {
            return .result(dialog: "Checked in \(habit.name). That's everything for today. Well done!")
        }
        return .result(dialog: "Checked in \(habit.name). \(done) of \(today.count) done today.")
    }
}

/// "How am I doing in Longevity Master?" — today's count, and what is still to do.
struct TodayProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Today's Habit Progress"
    static var description = IntentDescription("Hear how many of today's habits are done, and which are left.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let today = try WidgetDatabase.habitsDue(on: Date())
        let done = today.filter(\.isCompleted).count

        if today.isEmpty {
            return .result(dialog: "Nothing is scheduled for today.")
        }
        if done == today.count {
            return .result(dialog: "All \(today.count) of today's habits are done. Great work!")
        }
        let remaining = today
            .filter { !$0.isCompleted }
            .map(\.habit.name)
            .formatted(.list(type: .and))
        return .result(dialog: "\(done) of \(today.count) done. Still to go: \(remaining).")
    }
}
