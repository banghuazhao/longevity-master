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
    @FetchAll(animation: .default) var habits: [Habit]
    
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    @ObservationIgnored
    @Dependency(\.notificationService) var notificationService
    
    // Add selected category for filtering
    var selectedCategory: HabitCategory? = nil
    
    // Computed property for filtered habits
    var filteredHabits: [Habit] {
        guard let selectedCategory = selectedCategory else {
            return habits
        }
        return habits.filter { $0.category == selectedCategory }
    }
    
    @CasePathable
    enum Route {
        case editHabit(HabitFormViewModel)
        case createHabit(HabitFormViewModel)
        case habitDetail(HabitDetailViewModel)
    }
    var route: Route?
    
    func confirmDeleteHabit(_ habit: Habit) {
        withErrorReporting {
            notificationService.removeRemindersForHabit(habit.id)
            try  database.write { db in
                try Habit.delete(habit).execute(db)
            }
        }
    }
    
    func onTapHabitItem(_ habit: Habit) {
        route = .habitDetail(HabitDetailViewModel(habit: habit))
    }
    
    func onTapEditHabit(_ habit: Habit) {
        route = .editHabit(
            HabitFormViewModel(
                habit: Habit.Draft(habit)
            )
        )
    }
    
    func toggleFavorite(_ habit: Habit) {
        var updatedHabit = habit
        updatedHabit.isFavorite = !habit.isFavorite
        withErrorReporting {
            try database.write { db in
                try Habit
                    .update(updatedHabit)
                    .execute(db)
            }
        }
    }
    
    func toggleArchive(_ habit: Habit) {
        var updatedHabit = habit
        updatedHabit.isArchived = !habit.isArchived
        withErrorReporting {
            try database.write { db in
                try Habit
                    .update(updatedHabit)
                    .execute(db)
            }
        }
    }
    
    func onTapCreateHabit() {
        route = .createHabit(
            HabitFormViewModel(
                habit: Habit.Draft()
            )
        )
    }
    
    func selectCategory(_ category: HabitCategory?) {
        withAnimation {
            selectedCategory = category
        }
    }
}

struct HabitsListView: View {
    @State var viewModel = HabitsListViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // All categories option
                            CategoryFilterButton(
                                title: "All",
                                isSelected: viewModel.selectedCategory == nil,
                                action: { viewModel.selectCategory(nil) }
                            )
                            
                            // Individual category options
                            ForEach(HabitCategory.allCases, id: \.self) { category in
                                CategoryFilterButton(
                                    title: category.briefTitle,
                                    isSelected: viewModel.selectedCategory == category,
                                    action: { viewModel.selectCategory(category) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Habits List
                    ForEach(viewModel.filteredHabits) { habit in
                        HabitCardView(
                            habit: habit,
                            onEdit: { viewModel.onTapEditHabit(habit) },
                            onDelete: { viewModel.confirmDeleteHabit(habit) },
                            onToggleFavorite: { viewModel.toggleFavorite(habit) },
                            onToggleArchive: { viewModel.toggleArchive(habit) }
                        )
                        .padding(.horizontal)
                        .sheet(item: $viewModel.route.editHabit, id: \.self) { habitFormViewModel in
                            HabitFormView(
                                viewModel: habitFormViewModel
                            )
                        }
                        .onTapGesture {
                            viewModel.onTapHabitItem(habit)
                        }
                    }
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.onTapCreateHabit()
                    }) {
                        Image(systemName: "plus")
                            .appCircularButtonStyle()
                    }
                }
            }
            .sheet(item: $viewModel.route.createHabit, id: \.self) { habitFormViewModel in
                HabitFormView(viewModel: habitFormViewModel)
            }
            .navigationDestination(item: $viewModel.route.habitDetail) { habitDetailViewModel in
                HabitDetailView(viewModel: habitDetailViewModel)
            }
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    HabitsListView()
}
