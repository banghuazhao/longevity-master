//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI
import SwiftUINavigation

struct TodayView: View {
    @State var viewModel = TodayViewModel()
    
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .zero) {
                    if viewModel.showMotivationalQuote, let quote = viewModel.currentQuote {
                        MotivationalQuoteView(quote: quote) {
                            viewModel.dismissMotivationalQuote()
                        }
                        .padding(.bottom, AppSpacing.medium)
                        .padding(.horizontal, AppSpacing.medium)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.headline)

                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.selectedDate },
                                set: { newDate in
                                    withAnimation {
                                        viewModel.selectedDate = newDate
                                    }
                                }
                            ),
                            displayedComponents: .date
                        )
                        .environment(\.calendar, viewModel.userCalendar)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(ThemeManager.shared.current.primaryColor)
                        
                        if viewModel.hasCompletedToday {
                            Text(String(localized: "✅"))
                                .font(AppFont.subheadline)
                        } else {
                            Text(viewModel.todayCompletionText)
                                .font(AppFont.subheadline)
                        }
                        
                        Spacer()
                        
                    }

                    if viewModel.todayHabits.isEmpty {
                        EmptyStateView(
                            icon: "📅",
                            title: "No Habits for Today",
                            subtitle: "You don't have any habits scheduled for today. Create some habits to start your journey!",
                            buttonTitle: "Add Habit"
                        ) {
                            viewModel.onTapAddHabit()
                        }
                    } else {
                        VStack {
                            ForEach(HabitCategory.allCases, id: \.rawValue) { category in
                                let subHabits = viewModel.todayHabits.filter { $0.habit.category == category }
                                if !subHabits.isEmpty {
                                    HStack {
                                        Spacer()
                                        Text(category.title)
                                            .font(AppFont.headline)
                                        Spacer()
                                    }
                                    
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
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
                                                    .offset(x: -10, y: -10)
                                                }
                                            }
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
                                        }
                                        
                                        if viewModel.isEditing {
                                            Button {
                                                viewModel.onTapAddHabit(category: category)
                                            } label: {
                                                Image(systemName: "plus")
                                                    .font(AppFont.title)
                                                    .padding(.horizontal, AppSpacing.medium)
                                                    .frame(width: 160, height: 90)
                                                    .background(themeManager.current.primaryColor.opacity(0.1))
                                                    .foregroundColor(themeManager.current.primaryColor)
                                                    .clipShape(
                                                        RoundedRectangle(cornerRadius: 20)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .sheet(item: $viewModel.route.createHabit, id: \.self) { habitFormViewModel in
                HabitFormView(viewModel: habitFormViewModel)
            }
            .appBackground()
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.onTapEdit()
                    }) {
                        Text(viewModel.isEditing ? "Done" : "Edit")
                            .appRectButtonStyle()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.onTapAddHabit()
                    }) {
                        Image(systemName: "plus")
                            .appCircularButtonStyle()
                    }
                }
            }
            .onAppear {
                viewModel.updateMotivationalQuote()
            }
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    TodayView()
}
