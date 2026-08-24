//
// Created by Banghua Zhao on 25/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
@testable import LongevityMaster

/// A calendar pinned to UTC so a test means the same thing wherever it runs. `Calendar.current`
/// carries the machine's time zone, which quietly moves every date boundary these tests are
/// about.
func testCalendar(startWeekOnMonday: Bool = true) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.firstWeekday = startWeekOnMonday ? 2 : 1
    return calendar
}

/// `"2026-08-25"` or `"2026-08-25 07:30"`, read in `calendar`'s time zone.
func testDate(_ string: String, _ calendar: Calendar = testCalendar()) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = string.count > 10 ? "yyyy-MM-dd HH:mm" : "yyyy-MM-dd"
    guard let date = formatter.date(from: string) else {
        fatalError("not a date this test can use: \(string)")
    }
    return date
}

func testDays(_ strings: [String], _ calendar: Calendar = testCalendar()) -> Set<Date> {
    Set(strings.map { calendar.startOfDay(for: testDate($0, calendar)) })
}

// MARK: - Database

import Dependencies
import SQLiteData

/// Runs `body` against a fresh in-memory database built by the app's own `appDatabase()`, so
/// tests exercise the real schema rather than a copy of it that can drift.
///
/// The DEBUG seed leaves the habit gallery behind; it is cleared first so a test only ever
/// sees what it put there. Achievement definitions are left in place — they are what the
/// achievement tests are about.
func withTestDatabase(_ body: (any DatabaseWriter) async throws -> Void) async throws {
    try await withDependencies {
        $0.defaultDatabase = try appDatabase()
    } operation: {
        @Dependency(\.defaultDatabase) var database
        try await database.write { db in
            try Habit.all.delete().execute(db)
        }
        try await body(database)
    }
}

func testHabitDraft(
    name: String,
    antiAgingRating: Int = 3,
    frequency: HabitFrequency = .fixedDaysInWeek,
    frequencyDetail: String = "1,2,3,4,5,6,7",
    category: HabitCategory = .diet,
    isArchived: Bool = false
) -> Habit.Draft {
    var draft = Habit.Draft()
    draft.name = name
    draft.antiAgingRating = antiAgingRating
    draft.frequency = frequency
    draft.frequencyDetail = frequencyDetail
    draft.category = category
    draft.isArchived = isArchived
    return draft
}

extension RatingService {
    /// `@FetchAll` catches up with the database asynchronously. Tests need the values to be
    /// current at a known moment, so they ask outright.
    func reload() async throws {
        try await $allHabits.load()
        try await $allAchievements.load()
        try await $allCheckIns.load()
    }
}

/// A date `daysAgo` days before today at `hour` o'clock, built in the device's own calendar —
/// the one `AchievementService` and `RatingService` work in. Tests that go through those have
/// to speak the same time zone or every day boundary lands somewhere else.
func localDate(daysAgo: Int, hour: Int = 12) -> Date {
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: Date())
    let day = calendar.date(byAdding: .day, value: -daysAgo, to: startOfToday)!
    return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
}

extension Achievement {
    static func named(_ title: String, in achievements: [Achievement]) -> Achievement? {
        achievements.first { $0.title == String(localized: String.LocalizationValue(title)) }
    }
}
