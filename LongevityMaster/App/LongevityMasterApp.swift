//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftData
import SwiftUI

@main
struct LongevityMasterApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "calendar")
                    }

                HabitsListView()
                    .tabItem {
                        Label("Habits", systemImage: "list.bullet")
                    }
            }
        }
        .modelContainer(DataService.shared.modelContainer)
    }
}
