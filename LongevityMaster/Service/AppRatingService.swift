//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import StoreKit
import SwiftUI
import Dependencies
import Sharing

@Observable
class AppRatingService {
    @ObservationIgnored
    @Shared(.appStorage("ratingHappyMoments")) private var happyMoments: Int = 0
    @ObservationIgnored
    @Shared(.appStorage("lastRatingPromptDate")) private var lastRatingPromptDate: Date?
    @ObservationIgnored
    @Shared(.appStorage("hasRatedApp")) private var hasRatedApp: Bool = false

    /// Minimum time between rating prompts, on top of the system's own limit of three a year.
    static let minimumIntervalBetweenPrompts: TimeInterval = 30 * 24 * 60 * 60
    /// How many good moments someone has had before they are first asked.
    static let happyMomentsBeforeAsking = 3

    init() {}

    /// Records a moment someone is likely pleased with the app — an achievement just earned,
    /// the last of the day's habits ticked off — and asks for a rating if it is time.
    ///
    /// This used to ask on every third habit added or edited: in the middle of filling in a
    /// form, which is when people are least in the mood to be asked anything.
    func noteHappyMoment(now: Date = Date()) {
        $happyMoments.withLock { $0 += 1 }
        debugLog("Happy moments: \(happyMoments)")
        guard Self.shouldAsk(
            happyMoments: happyMoments,
            lastPrompt: lastRatingPromptDate,
            hasRated: hasRatedApp,
            now: now
        ) else { return }
        showRatingPrompt(now: now)
    }

    /// Whether this moment should bring up the prompt.
    static func shouldAsk(happyMoments: Int, lastPrompt: Date?, hasRated: Bool, now: Date) -> Bool {
        guard !hasRated, happyMoments >= happyMomentsBeforeAsking else { return false }
        guard let lastPrompt else { return true }
        return now.timeIntervalSince(lastPrompt) >= minimumIntervalBetweenPrompts
    }

    /// Shows the system rating prompt, after a moment so it does not land on top of the tap
    /// that earned it.
    private func showRatingPrompt(now: Date) {
        debugLog("showRatingPrompt")
        $lastRatingPromptDate.withLock { $0 = now }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }

    /// Manually trigger rating prompt (for testing or manual rating button)
    func requestRating() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    /// Opens the App Store review page
    func openAppStoreReview() {
        let appID = Constants.AppID.longevityMasterID
        let reviewURL = "https://itunes.apple.com/app/id\(appID)?action=write-review"
        
        if let url = URL(string: reviewURL) {
            AppOpenAdPolicy.skipNextReturn()
            UIApplication.shared.open(url)
        }
    }
    
    /// Opens the App Store app page
    func openAppStorePage() {
        let appID = Constants.AppID.longevityMasterID
        let appURL = "https://apps.apple.com/app/id\(appID)"
        
        if let url = URL(string: appURL) {
            AppOpenAdPolicy.skipNextReturn()
            UIApplication.shared.open(url)
        }
    }
    
    /// Resets the rating state (for testing purposes)
    func resetRatingState() {
        $happyMoments.withLock { $0 = 0 }
        $lastRatingPromptDate.withLock { $0 = nil }
        $hasRatedApp.withLock { $0 = false }
    }
    
    
    /// Checks if user has rated the app
    var userHasRated: Bool {
        hasRatedApp
    }
}

// MARK: - Dependency Injection
extension DependencyValues {
    var appRatingService: AppRatingService {
        get { self[AppRatingServiceKey.self] }
        set { self[AppRatingServiceKey.self] = newValue }
    }
}

private enum AppRatingServiceKey: DependencyKey {
    static let liveValue = AppRatingService()
} 
