//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(habit.icon)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 5) {
                Text(habit.name)
                    .font(.subheadline).bold()
                    .lineLimit(1)

                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(habit.frequencyDescription)
                        .font(.caption2)
                        .lineLimit(1)
                }

                HStack {
                    Image(systemName: "hand.thumbsup")
                        .font(.caption2)

                    HStack(spacing: 2) {
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
            }

            Spacer()

            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Divider()
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .imageScale(.large)
            }
        }
        .padding()
        .background(
            Color(hex: habit.color)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(habit.borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        HabitCardView(
            habit: HabitsDataStore.eatSalmon,
            onEdit: {},
            onDelete: {}
        )

        HabitCardView(
            habit: HabitsDataStore.swimming,
            onEdit: {},
            onDelete: {}
        )
        
        HabitCardView(
            habit: HabitsDataStore.sleep,
            onEdit: {},
            onDelete: {}
        )
    }
}
