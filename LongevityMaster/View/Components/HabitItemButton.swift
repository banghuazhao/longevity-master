//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI

struct HabitItemButton: View {
    let habit: Habit
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
        }) {
            VStack {
                ZStack {
                    Circle()
                        .stroke(
                            isCompleted ?
                                habit.borderColor :
                                Color.gray.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                        )
                        .background(
                            Circle()
                                .fill(isCompleted ? Color(hex: habit.color) : Color.clear)
                        )
                        .frame(width: 60, height: 60)

                    Text(habit.icon)
                        .font(.system(size: 32))
                        .foregroundColor(isCompleted ? .white : Color(hex: habit.color))
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
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
        HabitItemButton(
            habit: HabitsDataStore.eatSalmon,
            isCompleted: true
        ) {}

        HabitItemButton(
            habit: HabitsDataStore.swimming,
            isCompleted: false
        ) {}

        HabitItemButton(
            habit: HabitsDataStore.sleep,
            isCompleted: true
        ) {}
    }
    .padding()
}
