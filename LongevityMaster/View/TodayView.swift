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

                        DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)

                        Spacer()
                    }

                    ForEach(HabitCategory.allCases, id: \.rawValue) { category in
                        let subHabits = viewModel.todayHabits.filter { $0.habit.category == category }
                        if !subHabits.isEmpty {
                            HStack {
                                Spacer()
                                Text(category.title)
                                Spacer()
                            }

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                                ForEach(subHabits, id: \.habit.id) { todayHabit in
                                    HabitItemView(
                                        todayHabit: todayHabit
                                    ) {
                                        Task {
                                            await viewModel.onTapHabitItem(todayHabit)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
            .sheet(item: $viewModel.destination.createHabit, id: \.self) { habitFormViewModel in
                HabitFormView(viewModel: habitFormViewModel)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.selectedDate) { _, _ in
                Task {
                    await viewModel.onChangeOfSelectedDate()
                }
            }
            .task {
                await viewModel.updateTodayHabits()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.onTapAddHabit()
                    }) {
                        Image(systemName: "plus")
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
