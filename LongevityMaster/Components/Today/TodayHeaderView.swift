//
// Created by Banghua Zhao on 23/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

/// The top of the Today tab: how much of the selected day is done, and the week around it.
struct TodayHeaderView: View {
    let viewModel: TodayViewModel
    let done: Int
    let total: Int
    @Binding var isPlanningTimeOff: Bool

    @State private var isShowingCalendar = false
    @Dependency(\.themeManager) private var themeManager
    @ScaledMetric(relativeTo: .title) private var ringSize: CGFloat = 64

    private var theme: AppTheme { themeManager.current }
    private var isAllDone: Bool { total > 0 && done == total }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.medium) {
                ring

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppSpacing.small) {
                        dayTitle
                            .font(AppFont.title)
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        if !viewModel.isShowingToday {
                            Button {
                                viewModel.goToToday()
                            } label: {
                                Text("Today")
                                    .font(AppFont.footnote.weight(.semibold))
                                    .padding(.horizontal, AppSpacing.small)
                                    .padding(.vertical, 3)
                                    .background(theme.primaryColor.opacity(0.12), in: Capsule())
                                    .foregroundStyle(theme.primaryColor)
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                    }

                    Text(viewModel.selectedDate, format: dateFormat)
                        .font(AppFont.subheadline)
                        .foregroundStyle(theme.textSecondary)

                    statusLine
                        .font(AppFont.subheadline.weight(.semibold))
                        .foregroundStyle(isAllDone ? theme.primaryColor : theme.textPrimary)
                        .contentTransition(.numericText(value: Double(done)))
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                VStack(spacing: AppSpacing.small) {
                    restDayButton
                    Button {
                        isShowingCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                            .appCircularButtonStyle()
                    }
                    .accessibilityLabel(Text("Choose a Day"))
                }
            }

            if viewModel.isRestDay {
                HStack(spacing: AppSpacing.small) {
                    Text("😌")
                    Text("Rest day — nothing missed today counts against your streak.")
                        .font(AppFont.footnote)
                        .foregroundColor(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .transition(.opacity)
            }

            WeekStrip(viewModel: viewModel)
        }
        .appCardStyle(theme: theme)
        // Outside the card, which clips its contents, so the burst can spill over its edges.
        .overlay(alignment: .topLeading) {
            CelebrationBurst(trigger: viewModel.celebrationCount)
                .frame(width: ringSize, height: ringSize)
                .padding(AppSpacing.medium)
        }
        .animation(.snappy, value: viewModel.isShowingToday)
        .animation(.snappy, value: viewModel.isRestDay)
        .sheet(isPresented: $isShowingCalendar) {
            calendarSheet
        }
    }

    // MARK: - Pieces

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(theme.primaryColor.opacity(0.15), lineWidth: 7)
            Circle()
                .trim(from: 0, to: total == 0 ? 0 : CGFloat(done) / CGFloat(total))
                .stroke(theme.primaryColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if isAllDone {
                Image(systemName: "checkmark")
                    .font(AppFont.title.weight(.bold))
                    .foregroundStyle(theme.primaryColor)
                    .symbolEffect(.bounce, value: viewModel.celebrationCount)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text(verbatim: "\(done)/\(total)")
                    .font(AppFont.subheadline.weight(.bold))
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .foregroundStyle(theme.textPrimary)
                    .contentTransition(.numericText(value: Double(done)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(AppSpacing.small)
            }
        }
        .frame(width: ringSize, height: ringSize)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: done)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: total)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(done) of \(total) done"))
    }

    /// The weekday, since the navigation bar above already says "Today".
    @ViewBuilder
    private var dayTitle: some View {
        if viewModel.userCalendar.isDateInYesterday(viewModel.selectedDate) {
            Text("Yesterday")
        } else {
            Text(viewModel.selectedDate, format: .dateTime.weekday(.wide))
        }
    }

    /// The year only once it is not this one.
    private var dateFormat: Date.FormatStyle {
        let calendar = viewModel.userCalendar
        let sameYear = calendar.isDate(viewModel.selectedDate, equalTo: Date(), toGranularity: .year)
        let style = Date.FormatStyle.dateTime.day().month(.wide)
        return sameYear ? style : style.year()
    }

    @ViewBuilder
    private var statusLine: some View {
        if total == 0 {
            Text("Nothing scheduled")
        } else if isAllDone {
            if viewModel.isShowingToday {
                Text("All done for today!")
            } else {
                Text("All done!")
            }
        } else {
            Text("\(done) of \(total) done")
        }
    }

    private var restDayButton: some View {
        Button {
            withAnimation {
                viewModel.toggleRestDay()
            }
        } label: {
            Image(systemName: viewModel.isRestDay ? "moon.zzz.fill" : "moon.zzz")
                .contentTransition(.symbolEffect(.replace))
                .appCircularButtonStyle()
        }
        .accessibilityLabel(
            viewModel.isRestDay
                ? Text("Rest day on. Tap to turn off.")
                : Text("Mark today a rest day")
        )
        .contextMenu {
            Button {
                isPlanningTimeOff = true
            } label: {
                Label("Plan Time Off", systemImage: "calendar.badge.clock")
            }
        }
        .accessibilityAction(named: Text("Plan Time Off")) {
            isPlanningTimeOff = true
        }
    }

    private var calendarSheet: some View {
        NavigationStack {
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.selectedDate },
                    set: { viewModel.select($0) }
                ),
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .environment(\.calendar, viewModel.userCalendar)
            .tint(theme.primaryColor)
            .padding(.horizontal)
            .navigationTitle("Choose a Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Today") {
                        viewModel.goToToday()
                        isShowingCalendar = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isShowingCalendar = false }
                }
            }
            Spacer(minLength: 0)
        }
        .presentationDetents([.height(500), .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Week strip

/// Seven days to tap between, each ringed by how much of it was done. Swiping moves a week.
private struct WeekStrip: View {
    let viewModel: TodayViewModel

    @Dependency(\.themeManager) private var themeManager
    @ScaledMetric(relativeTo: .subheadline) private var cellSize: CGFloat = 36

    var body: some View {
        let week = viewModel.week
        let calendar = viewModel.userCalendar

        HStack(spacing: 0) {
            ForEach(week) { day in
                cell(day, calendar: calendar)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width < -40 {
                        viewModel.shiftWeek(by: 1)
                    } else if value.translation.width > 40 {
                        viewModel.shiftWeek(by: -1)
                    }
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: Text("Previous Week")) { viewModel.shiftWeek(by: -1) }
        .accessibilityAction(named: Text("Next Week")) { viewModel.shiftWeek(by: 1) }
    }

    private func cell(_ day: TodayViewModel.DayProgress, calendar: Calendar) -> some View {
        let theme = themeManager.current
        let isSelected = calendar.isDate(day.date, inSameDayAs: viewModel.selectedDate)
        let isToday = calendar.isDateInToday(day.date)

        return Button {
            Haptics.shared.vibrateIfEnabled()
            viewModel.select(day.date)
        } label: {
            VStack(spacing: 6) {
                Text(day.date, format: .dateTime.weekday(.narrow))
                    .font(AppFont.footnote.weight(.medium))
                    .foregroundStyle(isToday ? theme.primaryColor : theme.textSecondary)

                ZStack {
                    if isSelected {
                        Circle().fill(theme.primaryColor)
                    } else {
                        Circle().stroke(theme.primaryColor.opacity(0.12), lineWidth: 3)
                        if !day.isFuture && day.due > 0 {
                            Circle()
                                .trim(from: 0, to: day.fraction)
                                .stroke(theme.primaryColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                    }

                    // The bare number: the date style adds "日" in Chinese, too wide for the circle.
                    Text(verbatim: "\(calendar.component(.day, from: day.date))")
                        .font(AppFont.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(
                            isSelected ? Color.white : (isToday ? theme.primaryColor : theme.textPrimary)
                        )
                }
                .frame(width: cellSize, height: cellSize)

                // A mark under days that were finished or taken off.
                Group {
                    if day.isRestDay {
                        Image(systemName: "moon.zzz.fill")
                    } else if day.isComplete {
                        Image(systemName: "checkmark")
                    } else {
                        Color.clear
                    }
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(theme.primaryColor)
                .frame(height: 10)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .opacity(day.isFuture ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(day.isFuture)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: day.fraction)
        .animation(.snappy, value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day.date, format: .dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(accessibilityValue(day))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func accessibilityValue(_ day: TodayViewModel.DayProgress) -> Text {
        if day.isRestDay { return Text("Rest day") }
        if day.isFuture || day.due == 0 { return Text("") }
        return Text("\(day.done) of \(day.due) done")
    }
}

// MARK: - Celebration

/// A short burst of confetti from the progress ring when the day is finished. Nothing at all
/// for someone who has asked for less motion.
struct CelebrationBurst: View {
    let trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Dependency(\.themeManager) private var themeManager
    @State private var particles: [Particle] = []
    @State private var progress: CGFloat = 0

    private struct Particle: Identifiable {
        let id = UUID()
        let color: Color
        let size: CGFloat
        let angle: Double
        let distance: CGFloat
        let spin: Double
        let isStrip: Bool
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                RoundedRectangle(cornerRadius: particle.isStrip ? 1 : particle.size / 2)
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.isStrip ? particle.size * 0.45 : particle.size)
                    .rotationEffect(.degrees(particle.spin * progress))
                    .offset(
                        x: cos(particle.angle) * particle.distance * progress,
                        y: sin(particle.angle) * particle.distance * progress + 40 * progress
                    )
                    .opacity(1 - progress)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, _ in
            guard !reduceMotion else { return }
            burst()
        }
    }

    private func burst() {
        let theme = themeManager.current
        let palette: [Color] = [theme.primaryColor, theme.accent, .yellow, .pink, .mint, .blue]
        particles = (0..<32).map { _ in
            Particle(
                color: palette.randomElement()!,
                size: .random(in: 6...10),
                angle: .random(in: 0..<(2 * .pi)),
                distance: .random(in: 60...150),
                spin: .random(in: -360...360),
                isStrip: Bool.random()
            )
        }
        progress = 0
        // A turn later, so the new pieces are drawn at the centre before they fly out;
        // set in the same update they would appear already at the end.
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 1.2)) {
                progress = 1
            } completion: {
                particles = []
                progress = 0
            }
        }
    }
}
