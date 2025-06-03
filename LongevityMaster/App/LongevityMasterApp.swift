//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import SwiftData

@main
struct LongevityMasterApp: App {
    var body: some Scene {
        WindowGroup {
            HabitsListView()
        }
        .modelContainer(DataService.shared.modelContainer)
    }
}
