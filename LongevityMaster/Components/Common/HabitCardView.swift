//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleArchive: () -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        HStack {
            Text(habit.icon)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(habit.name)
                        .font(.subheadline).bold()
                        .lineLimit(1)

                    if habit.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    if habit.isArchived {
                        Image(systemName: "archivebox.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    Spacer()
                }

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

                Button(action: onToggleFavorite) {
                    Label(
                        habit.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: habit.isFavorite ? "heart.slash" : "heart"
                    )
                }

                Button(action: onToggleArchive) {
                    Label(
                        habit.isArchived ? "Unarchive" : "Archive",
                        systemImage: habit.isArchived ? "archivebox" : "archivebox.fill"
                    )
                }

                Divider()

                Button(role: .destructive, action: {
                    showDeleteAlert.toggle()
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.primary)
                    .imageScale(.large)
                    .padding()
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
        .opacity(habit.isArchived ? 0.6 : 1.0)
        .alert(
            "Delete ‘\(habit.truncatedName)’?",
            isPresented: $showDeleteAlert,
            actions: {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                Button("Cancel", role: .cancel) {}
            }, message: {
                Text("This will permanently delete the habit ‘\(habit.truncatedName)’ and all its check-in history. This action cannot be undone. Are you sure you want to proceed?")
            }
        )
    }
}

#Preview {
    VStack {
        HabitCardView(
            habit: HabitsDataStore.eatSalmon,
            onEdit: {},
            onDelete: {},
            onToggleFavorite: {},
            onToggleArchive: {}
        )

        HabitCardView(
            habit: HabitsDataStore.swimming,
            onEdit: {},
            onDelete: {},
            onToggleFavorite: {},
            onToggleArchive: {}
        )

        HabitCardView(
            habit: HabitsDataStore.sleep,
            onEdit: {},
            onDelete: {},
            onToggleFavorite: {},
            onToggleArchive: {}
        )
    }
}
