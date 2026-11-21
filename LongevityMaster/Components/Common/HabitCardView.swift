//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleArchive: () -> Void
    @State private var showDeleteAlert = false

    @Dependency(\.themeManager) private var themeManager
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 44

    var body: some View {
        let theme = themeManager.current

        HStack(spacing: AppSpacing.smallMedium) {
            Text(habit.icon)
                .font(.system(size: iconSize * 0.52))
                .frame(width: iconSize, height: iconSize)
                .background(
                    Color(hex: habit.color),
                    in: RoundedRectangle(cornerRadius: iconSize * 0.3, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: iconSize * 0.3, style: .continuous)
                        .strokeBorder(habit.borderColor.opacity(0.25), lineWidth: 1)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(habit.name)
                        .font(AppFont.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)

                    if habit.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption2)
                    }

                    if habit.isArchived {
                        Image(systemName: "archivebox.fill")
                            .foregroundStyle(theme.textSecondary)
                            .font(.caption2)
                    }
                }

                HStack(spacing: AppSpacing.small) {
                    HStack(spacing: 1.5) {
                        ForEach(0 ..< 5, id: \.self) { index in
                            Image(systemName: index < habit.antiAgingRating ? "star.fill" : "star")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(index < habit.antiAgingRating ? Color.orange : theme.textSecondary.opacity(0.4))
                        }
                    }

                    Text(habit.frequencyDescription)
                        .font(AppFont.footnote)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                }
            }
            // Read as one sentence rather than a dozen fragments — "calendar", then five
            // separate stars.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityAddTraits(.isButton)

            Spacer(minLength: 0)

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
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .contentShape(.rect)
            }
            .accessibilityLabel(Text("Actions for \(habit.name)"))
        }
        .padding(.leading, AppSpacing.smallMedium)
        .padding(.trailing, AppSpacing.xSmall)
        .padding(.vertical, 10)
        .contentShape(.rect)
        .opacity(habit.isArchived ? 0.55 : 1.0)
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

extension HabitCardView {
    private var accessibilityDescription: Text {
        var parts = [habit.name]
        if habit.isFavorite { parts.append(String(localized: "Favorite")) }
        if habit.isArchived { parts.append(String(localized: "Archived")) }
        parts.append(habit.frequencyDescription)
        parts.append(String(localized: "Anti-aging rating \(habit.antiAgingRating) of 5"))
        return Text(parts.joined(separator: ", "))
    }
}

#Preview {
    AppGroupedCard {
        HabitCardView(
            habit: HabitsDataStore.eatSalmon.toMock,
            onEdit: {},
            onDelete: {},
            onToggleFavorite: {},
            onToggleArchive: {}
        )

        HabitCardView(
            habit: HabitsDataStore.swimming.toMock,
            onEdit: {},
            onDelete: {},
            onToggleFavorite: {},
            onToggleArchive: {}
        )

        HabitCardView(
            habit: HabitsDataStore.sleep.toMock,
            onEdit: {},
            onDelete: {},
            onToggleFavorite: {},
            onToggleArchive: {}
        )
    }
}
