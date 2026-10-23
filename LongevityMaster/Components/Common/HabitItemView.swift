//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI

struct HabitItemView: View {
    let todayHabit: TodayHabit
    /// Off where the tile only shows the habit — the habit's own page — rather than a day's
    /// check-in to toggle.
    var isCheckIn = true
    let onTap: () -> Void

    @Dependency(\.themeManager) private var themeManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 26
    @ScaledMetric(relativeTo: .title) private var iconBadgeSize: CGFloat = 44

    private var isDone: Bool { todayHabit.isCompleted }

    var body: some View {
        // No haptic here: the check-in itself gives one, and only when a check-in happens.
        Button(action: onTap) {
            HStack(spacing: AppSpacing.smallMedium) {
                Text(todayHabit.habit.icon)
                    .font(.system(size: iconSize))
                    .frame(width: iconBadgeSize, height: iconBadgeSize)
                    .background(
                        Circle().fill(isDone ? Color.white.opacity(0.45) : habitColor.opacity(0.35))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(todayHabit.habit.name + (todayHabit.habit.isFavorite ? " ❤️" : ""))
                        .font(AppFont.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.current.textPrimary)
                        .lineLimit(dynamicTypeSize >= .xLarge ? 3 : 2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    if let streakDescription = todayHabit.streakDescription {
                        detailText(streakDescription)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if let frequencyDescription = todayHabit.frequencyDescription {
                        detailText(frequencyDescription)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.smallMedium)
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
            .background(tileBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous)
                    .strokeBorder(
                        isDone ? habitBorderColor.opacity(0.5) : themeManager.current.secondaryGray.opacity(0.18),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isDone ? .clear : AppShadow.card.color,
                radius: AppShadow.card.radius,
                x: AppShadow.card.x,
                y: AppShadow.card.y
            )
            // Done is also shown by a mark, not the fill colour alone, which some people
            // cannot tell apart.
            .overlay(alignment: .topTrailing) {
                if isCheckIn && isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppFont.headline)
                        .foregroundStyle(.white, habitBorderColor)
                        .padding(6)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isDone)
        }
        .buttonStyle(PressableTileStyle())
        .allowsHitTesting(isCheckIn)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCheckIn && isDone ? .isSelected : [])
        .accessibilityValue(isCheckIn ? (isDone ? Text("Done") : Text("Not done")) : Text(""))
        .accessibilityHint(isCheckIn ? (isDone ? Text("Double-tap to undo the check-in") : Text("Double-tap to check in")) : Text(""))
    }

    private var habitColor: Color { Color(hex: todayHabit.habit.color) }
    private var habitBorderColor: Color { todayHabit.habit.borderColor }

    /// Done tiles take the habit's colour, laid over the card so the palette's translucent
    /// colours look the same whatever is behind them.
    private var tileBackground: some View {
        let shape = RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous)
        return ZStack {
            shape.fill(themeManager.current.card)
            if isDone {
                shape.fill(habitColor)
            }
        }
    }

    private func detailText(_ text: String) -> some View {
        Text(text)
            .font(AppFont.footnote)
            .foregroundStyle(themeManager.current.textPrimary.opacity(isDone ? 0.75 : 0.6))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

/// Sinks a little under the finger, so a tile feels pressed before it flips.
struct PressableTileStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
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
