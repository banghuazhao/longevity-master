//
// Created by Banghua Zhao on 18/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

@Suite("Habit calendar")
struct HabitCalendarTests {
    let calendar = testCalendar()
    let now = testDate("2026-10-17 12:00")

    @Test("Today and any day before it can be checked in")
    @MainActor
    func pastAndToday() {
        #expect(HabitDetailViewModel.canCheckIn(on: testDate("2026-10-17 23:59"), now: now, calendar: calendar))
        #expect(HabitDetailViewModel.canCheckIn(on: testDate("2026-10-17 00:00"), now: now, calendar: calendar))
        #expect(HabitDetailViewModel.canCheckIn(on: testDate("2026-09-01 08:00"), now: now, calendar: calendar))
    }

    @Test("A day that has not begun cannot be checked in")
    @MainActor
    func future() {
        #expect(!HabitDetailViewModel.canCheckIn(on: testDate("2026-10-18 00:00"), now: now, calendar: calendar))
        #expect(!HabitDetailViewModel.canCheckIn(on: testDate("2026-10-25 12:00"), now: now, calendar: calendar))
    }
}
