//
// Created by Banghua Zhao on 03/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import Sharing
import SwiftUI

/// A look back at one week: how much of the plan got done, which habits carried it, which
/// slipped, and what to focus on next. Opened from My Stats, or from the end-of-week
/// notification.
struct WeeklyReviewView: View {
    @FetchAll(Habit.all, animation: .default) private var habits
    @FetchAll(CheckIn.all, animation: .default) private var checkIns
    @FetchAll(SkippedDay.all, animation: .default) private var skippedDays

    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true
    @Dependency(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss

    @State private var weekStart: Date
    private let showsCloseButton: Bool

    /// - Parameter initialWeek: any day in the week to open on; the most useful week to look
    ///   back on if `nil`.
    init(initialWeek: Date? = nil, showsCloseButton: Bool = false) {
        let calendar = Calendar.userPreferred(
            startWeekOnMonday: UserDefaults.standard.object(forKey: "startWeekOnMonday") as? Bool ?? true
        )
        let week = initialWeek ?? WeeklyReview.defaultWeek(now: Date(), calendar: calendar)
        _weekStart = State(initialValue: week.startOfWeek(for: calendar))
        self.showsCloseButton = showsCloseButton
    }

    private var calendar: Calendar {
        .userPreferred(startWeekOnMonday: startWeekOnMonday)
    }

    var body: some View {
        let review = WeeklyReview.make(
            weekContaining: weekStart,
            now: Date(),
            habits: habits,
            checkIns: checkIns,
            skippedDays: skippedDays,
            calendar: calendar
        )

        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                weekPicker(review)
                summaryCard(review)
                daysCard(review)
                if !review.strongest.isEmpty {
                    habitList(
                        "Carried the week",
                        systemImage: "star.fill",
                        results: review.strongest
                    )
                }
                if !review.needsAttention.isEmpty {
                    habitList(
                        "Needs attention",
                        systemImage: "exclamationmark.circle",
                        results: review.needsAttention
                    )
                }
                if let focus = review.needsAttention.first {
                    focusCard(focus, isCurrentWeek: review.isCurrentWeek)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            if review.adherence != nil {
                ShareCardLink(content: .weeklyReview(review)) {
                    Label("Share My Week", systemImage: "square.and.arrow.up")
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
        .navigationTitle("Weekly Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .appToolbarCircularButtonStyle()
                    }
                    .accessibilityLabel(Text("Close"))
                }
            }
        }
        .onChange(of: startWeekOnMonday) { _, _ in
            weekStart = weekStart.startOfWeek(for: calendar)
        }
    }

    // MARK: - Week picker

    /// Back as far as the first check-in, forward as far as the week under way.
    private func weekPicker(_ review: WeeklyReview) -> some View {
        let earliest = checkIns.map(\.date).min().map { $0.startOfWeek(for: calendar) } ?? review.weekStart
        let canGoBack = review.weekStart > earliest
        let canGoForward = !review.isCurrentWeek

        return HStack {
            Button {
                shiftWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoBack)
            .accessibilityLabel(Text("Previous week"))

            Spacer()

            VStack(spacing: 2) {
                Text(verbatim: Self.weekRange(review))
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
                Text(review.isCurrentWeek ? "This week so far" : "Week in review")
                    .font(AppFont.footnote)
                    .foregroundStyle(themeManager.current.textSecondary)
            }

            Spacer()

            Button {
                shiftWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoForward)
            .accessibilityLabel(Text("Next week"))
        }
        .tint(themeManager.current.primaryColor)
    }

    private func shiftWeek(by weeks: Int) {
        guard let shifted = calendar.date(byAdding: .day, value: 7 * weeks, to: weekStart) else { return }
        Haptics.shared.vibrateIfEnabled()
        withAnimation {
            weekStart = shifted
        }
    }

    static func weekRange(_ review: WeeklyReview) -> String {
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(review.weekStart.formatted(style)) – \(review.weekEnd.formatted(style))"
    }

    // MARK: - Summary

    private func summaryCard(_ review: WeeklyReview) -> some View {
        VStack(spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.medium) {
                ring(review.adherence)

                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: review.verdict)
                        .font(AppFont.subheadline.weight(.medium))
                        .foregroundStyle(themeManager.current.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let change = review.change {
                        changeBadge(change)
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: AppSpacing.small) {
                statTile(value: "\(review.checkInCount)", label: "check-ins")
                statTile(value: "\(review.activeDayCount)/7", label: "active days")
                statTile(value: "\(review.strongest.count)/\(review.habits.filter { $0.due >= 1 }.count)", label: "habits on track")
            }
        }
        .appCardStyle(theme: themeManager.current)
    }

    private func ring(_ adherence: Double?) -> some View {
        ZStack {
            Circle()
                .stroke(themeManager.current.primaryColor.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(adherence ?? 0, 1))
                .stroke(themeManager.current.primaryColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(verbatim: adherence.map { "\(Int(($0 * 100).rounded()))%" } ?? "–")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.current.textPrimary)
                Text("on track")
                    .font(.caption2)
                    .foregroundStyle(themeManager.current.textSecondary)
            }
        }
        .frame(width: 96, height: 96)
    }

