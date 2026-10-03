//
// Created by Banghua Zhao on 03/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AppIntents
import Foundation

// Compiled into both the app and the widget extension: Siri and Shortcuts look habits up in
// the app's process, and Control Center in the extension's. The intents that use it are not
// shared — an intent the extension also declares gets routed to the extension, which has no
// App Shortcuts and fails.

/// A habit, as Siri, Shortcuts and Control Center refer to one.
struct HabitEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    static var defaultQuery = HabitEntityQuery()

    let id: Habit.ID
    let name: String
    let icon: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(icon) \(name)")
    }

    init(_ habit: Habit) {
        id = habit.id
        name = habit.name
        icon = habit.icon
    }
}

struct HabitEntityQuery: EntityStringQuery {
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        try WidgetDatabase.habits(ids: identifiers).map(HabitEntity.init)
    }

    /// Before the app has ever run there is no database, and so nothing to suggest.
    func suggestedEntities() async throws -> [HabitEntity] {
        ((try? WidgetDatabase.activeHabits()) ?? []).map(HabitEntity.init)
    }

    func entities(matching string: String) async throws -> [HabitEntity] {
        ((try? WidgetDatabase.activeHabits()) ?? [])
            .filter { $0.name.localizedCaseInsensitiveContains(string) }
            .map(HabitEntity.init)
    }
}
