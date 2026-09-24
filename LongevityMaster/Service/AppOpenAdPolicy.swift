//
// Created by Banghua Zhao on 24/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// When the app-open ad may show. Kept apart from the ad SDK so the rules can be tested.
///
/// A habit tracker is opened many times a day for a few seconds at a time; an ad on every one
/// of those is what makes people stop opening it. So the ad waits until someone is past their
/// first day, shows at most once an hour, and never greets a person coming back from
/// something they just chose to do — sharing a card, reading a study, tapping a reminder.
enum AppOpenAdPolicy {
    /// No app-open ads until this long after onboarding. Users who onboarded before this rule
    /// existed have no date recorded, and get no grace period.
    static let newUserGracePeriod: TimeInterval = 24 * 60 * 60
    static let minimumGapBetweenAds: TimeInterval = 60 * 60
    /// How long a deliberate trip out of the app keeps the ad away on the way back.
    static let returnGracePeriod: TimeInterval = 30 * 60

    static let onboardingCompletedKey = "onboardingCompletedAt"
    private static let lastShownKey = "appOpenAdLastShownAt"
    private static let skipUntilKey = "appOpenAdSkipUntil"

    static func allows(
        now: Date,
        lastShown: Date?,
        onboardingCompletedAt: Date?,
        skipUntil: Date?
    ) -> Bool {
        if let skipUntil, now < skipUntil {
            return false
        }
        if let onboardingCompletedAt, now.timeIntervalSince(onboardingCompletedAt) < newUserGracePeriod {
            return false
        }
        if let lastShown, now.timeIntervalSince(lastShown) < minimumGapBetweenAds {
            return false
        }
        return true
    }

    /// Whether to show the ad on this return to the app. A pending skip is used up either way:
    /// it covers the one return it was set for.
    static func shouldPresent(now: Date = Date(), defaults: UserDefaults = .standard) -> Bool {
        let skipUntil = defaults.object(forKey: skipUntilKey) as? Date
        defaults.removeObject(forKey: skipUntilKey)
        return allows(
            now: now,
            lastShown: defaults.object(forKey: lastShownKey) as? Date,
            onboardingCompletedAt: defaults.object(forKey: onboardingCompletedKey) as? Date,
            skipUntil: skipUntil
        )
    }

    /// The user is leaving for something they chose — another app to share to, a web page, the
    /// App Store — or arriving from a reminder they tapped. Don't meet them with an ad.
    static func skipNextReturn(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(now.addingTimeInterval(returnGracePeriod), forKey: skipUntilKey)
    }

    static func recordShown(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(now, forKey: lastShownKey)
    }

    static func recordOnboardingCompleted(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(now, forKey: onboardingCompletedKey)
    }
}
