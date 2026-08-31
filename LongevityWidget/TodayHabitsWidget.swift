//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import WidgetKit

struct TodayHabitsWidget: Widget {
    static let kind = "TodayHabitsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: TodayHabitsProvider()) { entry in
            TodayHabitsWidgetView(entry: entry)
                .containerBackground(WidgetTheme.background, for: .widget)
        }
        .configurationDisplayName("Today's Habits")
        .description("Check off today's habits without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

enum WidgetTheme {
    /// The theme colour the user picked in the app. It is stored there as a theme name this
    /// process cannot resolve, so the app mirrors the resolved colour into the App Group and
    /// the widget reads it back from there.
    static var accent: Color { Color(widgetHex: AppGroup.accentColorHex) }
    static let background = Color(.systemBackground)
}

struct TodayHabitsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayHabitsEntry

    /// Deliberately conservative: a widget that overflows its container clips the header
    /// rather than scrolling, so leave headroom for long habit names wrapping.
    private var visibleHabitCount: Int {
        switch family {
        case .systemSmall: 3
        case .systemLarge: 10
        default: 6
        }
    }

    private var columnCount: Int {
        family == .systemSmall ? 1 : 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if !entry.isDataAvailable {
                message("Open Longevity Master to get started.")
            } else if entry.habits.isEmpty {
                message("Nothing scheduled today. Enjoy the rest.")
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount),
                    alignment: .leading,
                    spacing: 6
                ) {
                    ForEach(entry.habits.prefix(visibleHabitCount)) { habit in
                        HabitRow(habit: habit, showsDetail: family != .systemSmall)
                    }
                }
                if entry.habits.count > visibleHabitCount {
                    Text("+\(entry.habits.count - visibleHabitCount) more")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "longevitymaster://today"))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            if entry.isDataAvailable, !entry.habits.isEmpty {
                Text("\(entry.completedCount)/\(entry.habits.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WidgetTheme.accent)
                    .contentTransition(.numericText())
            }
        }
    }

    private func message(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }
}

private struct HabitRow: View {
    let habit: WidgetHabit
    let showsDetail: Bool

    var body: some View {
        Button(intent: ToggleHabitCheckInIntent(habitID: habit.id)) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(widgetHex: habit.colorHex).opacity(habit.isCompleted ? 1 : 0.28))
                    if habit.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text(habit.icon)
                            .font(.system(size: 13))
                    }
                }
                .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(habit.name)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .strikethrough(habit.isCompleted, color: .secondary)
                        .foregroundStyle(habit.isCompleted ? .secondary : .primary)
                    if showsDetail, let detail = habit.detail {
                        Text(detail)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension Color {
    /// Habit colours are stored as 0xRRGGBBAA. The app has its own `Color(hex:)`, but that
    /// file is not part of the widget target.
    init(widgetHex hex: Int) {
        self.init(
            red: Double((hex >> 24) & 0xFF) / 255.0,
            green: Double((hex >> 16) & 0xFF) / 255.0,
            blue: Double((hex >> 8) & 0xFF) / 255.0,
            opacity: Double(hex & 0xFF) / 255.0
        )
    }
}

#Preview(as: .systemMedium) {
    TodayHabitsWidget()
} timeline: {
    TodayHabitsEntry(date: Date(), habits: WidgetHabit.samples, isDataAvailable: true)
    TodayHabitsEntry(date: Date(), habits: [], isDataAvailable: true)
    TodayHabitsEntry.unavailable
}
