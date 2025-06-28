//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI

@main
struct LongevityMasterApp: App {
    init() {
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }

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
                
                MeView()
                    .tabItem {
                        Label("Me", systemImage: "person.fill")
                    }
            }
        }
    }
}
