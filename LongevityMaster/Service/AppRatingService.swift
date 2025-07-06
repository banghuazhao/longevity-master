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
    @Shared(.appStorage("habitModificationCount")) private var habitModificationCount: Int = 0
    @ObservationIgnored
    @Shared(.appStorage("lastRatingPromptDate")) private var lastRatingPromptDate: Date?
    @ObservationIgnored
    @Shared(.appStorage("hasRatedApp")) private var hasRatedApp: Bool = false
        
    // Minimum days between rating prompts (to avoid spam)
    private let minimumDaysBetweenPrompts: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    
    init() {
        // No longer increment on initialization since we're tracking habit modifications
    }
    
    /// Increments the habit modification count and checks if we should show a rating prompt
    func incrementHabitModificationCount() {
        $habitModificationCount.withLock { $0 += 1 }
        print("Habit modification count: \(habitModificationCount)")
        
        // Check if we should show rating prompt
        checkAndShowRatingPrompt()
    }
    
    /// Checks if conditions are met to show a rating prompt
    private func checkAndShowRatingPrompt() {
        // Don't show if user has already rated
        guard !hasRatedApp else { return }
        
        // Don't show if we've shown a prompt recently
        if let lastPrompt = lastRatingPromptDate {
            let daysSinceLastPrompt = Date().timeIntervalSince(lastPrompt)
            if daysSinceLastPrompt < minimumDaysBetweenPrompts {
                return
            }
        }
        
        // Check if current habit modification count matches any threshold
        guard habitModificationCount.isMultiple(of: 3) else { return }
        
        // Show rating prompt
        showRatingPrompt()
    }
    
    /// Shows the system rating prompt
    private func showRatingPrompt() {
        print("showRatingPrompt")
        // Update last prompt date
        $lastRatingPromptDate.withLock { $0 = Date() }
        
        // Request review using StoreKit
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
            UIApplication.shared.open(url)
        }
    }
    
    /// Opens the App Store app page
    func openAppStorePage() {
        let appID = Constants.AppID.longevityMasterID
        let appURL = "https://apps.apple.com/app/id\(appID)"
        
        if let url = URL(string: appURL) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Resets the rating state (for testing purposes)
    func resetRatingState() {
        $habitModificationCount.withLock { $0 = 0 }
        $lastRatingPromptDate.withLock { $0 = nil }
        $hasRatedApp.withLock { $0 = false }
    }
    
    /// Gets the current habit modification count
    var currentHabitModificationCount: Int {
        habitModificationCount
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
