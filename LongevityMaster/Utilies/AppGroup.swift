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
}

extension Calendar {
    /// `Calendar.current` follows the device region's week start; the app lets the user pick,
    /// and every scheduling calculation has to agree on which one is in effect.
    static func userPreferred(startWeekOnMonday: Bool) -> Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = startWeekOnMonday ? 2 : 1 // 2 = Monday, 1 = Sunday
        return calendar
    }
}
