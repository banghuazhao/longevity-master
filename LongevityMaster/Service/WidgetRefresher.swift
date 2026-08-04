//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import WidgetKit

/// The widget renders from a snapshot of the database taken in its own process, so anything
/// that changes today's list has to ask WidgetKit for a new one.
enum WidgetRefresher {
    static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
