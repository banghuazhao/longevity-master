//
// Created by Banghua Zhao on 03/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AppIntents
import SwiftUI
import WidgetKit

/// A Control Center, Lock Screen or Action button toggle for one habit the user picks when
/// adding it. On means checked in today.
@available(iOS 18.0, *)
struct HabitCheckInControl: ControlWidget {
    static let kind = "HabitCheckInControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: Self.kind, provider: Provider()) { value in
            ControlWidgetToggle(isOn: value.isDone, action: SetHabitCheckInIntent(habit: value.habit)) {
                if let habit = value.habit {
                    Text(verbatim: "\(habit.icon) \(habit.name)")
                } else {
                    Text("Choose a Habit")
                }
            } valueLabel: { isOn in
                Label(isOn ? "Done" : "Not Yet", systemImage: isOn ? "checkmark.circle.fill" : "circle")
            }
            .tint(WidgetTheme.accent)
        }
        .displayName("Check In Habit")
        .description("Check a habit in or out without opening the app.")
        .promptsForUserConfiguration()
    }

    struct Value {
        let habit: HabitEntity?
        let isDone: Bool
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: SelectHabitIntent) -> Value {
            Value(habit: configuration.habit, isDone: false)
        }

        func currentValue(configuration: SelectHabitIntent) async throws -> Value {
            guard let habit = configuration.habit else {
                return Value(habit: nil, isDone: false)
            }
            let isDone = (try? WidgetDatabase.isCheckedIn(habitID: habit.id, on: Date())) ?? false
            return Value(habit: habit, isDone: isDone)
        }
    }
}

/// Which habit a control is for, chosen when the control is added.
@available(iOS 18.0, *)
struct SelectHabitIntent: ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Choose Habit"

    @Parameter(title: "Habit")
    var habit: HabitEntity?

    init() {}
}

/// What flipping the control does. The system passes the new state as `value`.
@available(iOS 18.0, *)
struct SetHabitCheckInIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Set Habit Check-In"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Habit")
    var habit: HabitEntity?

    @Parameter(title: "Checked In")
    var value: Bool

    init() {}

    init(habit: HabitEntity?) {
        self.habit = habit
    }

    func perform() async throws -> some IntentResult {
        guard let habit else { return .result() }
        try WidgetDatabase.setCheckIn(habitID: habit.id, on: Date(), done: value)
        return .result()
    }
}
