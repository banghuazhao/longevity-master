//
// Created by Banghua Zhao on 03/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import WidgetKit

/// Today's progress on the Lock Screen: a ring, a line with what is next, or a single line of
/// text above the clock. Reads the same timeline as the Home Screen widget.
struct TodayProgressWidget: Widget {
    static let kind = "TodayProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: TodayHabitsProvider()) { entry in
            TodayProgressWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Today's Progress")
        .description("See how many of today's habits are done at a glance.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct TodayProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayHabitsEntry

    private var total: Int { entry.habits.count }
    private var completed: Int { entry.completedCount }
    private var remaining: [WidgetHabit] { entry.habits.filter { !$0.isCompleted } }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular: circular
            case .accessoryInline: inline
            default: rectangular
            }
        }
        .widgetURL(URL(string: "longevitymaster://today"))
    }

    @ViewBuilder
    private var circular: some View {
        if !entry.isDataAvailable || entry.habits.isEmpty {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: entry.isDataAvailable ? "checkmark" : "heart.text.square")
                    .font(.title3.weight(.semibold))
            }
        } else {
            Gauge(value: Double(completed), in: 0...Double(total)) {
                Image(systemName: "checkmark")
            } currentValueLabel: {
                Text("\(completed)/\(total)")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetAccentable()
        }
    }

    @ViewBuilder
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today")
                    .font(.headline)
                    .widgetAccentable()
                Spacer(minLength: 4)
                if entry.isDataAvailable, !entry.habits.isEmpty {
                    Text("\(completed)/\(total)")
                        .font(.headline)
                }
            }

            if !entry.isDataAvailable {
                Text("Open Longevity Master to get started.")
                    .font(.caption)
                    .lineLimit(2)
            } else if entry.habits.isEmpty {
                Text("Nothing scheduled today.")
                    .font(.caption)
            } else {
                Gauge(value: Double(completed), in: 0...Double(total)) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinearCapacity)

                if let next = remaining.first {
                    Text(verbatim: "\(next.icon) \(next.name)")
                        .font(.caption)
                        .lineLimit(1)
                } else {
                    Text("All done today 🎉")
                        .font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var inline: some View {
        if !entry.isDataAvailable {
            Text("Open Longevity Master")
        } else if entry.habits.isEmpty {
            Label("No habits due today", systemImage: "checkmark.circle")
        } else if remaining.isEmpty {
            Label("All \(total) habits done", systemImage: "checkmark.circle.fill")
        } else {
            Label("\(completed) of \(total) habits done", systemImage: "checkmark.circle")
        }
    }
}

#Preview(as: .accessoryRectangular) {
    TodayProgressWidget()
} timeline: {
    TodayHabitsEntry(date: Date(), habits: WidgetHabit.samples, isDataAvailable: true)
    TodayHabitsEntry(date: Date(), habits: [], isDataAvailable: true)
}

#Preview(as: .accessoryCircular) {
    TodayProgressWidget()
} timeline: {
    TodayHabitsEntry(date: Date(), habits: WidgetHabit.samples, isDataAvailable: true)
}
