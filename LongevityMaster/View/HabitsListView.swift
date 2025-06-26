//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SharingGRDB

struct HabitsListView: View {
    @State var viewModel = HabitsListViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(viewModel.habits) { habit in
                    HabitCardView(
                        habit: habit,
                        onTapMore: {}
                    )
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    HabitsListView()
}
