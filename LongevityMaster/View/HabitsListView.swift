//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SharingGRDB

struct HabitsListView: View {
    @FetchAll private var habits: [Habit]

    var body: some View {
        NavigationSplitView {
            ScrollView {
                ForEach(habits) { habit in
                    HabitCardView(
                        habit: habit,
                        onTapMore: {}
                    )
                    .padding(.horizontal)
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    HabitsListView()
}
