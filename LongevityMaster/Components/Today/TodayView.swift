//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI
import SwiftUINavigation

struct TodayView: View {
    @State var viewModel = TodayViewModel()
    @State private var programsViewModel = ProgramsViewModel()
    @State private var isReordering = false
    @State private var isPlanningTimeOff = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        let todayHabits = viewModel.todayHabits
        let completedCount = todayHabits.filter(\.isCompleted).count
        let habitsByCategory = Dictionary(grouping: todayHabits, by: \.habit.category)

        NavigationStack {
            ScrollView {
                VStack(spacing: .zero) {
                    TodayHeaderView(
                        viewModel: viewModel,
                        done: completedCount,
                        total: todayHabits.count,
                        isPlanningTimeOff: $isPlanningTimeOff
                    )

                    if viewModel.showMotivationalQuote, let quote = viewModel.currentQuote {
                        MotivationalQuoteView(quote: quote) {
                            viewModel.dismissMotivationalQuote()
                        }
                        .padding(.top, AppSpacing.medium)
                    }

                    ProgramsTodaySection(viewModel: programsViewModel)

                    if todayHabits.isEmpty {
                        EmptyStateView(
                            icon: "📅",
                            title: "No Habits for Today",
                            subtitle: "You don't have any habits scheduled for today. Create some habits to start your journey!",
                            buttonTitle: "Add Habit"
                        ) {
                            viewModel.onTapAddHabit()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            ForEach(HabitCategory.allCases, id: \.rawValue) { category in
                                let subHabits = habitsByCategory[category] ?? []
                                if !subHabits.isEmpty {
                                    categoryHeader(category, habits: subHabits)

                                    LazyVGrid(columns: gridColumns, spacing: 12) {
                                        ForEach(subHabits, id: \.habit.id) { todayHabit in
                                            HabitItemView(
                                                todayHabit: todayHabit
                                            ) {
                                                viewModel.onTapHabitItem(todayHabit)
                                            }
                                            .overlay(alignment: .topLeading) {
                                                if viewModel.isEditing {
                                                    Button {
                                                        viewModel.showDeleteAlert(todayHabit.habit)
                                                    } label: {
                                                        Image(systemName: "trash")
                                                            .appCircularButtonStyle(overrideColor: .red)
                                                    }
                                                    .accessibilityLabel(Text("Delete \(todayHabit.habit.name)"))
                                                    .offset(x: -10, y: -10)
                                                }
                                            }
                                        }
                                        
                                        if viewModel.isEditing {
                                            Button {
                                                viewModel.onTapAddHabit(category: category)
                                            } label: {
                                                Image(systemName: "plus")
                                                    .font(AppFont.title)
                                                    .frame(maxWidth: .infinity, minHeight: 84)
                                                    .background(themeManager.current.primaryColor.opacity(0.1))
                                                    .foregroundColor(themeManager.current.primaryColor)
                                                    .clipShape(
                                                        RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous)
                                                    )
                                            }
                                            .accessibilityLabel(Text("Add Habit"))
                                        }
                                    }
                                    .padding(.bottom, AppSpacing.small)
                                }
                            }
                        }
                        .padding(.top, AppSpacing.medium)
                    }
                }
                .padding()
            }
            .sheet(item: $viewModel.route.createHabit, id: \.self) { habitFormViewModel in
                HabitFormView(viewModel: habitFormViewModel)
            }
            // One alert for the screen. Attached inside the grid it was one per habit tile,
            // every one of them bound to the same single route.
            .alert(
                item: $viewModel.route.showDeleteAlert,
                title: { habit in
                    Text(String(localized: "Delete ‘\(habit.truncatedName)’?"))
                },
                actions: { habit in
                    Button("Delete", role: .destructive) {
                        viewModel.confirmDeleteHabit(habit)
                    }
                    Button("Cancel", role: .cancel) {}
                },
                message: { habit in
                    Text(String(localized: "This will permanently delete the habit ‘\(habit.truncatedName)’ and all its check-in history. This action cannot be undone. Are you sure you want to proceed?"))
                }
            )
            .appBackground()
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.onTapEdit()
                    }) {
                        Text(viewModel.isEditing ? "Done" : "Edit")
                            .appToolbarRectButtonStyle()
                    }
                }
                if viewModel.isEditing {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isReordering = true
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .appToolbarCircularButtonStyle()
                        }
                        .accessibilityLabel(Text("Reorder Habits"))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.onTapAddHabit()
                    }) {
                        Image(systemName: "plus")
                            .appToolbarCircularButtonStyle()
                    }
                    .accessibilityLabel(Text("Add Habit"))
                }
            }
            .sheet(isPresented: $isReordering) {
                ReorderHabitsView()
            }
            .sheet(isPresented: $isPlanningTimeOff) {
                NavigationStack {
                    TimeOffView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { isPlanningTimeOff = false }
                            }
                        }
                }
            }
            .onAppear {
                viewModel.updateMotivationalQuote()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                viewModel.catchUpWithClock()
                Task { await viewModel.reloadFromSharedDatabase() }
            }
            // Midnight, or a time-zone change, while the app is open in front of the user.
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                viewModel.catchUpWithClock()
            }
        }
    }

    /// Two tiles a row until the text is too large for them to share it.
    private var gridColumns: [GridItem] {
        dynamicTypeSize >= .xxLarge
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 150), spacing: 12)]
    }

    private func categoryHeader(_ category: HabitCategory, habits: [TodayHabit]) -> some View {
        let done = habits.filter(\.isCompleted).count
        return HStack(alignment: .firstTextBaseline) {
            Text(category.title)
                .font(AppFont.headline)
                .foregroundStyle(themeManager.current.textPrimary)
            Spacer()
            Text(verbatim: "\(done)/\(habits.count)")
                .font(AppFont.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(
                    done == habits.count ? themeManager.current.primaryColor : themeManager.current.textSecondary
                )
                .contentTransition(.numericText(value: Double(done)))
                .animation(.snappy, value: done)
                .accessibilityLabel(Text("\(done) of \(habits.count) done"))
        }
        .padding(.top, AppSpacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    TodayView()
}
