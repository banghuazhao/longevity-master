//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI
import SwiftUINavigation

struct TodayView: View {
    @State var viewModel = TodayViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .zero) {
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
                            Text("✅")
                                .font(AppFont.subheadline)
                        } else {
                            Text(viewModel.todayCompletionText)
                                .font(AppFont.subheadline)
                        }
                        
                        Spacer()
                        
                    }

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
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .padding()
            }
            .sheet(item: $viewModel.route.createHabit, id: \.self) { habitFormViewModel in
                HabitFormView(viewModel: habitFormViewModel)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.onTapEdit()
                    }) {
                        Image(systemName: "pencil")
                            .appCircularButtonStyle()
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
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    TodayView()
}
