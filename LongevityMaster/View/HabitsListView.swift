//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftData
import SwiftUI

struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(habits) { habit in
                    HabitCardView(
                        habit: habit,
                        onTapMore: {}
                    )
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    HabitsListView()
        .modelContainer(PreviewDataService.shared.modelContainer)
}
