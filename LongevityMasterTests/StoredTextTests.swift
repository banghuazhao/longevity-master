//
// Created by Banghua Zhao on 24/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

/// Text written to the database is frozen in the language it was written in. These check that
/// what the user sees is looked up afresh instead.
@Suite("Stored text is shown in the current language")
struct StoredTextTests {
    @Test("Each achievement definition is identified by its type and criteria alone")
    func definitionsAreUniquelyKeyed() {
        for definition in AchievementDefinitions.all {
            let found = AchievementDefinitions.definition(type: definition.type, criteria: definition.criteria)
            #expect(found?.title == definition.title, "\(definition.title)")
        }
    }

    @Test("An achievement stored in another language shows in the current one")
    func achievementTextIsLookedUp() throws {
        let definition = try #require(AchievementDefinitions.all.first)
        let stored = Achievement(
            id: 1,
            title: "第一步",
            description: "连续 3 天完成一个习惯",
            icon: definition.icon,
            type: definition.type,
            criteria: definition.criteria,
            isUnlocked: true,
            unlockedDate: nil,
            habitID: nil
        )
        #expect(stored.localizedTitle == definition.title)
        #expect(stored.localizedDescription == definition.description)
    }

    @Test("The stored English reminder defaults are never sent as they are")
    func reminderDefaultsAreTranslated() {
        let general = Reminder(id: 1, time: Date(), habitID: nil)
        #expect(general.displayTitle == String(localized: "Time to check in"))
        #expect(general.displayBody == String(localized: "See what's still on today's list."))

        let habitReminder = Reminder(id: 2, title: "🦵 Squats", time: Date(), habitID: 7)
        #expect(habitReminder.displayTitle == "🦵 Squats")
        #expect(habitReminder.displayBody == String(localized: "Time to check in on your habit!"))
    }
}
