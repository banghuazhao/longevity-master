//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HabitIconButton: View {
    let habit: Habit

    private let calendar = Calendar.current
    private let currentDate = Date()

    private var isCompletedToday: Bool {
//        habit.completionDates.contains { date in
//            calendar.isDate(date, inSameDayAs: currentDate)
//        }
        true
    }

    var body: some View {
        Button(action: {
            toggleCompletion()
        }) {
            VStack {
                ZStack {
                    Circle()
                        .stroke(isCompletedToday ? Color.clear : Color.gray.opacity(0.5), lineWidth: 2)
                        .background(
                            Circle()
                                .fill(isCompletedToday ? Color(hex: habit.color) ?? .blue : Color.clear)
                        )
                        .frame(width: 60, height: 60)

                    Text(habit.icon)
                        .font(.system(size: 32))
                        .foregroundColor(isCompletedToday ? .white : Color(hex: habit.color) ?? .blue)
                }
                Text(habit.name)
                    .font(.subheadline)
                    .bold()
                    .minimumScaleFactor(0.4)
                    .lineLimit(2)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func toggleCompletion() {
        
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
        HabitIconButton(
            habit: HabitsDataStore.eatSalmon
        )

        HabitIconButton(
            habit: HabitsDataStore.swimming
        )

        HabitIconButton(
            habit: HabitsDataStore.sleep
        )
        
        HabitIconButton(
            habit: HabitsDataStore.sleep
        )
    }
    .padding()
}
