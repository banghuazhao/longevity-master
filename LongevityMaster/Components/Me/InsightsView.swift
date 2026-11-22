//
// Created by Banghua Zhao on 22/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SQLiteData
import Sharing
import SwiftUI

/// What the last four weeks say about the user's habits, in a few plain sentences and one
/// chart.
struct InsightsView: View {
    @FetchAll(Habit.all) private var habits
    @FetchAll(CheckIn.all) private var checkIns
    @FetchAll(SkippedDay.all) private var skippedDays
    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true
    @Dependency(\.themeManager) private var themeManager

    private var theme: AppTheme { themeManager.current }
    private var calendar: Calendar { .userPreferred(startWeekOnMonday: startWeekOnMonday) }

    var body: some View {
        let insights = Insights.make(
            habits: habits,
            checkIns: checkIns,
            skippedDays: skippedDays,
            now: Date(),
            calendar: calendar
        )

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                if insights.hasEnoughData {
                    summaryCard(insights)

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        AppSectionHeader("By Day of the Week")
                        WeekdayChart(insights: insights, calendar: calendar)
                            .appCardStyle(theme: theme)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        AppSectionHeader("Highlights")
                        AppGroupedCard {
                            let rows = highlights(insights)
                            ForEach(rows.indices, id: \.self) { index in
                                if index > 0 {
                                    AppRowDivider()
                                }
                                rows[index]
                            }
                        }
                    }

                    Text("Based on your check-ins over the last 4 weeks.")
                        .font(AppFont.footnote)
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal)
            .padding(.top, AppSpacing.small)
            .padding(.bottom, AppSpacing.large)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary

    private func summaryCard(_ insights: Insights) -> some View {
        HStack(spacing: 0) {
            AppStatView(value: insights.totalCheckIns.formatted(), title: "Check-ins")
            AppStatDivider()
            AppStatView(value: "\(insights.activeDays)/\(Insights.windowDays)", title: "Active Days")
            AppStatDivider()
            AppStatView(
                value: trendValue(insights),
                title: "vs Last Week",
                valueColor: trendColor(insights)
            )
        }
        .appCardStyle(theme: theme)
    }

    private func trendValue(_ insights: Insights) -> String {
        guard let change = insights.weekOverWeekChange else {
            return insights.thisWeekCount > 0 ? "↑" : "–"
        }
        return change.formatted(.percent.precision(.fractionLength(0)).sign(strategy: .always(includingZero: false)))
    }

    private func trendColor(_ insights: Insights) -> Color? {
        let difference = insights.thisWeekCount - insights.lastWeekCount
        if difference > 0 { return .green }
        if difference < 0 { return .red }
        return nil
    }

    // MARK: - Highlights

    private func highlights(_ insights: Insights) -> [InsightRow] {
        var rows: [InsightRow] = []

        if let weekday = insights.bestWeekday {
            rows.append(InsightRow(
                systemImage: "calendar.badge.checkmark",
                color: .green,
                title: "Best day: \(weekdayName(weekday))",
                message: "You check in more on this day than on any other."
            ))
        }

        if let weekday = insights.quietestWeekday {
            rows.append(InsightRow(
                systemImage: "calendar.badge.exclamationmark",
                color: .orange,
                title: "Toughest day: \(weekdayName(weekday))",
                message: "Your fewest check-ins fall on this day. A reminder could help."
            ))
        }

        if let time = insights.mainTimeOfDay {
            let share = insights.mainTimeOfDayShare.formatted(.percent.precision(.fractionLength(0)))
            switch time {
            case .morning:
                rows.append(InsightRow(
                    systemImage: "sunrise.fill",
                    color: .yellow,
                    title: "Morning person",
                    message: "\(share) of your check-ins happen before noon."
                ))
            case .afternoon:
                rows.append(InsightRow(
                    systemImage: "sun.max.fill",
                    color: .orange,
                    title: "Afternoon achiever",
                    message: "\(share) of your check-ins happen between noon and 5 pm."
                ))
            case .evening:
                rows.append(InsightRow(
                    systemImage: "moon.stars.fill",
                    color: .indigo,
                    title: "Evening finisher",
                    message: "\(share) of your check-ins happen after 5 pm."
                ))
            }
        }

        if let habit = insights.mostConsistent {
            let share = habit.adherence.formatted(.percent.precision(.fractionLength(0)))
            rows.append(InsightRow(
                systemImage: "trophy.fill",
                color: .yellow,
                title: "Most consistent: \(habit.icon) \(habit.name)",
                message: "Done \(share) of the times it was due in the last 30 days."
            ))
        }

        if let habit = insights.needsAttention {
            let share = habit.adherence.formatted(.percent.precision(.fractionLength(0)))
            rows.append(InsightRow(
                systemImage: "arrow.up.heart.fill",
                color: .pink,
                title: "Needs attention: \(habit.icon) \(habit.name)",
                message: "Done \(share) of the times it was due. Try a reminder, or fewer days a week."
            ))
        }

        if let category = insights.topCategory {
            let share = insights.topCategoryShare.formatted(.percent.precision(.fractionLength(0)))
            rows.append(InsightRow(
                systemImage: "chart.pie.fill",
                color: .purple,
                title: "Strongest area: \(category.title)",
                message: "\(share) of your check-ins in the last 4 weeks."
            ))
        }

        rows.append(trendRow(insights))
        return rows
    }

