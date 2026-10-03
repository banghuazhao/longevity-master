//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AppIntents
import WidgetKit

/// The widgets and controls render from a snapshot of the database taken in their own process,
/// so anything that changes today's list has to ask for a new one.
enum WidgetRefresher {
    static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) {
            ControlCenter.shared.reloadAllControls()
        }
        // Siri matches "Check in <habit>" against the names it was last given.
        LongevityShortcuts.updateAppShortcutParameters()
    }
}
