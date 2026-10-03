//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct LongevityWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayHabitsWidget()
        TodayProgressWidget()
        if #available(iOSApplicationExtension 18.0, *) {
            HabitCheckInControl()
        }
    }
}