    private func trendRow(_ insights: Insights) -> InsightRow {
        let detail: LocalizedStringKey = "This week: \(insights.thisWeekCount) · Last week: \(insights.lastWeekCount)"
        let difference = insights.thisWeekCount - insights.lastWeekCount
        guard difference != 0 else {
            return InsightRow(systemImage: "equal.circle.fill", color: .blue, title: "Steady with last week", message: detail)
        }
        guard let change = insights.weekOverWeekChange else {
            return InsightRow(systemImage: "chart.line.uptrend.xyaxis", color: .green, title: "Up on last week", message: detail)
        }
        let amount = abs(change).formatted(.percent.precision(.fractionLength(0)))
        return difference > 0
            ? InsightRow(systemImage: "chart.line.uptrend.xyaxis", color: .green, title: "Up \(amount) on last week", message: detail)
            : InsightRow(systemImage: "chart.line.downtrend.xyaxis", color: .red, title: "Down \(amount) on last week", message: detail)
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = calendar.standaloneWeekdaySymbols
        return symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : ""
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 44))
                .foregroundStyle(theme.primaryColor)
            Text("Not enough check-ins yet")
                .font(AppFont.headline)
                .foregroundStyle(theme.textPrimary)
            Text("Check in for a few days and your patterns will show up here.")
                .font(AppFont.subheadline)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.large * 2)
        .appCardStyle(theme: theme)
    }
}

/// One observation: a badge, a short headline and a sentence.
private struct InsightRow: View {
    let systemImage: String
    let color: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.smallMedium) {
            IconBadge(systemName: systemImage, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.subheadline.weight(.semibold))
                    .foregroundStyle(themeManager.current.textPrimary)
                Text(message)
                    .font(AppFont.footnote)
                    .foregroundStyle(themeManager.current.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.smallMedium)
        .accessibilityElement(children: .combine)
    }
}

/// Check-ins per day of the week, the best day picked out in the theme colour.
private struct WeekdayChart: View {
    let insights: Insights
    let calendar: Calendar

    @Dependency(\.themeManager) private var themeManager

    private let barHeight: CGFloat = 96

    var body: some View {
        let maximum = max(insights.weekdayCounts.map(\.count).max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: AppSpacing.small) {
            ForEach(insights.weekdayCounts) { day in
                let isBest = day.weekday == insights.bestWeekday
                VStack(spacing: AppSpacing.xSmall) {
                    Text(verbatim: "\(day.count)")
                        .font(AppFont.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(isBest ? themeManager.current.primaryColor : themeManager.current.textSecondary)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(themeManager.current.primaryColor.opacity(isBest ? 1 : 0.3))
                        .frame(height: max(barHeight * CGFloat(day.count) / CGFloat(maximum), 4))
                    Text(verbatim: shortName(day.weekday))
                        .font(AppFont.caption)
                        .foregroundStyle(themeManager.current.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: fullName(day.weekday)))
                .accessibilityValue(Text("\(day.count) check-ins"))
            }
        }
        .frame(height: barHeight + 44, alignment: .bottom)
    }

    private func shortName(_ weekday: Int) -> String {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : ""
    }

    private func fullName(_ weekday: Int) -> String {
        let symbols = calendar.standaloneWeekdaySymbols
        return symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : ""
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
}
