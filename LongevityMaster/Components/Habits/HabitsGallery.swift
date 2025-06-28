//
// Created by Banghua Zhao on 28/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HabitsGalleryView: View {
    @Binding var habit: Habit.Draft

    @State var category: HabitCategory = .diet

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Category", selection: $category) {
                        ForEach(HabitCategory.allCases, id: \.self) { category in
                            Text(category.briefTitle).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        ForEach(
                            HabitsDataStore.all.filter { $0.category == category }
                        ) { habitNew in
                            HabitItemView(
                                todayHabit: habitNew.toTodayHabit(),
                                onTap: {
                                    habit = habitNew.newHabitDraft
                                }
                            )
                        }
                    }
    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

#Preview {
    @Previewable @State var habit = Habit.Draft(Habit(id: 0))

    HabitsGalleryView(
        habit: $habit
    )
}
