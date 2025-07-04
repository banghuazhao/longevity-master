//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI

struct HabitItemView: View {
    let todayHabit: TodayHabit
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.shared.vibrateIfEnabled()
            onTap()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        todayHabit.isCompleted ?
                            todayHabit.habit.borderColor :
                            Color.gray.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(todayHabit.isCompleted ? Color(hex: todayHabit.habit.color) : Color.clear)
                    )

                HStack(spacing: 5) {
                    Text(todayHabit.habit.icon)
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading) {
                        Text(todayHabit.habit.name + (todayHabit.habit.isFavorite ? " ❤️" : ""))
                            .font(.system(size: 15))
                            .bold()
                            .minimumScaleFactor(0.4)
                            .lineLimit(2)
                        
                        Spacer().frame(height: 5)
                        
                        if let streakDescription = todayHabit.streakDescription {
                            Text(streakDescription)
                                .font(.system(size: 12))
                                .minimumScaleFactor(0.4)
                                .lineLimit(1)
                        }
                        
                        if let frequencyDescription = todayHabit.frequencyDescription {
                            Text(frequencyDescription)
                                .font(.system(size: 12))
                                .minimumScaleFactor(0.4)
                                .lineLimit(1)
                        }
                    }
                    Spacer()

                }
                .padding(.all, 10)
            }
            .frame(width: 160, height: 90)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 150, maximum: 240))],
        spacing: 12
    ) {
        HabitItemView(
            todayHabit: TodayHabit(
                habit: HabitsDataStore.eatSalmon.toMock,
                isCompleted: true,
                streakDescription: "🔥 4d streak",
                frequencyDescription: "1/3 weekly"
            )
        ) {}

        HabitItemView(
            todayHabit: TodayHabit(
                habit: HabitsDataStore.swimming.toMock,
                isCompleted: false,
                streakDescription: nil,
                frequencyDescription: "1/3 this week"
            )
        ) {}

        HabitItemView(
            todayHabit: TodayHabit(
                habit: HabitsDataStore.sleep.toMock,
                isCompleted: true,
                streakDescription: "🔥 4d streak",
                frequencyDescription: nil
            )
        ) {}
    }
    .padding()
}