    private func changeBadge(_ change: Int) -> some View {
        let color: Color = change > 0 ? .green : (change < 0 ? .orange : themeManager.current.textSecondary)
        return HStack(spacing: 4) {
            Image(systemName: change > 0 ? "arrow.up.right" : (change < 0 ? "arrow.down.right" : "equal"))
            if change == 0 {
                Text("Same as last week")
            } else {
                Text("\(abs(change)) pts vs last week")
            }
        }
        .font(AppFont.footnote.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
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
    }

    // MARK: - Days

    private func daysCard(_ review: WeeklyReview) -> some View {
        let most = max(review.days.map(\.checkInCount).max() ?? 0, 1)

        return VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle("Day by day", systemImage: "calendar")

            HStack(spacing: 0) {
                ForEach(review.days) { day in
                    VStack(spacing: 6) {
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(AppFont.footnote.weight(.semibold))
                            .foregroundStyle(themeManager.current.textSecondary)
                        dayMark(day, intensity: Double(day.checkInCount) / Double(most))
                        Text(verbatim: day.isFuture || day.checkInCount == 0 ? " " : "\(day.checkInCount)")
                            .font(.caption2)
                            .foregroundStyle(themeManager.current.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(day.date.formatted(.dateTime.weekday(.wide))))
                    .accessibilityValue(dayAccessibilityValue(day))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    @ViewBuilder
    private func dayMark(_ day: WeeklyReview.Day, intensity: Double) -> some View {
        if day.isFuture {
            Circle()
                .strokeBorder(themeManager.current.textSecondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .frame(width: 30, height: 30)
        } else if day.isRestDay && day.checkInCount == 0 {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 13))
                .foregroundStyle(themeManager.current.textSecondary)
                .frame(width: 30, height: 30)
                .background(themeManager.current.textSecondary.opacity(0.12), in: Circle())
        } else {
            Circle()
                .fill(themeManager.current.primaryColor.opacity(day.checkInCount == 0 ? 0.1 : 0.35 + 0.65 * intensity))
                .frame(width: 30, height: 30)
                .overlay {
                    if day.checkInCount > 0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
        }
    }

    private func dayAccessibilityValue(_ day: WeeklyReview.Day) -> Text {
        if day.isFuture { return Text("Still ahead") }
        if day.isRestDay && day.checkInCount == 0 { return Text("Rest day") }
        return Text("\(day.checkInCount) habits checked in")
    }

    // MARK: - Habits

    private func habitList(
        _ title: LocalizedStringKey,
        systemImage: String,
        results: [WeeklyReview.HabitResult]
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle(title, systemImage: systemImage)

            ForEach(results) { result in
                NavigationLink {
                    HabitDetailView(viewModel: HabitDetailViewModel(habit: result.habit))
                } label: {
                    HStack(spacing: AppSpacing.smallMedium) {
                        Text(result.habit.icon)
                            .font(.system(size: 20))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: result.habit.color), in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.habit.name)
                                .font(AppFont.subheadline.weight(.medium))
                                .foregroundStyle(themeManager.current.textPrimary)
                                .lineLimit(1)
                            Text("\(result.done) done · goal \(Int(result.due.rounded(.up)))")
                                .font(AppFont.footnote)
                                .foregroundStyle(themeManager.current.textSecondary)
                        }
                        Spacer(minLength: 0)
                        if let percent = result.adherencePercent {
                            Text(verbatim: "\(min(percent, 100))%")
                                .font(AppFont.subheadline.weight(.semibold))
                                .foregroundStyle(themeManager.current.primaryColor)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(themeManager.current.textSecondary)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    private func focusCard(_ focus: WeeklyReview.HabitResult, isCurrentWeek: Bool) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.smallMedium) {
            Text(verbatim: "🎯")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 4) {
                Text(isCurrentWeek ? "Focus for the rest of the week" : "Focus for next week")
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
                Text("Make “\(focus.habit.name)” the one habit you protect. Tie it to something you already do every day, like your morning coffee.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .appCardStyle(theme: themeManager.current)
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
        WeeklyReviewView()
    }
}
