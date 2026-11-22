//
// Created by Banghua Zhao on 22/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
import SwiftUI
import WidgetKit

/// Today's habits as a ring on the Lock Screen and in the Dynamic Island, with the next one
/// still to do. The app starts it from Settings and keeps it current as habits are checked in.
struct TodayLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TodayActivityAttributes.self) { context in
            LockScreenProgressView(state: context.state, accent: accent(context))
                .widgetURL(Self.todayURL)
        } dynamicIsland: { context in
            let accent = accent(context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Today", systemImage: "heart.text.square.fill")
                        .font(.headline)
                        .foregroundStyle(accent)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(verbatim: "\(context.state.done)/\(context.state.total)")
                        .font(.headline)
                        .monospacedDigit()
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: context.state.fraction)
                            .tint(accent)
                        NextHabitText(state: context.state)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                ProgressRing(fraction: context.state.fraction, accent: accent, lineWidth: 3)
                    .frame(width: 18, height: 18)
            } compactTrailing: {
                Text(verbatim: "\(context.state.done)/\(context.state.total)")
                    .monospacedDigit()
                    .foregroundStyle(accent)
            } minimal: {
                ProgressRing(fraction: context.state.fraction, accent: accent, lineWidth: 3)
                    .frame(width: 18, height: 18)
            }
            .widgetURL(Self.todayURL)
            .keylineTint(accent)
        }
    }

    private static let todayURL = URL(string: "longevitymaster://today")

    private func accent(_ context: ActivityViewContext<TodayActivityAttributes>) -> Color {
        Color(hex: context.attributes.accentColorHex)
    }
}

private struct LockScreenProgressView: View {
    let state: TodayActivityAttributes.ContentState
    let accent: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                ProgressRing(fraction: state.fraction, accent: accent, lineWidth: 6)
                if state.isAllDone {
                    Image(systemName: "checkmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(accent)
                } else {
                    Text(verbatim: "\(state.done)/\(state.total)")
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(state.isAllDone ? "All done today 🎉" : "Today's Habits")
                    .font(.headline)
                if !state.isAllDone {
                    Text("\(state.done) of \(state.total) habits done")
                        .font(.subheadline)
                        .monospacedDigit()
                }
                NextHabitText(state: state)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(16)
        // Left to the system, the card can come out dark while the text follows a light
        // appearance, leaving the text all but invisible. A dark card of its own, with text
        // drawn for a dark background, reads on any wallpaper in either appearance.
        .environment(\.colorScheme, .dark)
        .activityBackgroundTint(Color.black.opacity(0.75))
        .activitySystemActionForegroundColor(accent)
    }
}

private struct NextHabitText: View {
    let state: TodayActivityAttributes.ContentState

    var body: some View {
        if let next = state.nextHabit {
            Text("Next: \(next)")
        } else if state.total == 0 {
            Text("Nothing scheduled today.")
        } else {
            Text("Every habit is checked in.")
        }
    }
}

private struct ProgressRing: View {
    let fraction: Double
    let accent: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.25), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(fraction, 0.001))
                .stroke(accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview(
    "Lock Screen",
    as: .content,
    using: TodayActivityAttributes(day: Date(), accentColorHex: 0xFF772FFF)
) {
    TodayLiveActivity()
} contentStates: {
    TodayActivityAttributes.ContentState(done: 5, total: 8, nextHabit: "🧘‍♀️ Meditate")
    TodayActivityAttributes.ContentState(done: 8, total: 8, nextHabit: nil)
}
#endif
