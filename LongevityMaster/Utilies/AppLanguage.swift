//
// Created by Banghua Zhao on 24/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// The language the app runs in, overriding the one the device would otherwise pick for it.
///
/// iOS resolves `String(localized:)` against the bundle's localization, and that is settled from
/// `AppleLanguages` while the process is starting — before any of this code runs. So a choice
/// made here is recorded for the *next* launch and cannot take effect in the running app, which
/// is why the picker says so rather than pretending otherwise.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    /// Each language names itself, the way system language lists do: someone hunting for Chinese
    /// in an app currently showing English is looking for 简体中文, not "Chinese".
    var title: String {
        switch self {
        case .system: return String(localized: "System")
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }

    static let storageKey = "appLanguage"

    /// The key iOS itself reads to decide a bundle's language order.
    private static let appleLanguagesKey = "AppleLanguages"

    /// What the app is set to — not necessarily what it is displaying, since a change made
    /// since launch is still waiting on a restart.
    static func current(defaults: UserDefaults = .standard) -> AppLanguage {
        defaults.string(forKey: storageKey).flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    /// Records the choice for the next launch. `.system` clears the override so the device's own
    /// language order applies again.
    static func select(_ language: AppLanguage, defaults: UserDefaults = .standard) {
        defaults.set(language.rawValue, forKey: storageKey)
        switch language {
        case .system:
            defaults.removeObject(forKey: appleLanguagesKey)
        case .english, .simplifiedChinese:
            defaults.set([language.rawValue], forKey: appleLanguagesKey)
        }
    }
}
