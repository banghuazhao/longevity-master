//
// Created by Banghua Zhao on 28/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HabitsGalleryView: View {
    @Binding var habit: Habit.Draft

    @State var category: HabitCategory = .diet

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(HabitCategory.allCases, id: \.self) { category in
                            CategoryFilterButton(
                                title: category.briefTitle,
                                isSelected: self.category == category,
                                action: { self.category = category }
                            )
                        }
                    }
                }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(
                        HabitsDataStore.all.filter { $0.category == category
                        },
                        id: \.name
                    ) { habitNew in
                        HabitDraftItemView(
                            todayHabit: habitNew.toTodayDraftHabit(),
                            onTap: {
                                Haptics.shared.vibrateIfEnabled()
                                habit = habitNew
                            }
                        )
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding(.top, 20)
        }
    }
}

#Preview {
    @Previewable @State var habit = Habit.Draft(Habit(id: 0))

    HabitsGalleryView(
        habit: $habit
    )
}
