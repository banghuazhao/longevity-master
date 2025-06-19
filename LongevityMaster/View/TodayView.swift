//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI

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

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                                ForEach(subHabits, id: \.habit.id) { todayHabit in
                                    HabitItemButton(
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
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Action to add new habit
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onChange(of: viewModel.selectedDate) { _, _ in
                Task {
                    await viewModel.onChangeOfSelectedDate()
                }
            }
            .task {
                await viewModel.updateQuery()
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
