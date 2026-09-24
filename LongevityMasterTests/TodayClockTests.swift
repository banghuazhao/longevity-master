//
// Created by Banghua Zhao on 24/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

/// iOS keeps the app in memory overnight, so the Today screen has to notice the day change
/// itself — or the next morning's first check-in lands on yesterday.
@Suite("Today keeps up with the clock")
@MainActor
struct TodayClockTests {
    private let calendar = testCalendar()

    private func caughtUp(selected: String, lastSeen: String, now: String) -> Date {
        TodayViewModel.selectedDate(
            afterClockMovesFrom: testDate(lastSeen),
            to: testDate(now),
            selected: testDate(selected),
            calendar: calendar
        )
    }

    @Test("Someone looking at today is moved onto the new day")
    func todayFollowsTheClock() {
        let result = caughtUp(selected: "2026-09-23 21:00", lastSeen: "2026-09-23 22:00", now: "2026-09-24 07:30")
        #expect(calendar.isDate(result, inSameDayAs: testDate("2026-09-24")))
    }

    @Test("Someone filling in an earlier day is left on it")
    func anEarlierDayStaysPut() {
        let result = caughtUp(selected: "2026-09-20 12:00", lastSeen: "2026-09-23 22:00", now: "2026-09-24 07:30")
        #expect(result == testDate("2026-09-20 12:00"))
    }

    @Test("Coming back later the same day changes nothing")
    func sameDayIsLeftAlone() {
        let result = caughtUp(selected: "2026-09-24 08:00", lastSeen: "2026-09-24 08:00", now: "2026-09-24 18:00")
        #expect(result == testDate("2026-09-24 08:00"))
    }

    @Test("A day in the future is brought back to today")
    func theFutureIsClamped() {
        let result = caughtUp(selected: "2026-09-26 08:00", lastSeen: "2026-09-24 08:00", now: "2026-09-24 09:00")
        #expect(result == testDate("2026-09-24 09:00"))
    }
}

@Suite("When the app-open ad may show")
struct AppOpenAdPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let hour: TimeInterval = 60 * 60
    private let day: TimeInterval = 24 * 60 * 60

    @Test("A long-time user who has not seen one recently gets the ad")
    func allowedByDefault() {
        #expect(AppOpenAdPolicy.allows(now: now, lastShown: nil, onboardingCompletedAt: nil, skipUntil: nil))
    }

    @Test("No ads on someone's first day")
    func newUsersAreSpared() {
        #expect(!AppOpenAdPolicy.allows(now: now, lastShown: nil, onboardingCompletedAt: now - 12 * hour, skipUntil: nil))
        #expect(AppOpenAdPolicy.allows(now: now, lastShown: nil, onboardingCompletedAt: now - 2 * day, skipUntil: nil))
    }

    @Test("At most one an hour")
    func minimumGap() {
        #expect(!AppOpenAdPolicy.allows(now: now, lastShown: now - 0.5 * hour, onboardingCompletedAt: nil, skipUntil: nil))
        #expect(AppOpenAdPolicy.allows(now: now, lastShown: now - 2 * hour, onboardingCompletedAt: nil, skipUntil: nil))
    }

    @Test("Coming back from sharing, a link or a reminder: no ad, once")
    func deliberateTripsAreSkippedOnce() {
        let defaults = UserDefaults(suiteName: "AppOpenAdPolicyTests")!
        defaults.removePersistentDomain(forName: "AppOpenAdPolicyTests")

        AppOpenAdPolicy.skipNextReturn(now: now, defaults: defaults)
        #expect(!AppOpenAdPolicy.shouldPresent(now: now + 60, defaults: defaults))
        // Used up by that return.
        #expect(AppOpenAdPolicy.shouldPresent(now: now + 120, defaults: defaults))
    }
}
