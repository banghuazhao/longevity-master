//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// The container the app and its widget extension share. Each target has its own private
/// sandbox, so anything the widget needs to read — the database, the week-start preference —
/// has to live here instead.
enum AppGroup {
    static let identifier = "group.com.appsbayarea.longevityMaster"

    /// `nil` when the App Group entitlement is missing or has not been provisioned yet.
    /// Callers must keep working without it; only the widget goes dark.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    // MARK: - Week start

    private static let startWeekOnMondayKey = "startWeekOnMonday"

    /// The app stores this in its own defaults, which the widget cannot see, so the app
    /// mirrors it here whenever it launches or the setting changes.
    static func mirrorStartWeekOnMonday(_ startWeekOnMonday: Bool) {
        defaults?.set(startWeekOnMonday, forKey: startWeekOnMondayKey)
    }

    static func mirrorStartWeekOnMondayFromAppDefaults() {
        let standard = UserDefaults.standard
        mirrorStartWeekOnMonday(standard.object(forKey: startWeekOnMondayKey) as? Bool ?? true)
    }

    /// Matches the app's own default of starting the week on Monday when nothing is mirrored.
    static var startWeekOnMonday: Bool {
        guard let defaults, defaults.object(forKey: startWeekOnMondayKey) != nil else { return true }
        return defaults.bool(forKey: startWeekOnMondayKey)
    }

    // MARK: - Accent colour

    private static let accentColorHexKey = "accentColorHex"

    /// The app's default orange (#FF772F), for a widget added before the app has mirrored
    /// anything.
    private static let defaultAccentColorHex = 0xFF772FFF

    /// The user's chosen theme is stored as a theme *name* the widget target has no way to
    /// resolve — `ThemeColor` lives in the app. So the app resolves it and mirrors the
    /// finished colour, packed as 0xRRGGBBAA, which the widget can render on its own.
    static func mirrorAccentColor(hex: Int) {
        defaults?.set(hex, forKey: accentColorHexKey)
    }

    static var accentColorHex: Int {
        guard let defaults,
              defaults.object(forKey: accentColorHexKey) != nil
        else { return defaultAccentColorHex }
        return defaults.integer(forKey: accentColorHexKey)
    }
}
