//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let onTapMore: () -> Void

    var body: some View {
        HStack {
            Text(habit.icon)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 5) {
                Text(habit.name)
                    .font(.subheadline).bold()

                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(frequencyDescription)
                        .font(.caption2)
                }

                HStack {
                    Image(systemName: "hand.thumbsup")
                        .font(.caption2)

                    ForEach(0 ..< habit.antiAgingRating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    ForEach(habit.antiAgingRating ..< 5, id: \.self) { _ in
                        Image(systemName: "star")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            Button(action: onTapMore) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .imageScale(.large)
            }
        }
        .padding()
        .background(
            (Color(hex: habit.color) ?? .gray).opacity(0.2)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    var borderColor: Color {
        let baseColor = Color(hex: habit.color) ?? .gray
        return baseColor.blend(with: .black, amount: 0.2)
    }

    var frequencyDescription: String {
        switch habit.frequency {
        case let .fixedDaysInWeek(days):
            return days.isEmpty ? "No days set" : "Every \(daysString(from: days))"
        case let .nDaysEachWeek(days):
            return "\(days) day(s) each week"
        case let .fixedDaysInMonth(days):
            return days.isEmpty ? "No days set" : "Every \(daysString(from: days)) of month"
        case let .nDaysEachMonth(days):
            return "\(days) day(s) each month"
        }
    }

    private func daysString(from days: Set<String>) -> String {
        return days.sorted().joined(separator: ", ")
    }

    private func daysString(from days: Set<Int>) -> String {
        return days.sorted().map { String($0) }.joined(separator: ", ")
    }
}

#Preview {
    List {
        HabitCardView(
            habit: Habit.makeDefaultHabit(name: "Eat blueberry"),
            onTapMore: {}
        )

        HabitCardView(
            habit: Habit.makeDefaultHabit(
                name: "Swimming",
                frequency: .fixedDaysInWeek([1, 3, 5]),
                icon: "🏊‍♂️",
                color: "#4ECDC4",
                note: "Swimming improves cardiovascular health, builds muscle strength, reduces stress, enhances flexibility, and is low-impact, suitable for all ages."
            ),
            onTapMore: {}
        )
    }
    .listStyle(.plain)
}
