//
// Created by Banghua Zhao on 20/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

@Suite("What's New")
@MainActor
struct WhatsNewTests {
    private func defaults() -> UserDefaults {
        let name = "WhatsNewTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("Shown once to someone updating, and not again for the same release")
    func updatingUser() {
        #expect(WhatsNew.shouldShow(lastSeen: nil, hasCompletedOnboarding: true))
        #expect(WhatsNew.shouldShow(lastSeen: "1.8", hasCompletedOnboarding: true))
        #expect(!WhatsNew.shouldShow(lastSeen: WhatsNew.release, hasCompletedOnboarding: true))
    }

    @Test("A new install starts out having seen it")
    func newInstall() {
        let defaults = defaults()
        WhatsNew.presentIfDue(defaults: defaults)
        #expect(defaults.string(forKey: WhatsNew.lastSeenKey) == WhatsNew.release)
        #expect(AppRouter.shared.presented == nil)
    }

    @Test("It waits for another launch when something else is already on screen")
    func waitsItsTurn() {
        let defaults = defaults()
        defaults.set(true, forKey: "hasCompletedOnboarding")
        let router = AppRouter.shared
        router.presented = .weeklyReview(weekOf: Date(timeIntervalSince1970: 0))
        defer { router.presented = nil }

        WhatsNew.presentIfDue(defaults: defaults)
        #expect(defaults.string(forKey: WhatsNew.lastSeenKey) == nil)
        #expect(router.presented == .weeklyReview(weekOf: Date(timeIntervalSince1970: 0)))
    }

    @Test("Someone updating sees it, and it is marked seen")
    func presents() {
        let defaults = defaults()
        defaults.set(true, forKey: "hasCompletedOnboarding")
        defaults.set("1.8", forKey: WhatsNew.lastSeenKey)
        let router = AppRouter.shared
        defer { router.presented = nil }

        WhatsNew.presentIfDue(defaults: defaults)
        #expect(router.presented == .whatsNew)
        #expect(defaults.string(forKey: WhatsNew.lastSeenKey) == WhatsNew.release)
    }
}

@Suite("When to ask for a rating")
struct RatingPromptTests {
    let now = testDate("2026-10-20 09:00")

    @Test("Not before a few good moments")
    func needsGoodMoments() {
        #expect(!AppRatingService.shouldAsk(happyMoments: 1, lastPrompt: nil, hasRated: false, now: now))
        #expect(!AppRatingService.shouldAsk(happyMoments: 2, lastPrompt: nil, hasRated: false, now: now))
        #expect(AppRatingService.shouldAsk(happyMoments: 3, lastPrompt: nil, hasRated: false, now: now))
    }

    @Test("Not again within thirty days")
    func spacesPrompts() {
        let lastWeek = testDate("2026-10-13 09:00")
        let twoMonthsAgo = testDate("2026-08-20 09:00")
        #expect(!AppRatingService.shouldAsk(happyMoments: 10, lastPrompt: lastWeek, hasRated: false, now: now))
        #expect(AppRatingService.shouldAsk(happyMoments: 10, lastPrompt: twoMonthsAgo, hasRated: false, now: now))
    }

    @Test("Never once they have rated")
    func afterRating() {
        #expect(!AppRatingService.shouldAsk(happyMoments: 10, lastPrompt: nil, hasRated: true, now: now))
    }
}
