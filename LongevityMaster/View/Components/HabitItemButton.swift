//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI

struct HabitItemButton: View {
    let todayHabit: TodayHabit
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
        }) {
            VStack {
                ZStack {
                    Circle()
                        .stroke(
                            todayHabit.isCompleted ?
                                todayHabit.habit.borderColor :
                                Color.gray.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                        )
                        .background(
                            Circle()
                                .fill(todayHabit.isCompleted ? Color(hex: todayHabit.habit.color) : Color.clear)
                        )
                        .frame(width: 60, height: 60)

                    Text(todayHabit.habit.icon)
                        .font(.system(size: 32))
                        .foregroundColor(todayHabit.isCompleted ? .white : Color(hex: todayHabit.habit.color))
                }
                VStack(alignment: .leading) {
                    Text(todayHabit.habit.name)
                        .font(.subheadline)
                        .bold()
                        .minimumScaleFactor(0.4)
                        .lineLimit(2)
                    if !todayHabit.completionDetail.isEmpty {
                        Text(todayHabit.completionDetail)
                            .font(.body)
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
        HabitItemButton(
            todayHabit: TodayHabit(
                habit: HabitsDataStore.eatSalmon,
                isCompleted: true,
                completionDetail: "🔥 4d streak"
            )
        ) {}

        HabitItemButton(
            todayHabit: TodayHabit(
                habit: HabitsDataStore.swimming,
                isCompleted: false,
                completionDetail: ""
            )
        ) {}

        HabitItemButton(
            todayHabit: TodayHabit(
                habit: HabitsDataStore.sleep,
                isCompleted: true,
                completionDetail: ""
            )
        ) {}
    }
    .padding()
}
