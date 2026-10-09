//
// Created by Banghua Zhao on 10/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import Sharing
import SwiftUI

@Observable
@MainActor
final class TimeOffViewModel {
    /// `nil` plans time off from every habit; otherwise from this one alone.
    let habit: Habit?

    var startDate: Date
    var endDate: Date

    @ObservationIgnored
    @FetchAll(SkippedDay.all, animation: .default) var skippedDays

    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database

    @ObservationIgnored
    @Dependency(\.notificationService) private var notificationService

    @ObservationIgnored
    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true

    init(habit: Habit? = nil, now: Date = Date()) {
        self.habit = habit
        let calendar = Calendar.current
        startDate = calendar.startOfDay(for: now)
        endDate = calendar.date(byAdding: .day, value: 6, to: calendar.startOfDay(for: now)) ?? now
    }

    var calendar: Calendar {
        .userPreferred(startWeekOnMonday: startWeekOnMonday)
    }

    /// How many days the picked range covers, before any already off are left out.
    var dayCount: Int {
        TimeOff.days(from: startDate, through: endDate, calendar: calendar).count
    }

    /// The latest end date the picker offers for the chosen start.
    var latestEndDate: Date {
        calendar.date(byAdding: .day, value: TimeOff.maxDays - 1, to: startDate) ?? startDate
    }

    var upcoming: [ClosedRange<Date>] {
        TimeOff.upcoming(skippedDays, habitID: habit?.id, asOf: Date(), calendar: calendar)
    }

    /// Keeps the end date inside what the picker allows when the start moves past it.
    func startDateChanged() {
        if endDate < startDate {
            endDate = startDate
        } else if endDate > latestEndDate {
            endDate = latestEndDate
        }
    }

    func addTimeOff() {
        let calendar = calendar
        withErrorReporting {
            try database.write { [startDate, endDate, habit] db in
                try TimeOff.add(from: startDate, through: endDate, habitID: habit?.id, calendar: calendar, in: db)
            }
        }
        Haptics.shared.vibrateIfEnabled()
        didChange()
    }

    func remove(_ range: ClosedRange<Date>) {
        let calendar = calendar
        withErrorReporting {
            try database.write { [habit] db in
                try TimeOff.remove(range, habitID: habit?.id, calendar: calendar, in: db)
            }
        }
        didChange()
    }

    private func didChange() {
        WidgetRefresher.reload()
        Task { await notificationService.syncAllReminders() }
    }
}

/// Plans a stretch of days off. Shown pushed from Me for every habit, and in a sheet from a
/// habit's own page for that habit.
struct TimeOffView: View {
    @State private var viewModel: TimeOffViewModel
    @Dependency(\.themeManager) private var themeManager

    init(habit: Habit? = nil) {
        _viewModel = State(initialValue: TimeOffViewModel(habit: habit))
    }

    var body: some View {
        Form {
            Section {
                DatePicker(
                    "From",
                    selection: $viewModel.startDate,
                    displayedComponents: .date
                )
                .onChange(of: viewModel.startDate) { _, _ in
                    viewModel.startDateChanged()
                }

                DatePicker(
                    "To",
                    selection: $viewModel.endDate,
                    in: viewModel.startDate ... viewModel.latestEndDate,
                    displayedComponents: .date
                )

                Button {
                    withAnimation {
                        viewModel.addTimeOff()
                    }
                } label: {
                    Label(
                        viewModel.dayCount == 1
                            ? String(localized: "Take 1 Day Off")
                            : String(localized: "Take \(viewModel.dayCount) Days Off"),
                        systemImage: "moon.zzz.fill"
                    )
                }
                .disabled(viewModel.dayCount == 0)
            } header: {
                if let habit = viewModel.habit {
                    Text(verbatim: "\(habit.icon) \(habit.name)")
                } else {
                    Text("All Habits")
                }
            } footer: {
                Text("Days off never break a streak. Days you already checked in stay checked in.")
            }

            Section("Upcoming Time Off") {
                if viewModel.upcoming.isEmpty {
                    Text("Nothing planned.")
                        .foregroundStyle(themeManager.current.textSecondary)
                } else {
                    ForEach(viewModel.upcoming, id: \.lowerBound) { range in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rangeText(for: range))
                                Text(dayCountText(for: range))
                                    .font(AppFont.caption)
                                    .foregroundStyle(themeManager.current.textSecondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                withAnimation {
                                    viewModel.remove(range)
                                }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(Text("Remove"))
                        }
                    }
                }
            }
        }
        .environment(\.calendar, viewModel.calendar)
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Time Off")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func rangeText(for range: ClosedRange<Date>) -> String {
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day().weekday(.abbreviated)
        let start = range.lowerBound.formatted(style)
        guard range.lowerBound != range.upperBound else { return start }
        return "\(start) – \(range.upperBound.formatted(style))"
    }

    private func dayCountText(for range: ClosedRange<Date>) -> String {
        let count = (viewModel.calendar.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day ?? 0) + 1
        return count == 1 ? String(localized: "1 day") : String(localized: "\(count) days")
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    NavigationStack {
        TimeOffView()
    }
}
