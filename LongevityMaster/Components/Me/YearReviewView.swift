//
// Created by Banghua Zhao on 17/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Charts
import SQLiteData
import Sharing
import SwiftUI

/// A look back at one calendar year: how many check-ins, on how many days, which months and
/// habits carried it, and a card to share. Opened from My Stats.
struct YearReviewView: View {
    @FetchAll(Habit.all, animation: .default) private var habits
    @FetchAll(CheckIn.all, animation: .default) private var checkIns
    @FetchAll(SkippedDay.all, animation: .default) private var skippedDays

    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true
    @Dependency(\.themeManager) private var themeManager

    /// `nil` until the user pages: the default year is decided once the check-ins are in,
    /// since it depends on whether last year has any.
    @State private var pickedYear: Int?

    private static let topHabitCount = 5

    private var calendar: Calendar {
        YearReview.calendar(from: .userPreferred(startWeekOnMonday: startWeekOnMonday))
    }

    private var earliestCheckIn: Date? {
        checkIns.map(\.date).min()
    }

    var body: some View {
        let now = Date()
        let calendar = calendar
        let earliest = earliestCheckIn
        let years = YearReview.availableYears(earliestCheckIn: earliest, now: now, calendar: calendar)
        let year = min(max(pickedYear ?? YearReview.defaultYear(now: now, earliestCheckIn: earliest, calendar: calendar), years.lowerBound), years.upperBound)
        let review = YearReview.make(
            year: year,
            now: now,
            habits: habits,
            checkIns: checkIns,
            skippedDays: skippedDays,
            calendar: calendar
        )

        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                yearPicker(review, years: years)
                if review.isEmpty {
                    emptyCard(review)
                } else {
                    summaryCard(review)
                    monthsCard(review, calendar: calendar)
                    topHabitsCard(review)
                    highlightsCard(review, calendar: calendar)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            if !review.isEmpty {
                ShareCardLink(content: .yearReview(review)) {
                    Label("Share My Year", systemImage: "square.and.arrow.up")
                        .font(AppFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.current.primaryColor, in: RoundedRectangle(cornerRadius: AppCornerRadius.button))
                }
                .padding(.horizontal)
                .padding(.vertical, AppSpacing.small)
                .background(.ultraThinMaterial)
            }
        }
        .appBackground()
        .navigationTitle("Year in Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Year picker

    /// Back as far as the year of the first check-in, forward as far as this one.
    private func yearPicker(_ review: YearReview, years: ClosedRange<Int>) -> some View {
        HStack {
            Button {
                shiftYear(from: review.year, by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .disabled(review.year <= years.lowerBound)
            .accessibilityLabel(Text("Previous year"))

            Spacer()

            VStack(spacing: 2) {
                // Verbatim: an interpolated number is formatted for the locale, as "2,026".
                Text(verbatim: String(review.year))
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
                Text(review.isCurrentYear ? "This year so far" : "Year in review")
                    .font(AppFont.footnote)
                    .foregroundStyle(themeManager.current.textSecondary)
            }

            Spacer()

            Button {
                shiftYear(from: review.year, by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .disabled(review.year >= years.upperBound)
            .accessibilityLabel(Text("Next year"))
        }
        .tint(themeManager.current.primaryColor)
    }

    private func shiftYear(from year: Int, by offset: Int) {
        Haptics.shared.vibrateIfEnabled()
        withAnimation {
            pickedYear = year + offset
        }
    }

    // MARK: - Empty

    private func emptyCard(_ review: YearReview) -> some View {
        VStack(spacing: AppSpacing.small) {
            Text(verbatim: "🌱")
                .font(.system(size: 48))
            // A year between two busy ones can be empty too, so this names the year rather
            // than saying "yet".
            Text("No check-ins in \(String(review.year))")
                .font(AppFont.headline)
                .foregroundStyle(themeManager.current.textPrimary)
            if review.isCurrentYear {
                Text("Check in on a habit and your year will start to take shape here.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.medium)
        .appCardStyle(theme: themeManager.current)
    }

    // MARK: - Summary

    private func summaryCard(_ review: YearReview) -> some View {
        VStack(spacing: AppSpacing.medium) {
            VStack(spacing: 4) {
                Text(verbatim: review.checkInCount.formatted())
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(themeManager.current.primaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(review.checkInCount == 1 ? "check-in" : "check-ins")
                    .font(AppFont.subheadline.weight(.medium))
                    .foregroundStyle(themeManager.current.textSecondary)
                Text(verbatim: review.verdict)
                    .font(AppFont.subheadline)
                    .foregroundStyle(themeManager.current.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppSpacing.small)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: AppSpacing.small) {
                statTile(value: "\(review.activeDayCount)/\(review.dayCount)", label: "active days")
                statTile(value: "\(review.longestStreak)", label: "best streak")
                statTile(value: "\(review.habits.count)", label: "habits")
            }
        }
        .appCardStyle(theme: themeManager.current)
    }

    private func statTile(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.current.primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(AppFont.footnote)
                .foregroundStyle(themeManager.current.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.small)
        .background(themeManager.current.background, in: RoundedRectangle(cornerRadius: AppCornerRadius.button))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Months

    private func monthsCard(_ review: YearReview, calendar: Calendar) -> some View {
        let theme = themeManager.current
        let best = review.bestMonth
        let monthStyle = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone)
        let nextYearStart = calendar.date(byAdding: .year, value: 1, to: review.yearStart) ?? review.yearEnd

        return VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle("Month by month", systemImage: "chart.bar.fill")

            Chart(review.months) { month in
                BarMark(
                    x: .value(String(localized: "Month"), month.month, unit: .month, calendar: calendar),
                    y: .value(String(localized: "Check-ins"), month.checkIns)
                )
                .foregroundStyle(theme.primaryColor.opacity(month.id == best?.id ? 1 : 0.45))
                .cornerRadius(3)
            }
            // The whole year, so December keeps its slot even while it is empty.
            .chartXScale(domain: review.yearStart...nextYearStart)
            .chartXAxis {
                // A centered label sits between its mark and the next one, so December needs
                // the next year's first day as a closing mark or its label is never drawn.
                AxisMarks(values: review.months.map(\.month) + [nextYearStart]) { _ in
                    AxisValueLabel(format: monthStyle.month(.narrow), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 150)

            if let best {
                let name = best.month.formatted(monthStyle.month(.wide))
                // Two keys rather than one: the catalog has no plural rules to lean on.
                Group {
                    if best.checkIns == 1 {
                        Text("Best month: \(name), with 1 check-in")
                    } else {
                        Text("Best month: \(name), with \(best.checkIns) check-ins")
                    }
                }
                .font(AppFont.footnote)
                .foregroundStyle(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: theme)
    }

    // MARK: - Habits

    private func topHabitsCard(_ review: YearReview) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle("Top habits", systemImage: "star.fill")

            ForEach(review.habits.prefix(Self.topHabitCount)) { total in
                NavigationLink {
                    HabitDetailView(viewModel: HabitDetailViewModel(habit: total.habit))
                } label: {
                    HStack(spacing: AppSpacing.smallMedium) {
                        Text(total.habit.icon)
                            .font(.system(size: 20))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: total.habit.color), in: RoundedRectangle(cornerRadius: 10))
                        Text(total.habit.name)
                            .font(AppFont.subheadline.weight(.medium))
                            .foregroundStyle(themeManager.current.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(verbatim: "\(total.checkIns)")
                            .font(AppFont.subheadline.weight(.semibold))
                            .foregroundStyle(themeManager.current.primaryColor)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(themeManager.current.textSecondary)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    // MARK: - Highlights

    private func highlightsCard(_ review: YearReview, calendar: Calendar) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle("Highlights", systemImage: "sparkles")

            if let weekday = review.busiestWeekday,
               calendar.standaloneWeekdaySymbols.indices.contains(weekday.weekday - 1) {
                highlightRow(
                    icon: "🗓️",
                    title: "Busiest day of the week",
                    value: calendar.standaloneWeekdaySymbols[weekday.weekday - 1]
                )
            }
            if let category = review.categories.first {
                highlightRow(icon: category.category.icon, title: "Top category", value: category.category.plainTitle)
            }
            if review.newHabitCount > 0 {
                highlightRow(icon: "🌱", title: "New habits started", value: "\(review.newHabitCount)")
            }
            if review.restDayCount > 0 {
                highlightRow(icon: "😴", title: "Rest days taken", value: "\(review.restDayCount)")
            }
            if let percent = review.activeDayPercent {
                highlightRow(icon: "📈", title: "Days with a check-in", value: "\(percent)%")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    private func highlightRow(icon: String, title: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: AppSpacing.smallMedium) {
            Text(verbatim: icon)
                .font(.system(size: 20))
                .frame(width: 32)
            Text(title)
                .font(AppFont.subheadline)
                .foregroundStyle(themeManager.current.textPrimary)
            Spacer(minLength: AppSpacing.small)
            Text(verbatim: value)
                .font(AppFont.subheadline.weight(.semibold))
                .foregroundStyle(themeManager.current.primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }

    private func sectionTitle(_ title: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(themeManager.current.primaryColor)
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(themeManager.current.textPrimary)
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    NavigationStack {
        YearReviewView()
    }
}
