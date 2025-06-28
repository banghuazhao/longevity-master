//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SharingGRDB
import Observation
import SwiftUINavigation

@Observable
@MainActor
class HabitsListViewModel {
    @ObservationIgnored
    @FetchAll var habits: [Habit]
    
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    @CasePathable
    enum Route {
        case editHabit(HabitFormViewModel)
    }
    var route: Route?
    
    func onTapDeleteHabit(_ habit: Habit) {
        withErrorReporting {
            try database.write { db in
                try Habit.delete(habit).execute(db)
            }
        }
    }
    
    func onTapEditHabit(_ habit: Habit) {
        route = .editHabit(
            HabitFormViewModel(
                habit: Habit.Draft(habit)
            )
        )
    }
}

struct HabitsListView: View {
    @State var viewModel = HabitsListViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(viewModel.habits) { habit in
                    HabitCardView(
                        habit: habit,
                        onEdit: { viewModel.onTapEditHabit(habit) },
                        onDelete: { viewModel.onTapDeleteHabit(habit) }
                    )
                    .padding(.horizontal)
                    .sheet(item: $viewModel.route.editHabit, id: \.self) { habitFormViewModel in
                        HabitFormView(
                            viewModel: habitFormViewModel
                        )
                    }
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
