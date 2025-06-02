//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let onTapMore: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(habit.icon)
                    .font(.title2)

                // Habit Name and Frequency
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)

                    Text(frequencyDescription(for: habit.frequency))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: onTapMore) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                }
            }

            if let description = habit.note {
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(
            (Color(hex: habit.color) ?? .gray).opacity(0.2)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
        .padding(.vertical, 4)
    }

    private func frequencyDescription(for frequency: HabitFrequency) -> String {
        switch frequency {
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
    HabitCardView(
        habit: Habit.makeDefaultHabit(name: "Eat Simon"),
        onTapMore: {}
    )
}
