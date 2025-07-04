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
    
    // Add sort and filter properties
    enum SortOption: String, CaseIterable {
        case `default` = "Default"
        case name = "Name"
        case antiAgingRating = "Anti-Aging Rating"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case active = "Active"
        case archived = "Archived"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    @ObservationIgnored
    @Shared(.appStorage("selectedSortOption")) var selectedSortOption: SortOption = .default
    @ObservationIgnored
    @Shared(.appStorage("selectedFilterOption")) var selectedFilterOption: FilterOption = .all
    
    // Computed property for filtered and sorted habits
    var filteredHabits: [Habit] {
        var filtered = habits
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Apply additional filters
        switch selectedFilterOption {
        case .all:
            break // No additional filtering
        case .favorites:
            filtered = filtered.filter { $0.isFavorite }
        case .archived:
            filtered = filtered.filter { $0.isArchived }
        case .active:
            filtered = filtered.filter { !$0.isArchived }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .default:
            break
        case .name:
            filtered.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .antiAgingRating:
            filtered.sort { $0.antiAgingRating > $1.antiAgingRating }
        }
        
        return filtered
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
            ) { [weak self] _ in
                guard let self else { return }
                route = nil
            }
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
            ) { [weak self] _ in
                guard let self else { return }
                route = nil
            }
        )
    }
    
    func selectCategory(_ category: HabitCategory?) {
        withAnimation {
            selectedCategory = category
        }
    }
    
    func selectSortOption(_ option: SortOption) {
        withAnimation {
            $selectedSortOption.withLock { $0 = option }
        }
    }
    
    func selectFilterOption(_ option: FilterOption) {
        withAnimation {
            $selectedFilterOption.withLock { $0 = option }
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        // Sort Section
                        Section("Sort By") {
                            ForEach(HabitsListViewModel.SortOption.allCases, id: \.self) { option in
                                Button(action: {
                                    viewModel.selectSortOption(option)
                                }) {
                                    HStack {
                                        Text(option.displayName)
                                        if viewModel.selectedSortOption == option {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Filter Section
                        Section("Filter By") {
                            ForEach(HabitsListViewModel.FilterOption.allCases, id: \.self) { option in
                                Button(action: {
                                    viewModel.selectFilterOption(option)
                                }) {
                                    HStack {
                                        Text(option.displayName)
                                        if viewModel.selectedFilterOption == option {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Reset Option
                        if viewModel.selectedFilterOption != .all || viewModel.selectedSortOption != .default {
                            Divider()
                            Button("Reset to Default") {
                                viewModel.selectSortOption(.default)
                                viewModel.selectFilterOption(.all)
                            }
                        }
                    } label: {
                        ZStack {
                            Image(systemName: viewModel.selectedFilterOption != .all || viewModel.selectedSortOption != .default ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .appCircularButtonStyle()
                        }
                    }
                }
                
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
