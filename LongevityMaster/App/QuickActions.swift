//
// Created by Banghua Zhao on 20/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

/// The shortcuts on the app icon's long-press menu. Set from code rather than Info.plist so
/// their titles follow the language picked inside the app, which a static list cannot.
enum QuickAction: String, CaseIterable {
    case checkIn = "com.appsbayarea.longevityMaster.checkIn"
    case newHabit = "com.appsbayarea.longevityMaster.newHabit"
    case weeklyReview = "com.appsbayarea.longevityMaster.weeklyReview"

    private var title: String {
        switch self {
        case .checkIn: return String(localized: "Check In")
        case .newHabit: return String(localized: "New Habit")
        case .weeklyReview: return String(localized: "Weekly Review")
        }
    }

    private var systemImage: String {
        switch self {
        case .checkIn: return "checkmark.circle"
        case .newHabit: return "plus.circle"
        case .weeklyReview: return "chart.bar.doc.horizontal"
        }
    }

    private var shortcutItem: UIApplicationShortcutItem {
        UIApplicationShortcutItem(
            type: rawValue,
            localizedTitle: title,
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: systemImage)
        )
    }

    /// Puts the shortcuts on the icon, in the current language.
    @MainActor
    static func install() {
        UIApplication.shared.shortcutItems = allCases.map(\.shortcutItem)
    }

    /// Leaves the shortcut for `RootView` to act on. Returns whether it was one of ours.
    @MainActor
    @discardableResult
    static func handle(_ item: UIApplicationShortcutItem) -> Bool {
        guard let action = QuickAction(rawValue: item.type) else { return false }
        // The user chose to come in; greeting them with an ad is the wrong answer.
        AppOpenAdPolicy.skipNextReturn()
        let router = AppRouter.shared
        switch action {
        case .checkIn:
            router.requestedTab = .today
        case .newHabit:
            router.requestedTab = .habits
            router.wantsNewHabit = true
        case .weeklyReview:
            router.presented = .weeklyReview(weekOf: Date())
        }
        return true
    }
}

/// SwiftUI has no hook for Home Screen quick actions, so the app keeps a delegate for them
/// and nothing else.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // A shortcut that launched the app arrives here rather than at the scene delegate.
        if let item = options.shortcutItem {
            MainActor.assumeIsolated { _ = QuickAction.handle(item) }
        }
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = QuickActionSceneDelegate.self
        return configuration
    }
}

/// Receives a shortcut chosen while the app is already running.
final class QuickActionSceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(MainActor.assumeIsolated { QuickAction.handle(shortcutItem) })
    }
}
