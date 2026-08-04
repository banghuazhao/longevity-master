//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AppIntents
import WidgetKit

/// Backs the tap target on each habit in the widget. Running in the widget's own process, it
/// writes straight to the shared database; WidgetKit re-renders the timeline when it returns.
struct ToggleHabitCheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "Check In Habit"
    static var description = IntentDescription("Check a habit in or out for today.")

    /// Keeps the widget responsive: WidgetKit renders the new state without relaunching the app.
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Habit")
    var habitID: Int

    init() {}

    init(habitID: Habit.ID) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        try WidgetDatabase.toggleCheckIn(habitID: habitID, on: Date())
        return .result()
    }
}
