//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI

struct HabitIconButton: View {
    @Dependency(\.defaultDatabase) var dataBase

    let habit: Habit

    @FetchAll
    var checkInDates: [CheckInDate]

    private let calendar = Calendar.current
    private let currentDate = Date()

    private var isCompletedToday: Bool {
        checkInDates.contains { checkInDate in
            calendar.isDate(checkInDate.date, inSameDayAs: currentDate)
                && checkInDate.habitID == habit.id
        }
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
        if isCompletedToday {
            withErrorReporting {
                try dataBase.write { db in
                    let todayCheckIns = checkInDates.filter { checkInDate in
                        calendar.isDate(checkInDate.date, inSameDayAs: currentDate)
                        && checkInDate.habitID == habit.id
                    }
                    let ids = todayCheckIns.map(\.id)
                    try CheckInDate
                        .where { $0.id.in(ids) }
                        .delete()
                        .execute(db)
                }
            }
        } else {
            withErrorReporting {
                try dataBase.write { db in
                    let checkInDate = CheckInDate.Draft(date: Date(), habitID: habit.id)
                    try CheckInDate.upsert(checkInDate)
                        .execute(db)
                }
            }
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
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
    }
    .padding()
}
