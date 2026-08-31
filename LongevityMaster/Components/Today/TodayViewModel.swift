//
// Created by Banghua Zhao on 06/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Combine
import Foundation
import Observation
import SQLiteData
import SwiftUI
import SwiftUINavigation
import Sharing

@Observable
@MainActor
class TodayViewModel {
    var todayHabits: [TodayHabit] {
        updateTodayHabits()
    }

    var selectedDate: Date = Date()

    @CasePathable
    enum Route {
        case createHabit(HabitFormViewModel)
        case showDeleteAlert(Habit)
    }

    var route: Route?

    var isEditing: Bool = false
    var currentQuote: MotivationalQuote?
    var showMotivationalQuote: Bool = false

    @ObservationIgnored
    @FetchAll(
        Habit
            .where {
                !$0.isArchived
            }
            .order {
                $0.isFavorite.desc()
            }
        , animation: .default
    )
    var habits

    @ObservationIgnored
    @FetchAll(CheckIn.all, animation: .default)
    var checkIns

    @ObservationIgnored
    @FetchAll(SkippedDay.all, animation: .default)
    var skippedDays

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var dataBase

    @ObservationIgnored
    @Dependency(\.achievementService) var achievementService

    @ObservationIgnored
    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true

    @ObservationIgnored
    @Dependency(\.soundPlayer) private var soundPlayer
    @ObservationIgnored
    @Dependency(\.notificationService) private var notificationService
    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database
    @ObservationIgnored
    @Dependency(\.motivationalQuoteService) private var motivationalQuoteService
    

    var userCalendar: Calendar {
        .userPreferred(startWeekOnMonday: startWeekOnMonday)
    }

    /// Whether the selected day has been declared off from every habit.
    var isRestDay: Bool {
        let calendar = userCalendar
        return RestDays(skippedDays, in: calendar).isEveryHabitRestDay(selectedDate, in: calendar)
    }

    /// Declares the selected day off from everything, or takes it back. Habits stay on the
    /// list and can still be checked in — a rest day removes the obligation, not the option —
    /// but a day missed on one costs no streak.
    func toggleRestDay() {
        let calendar = userCalendar
        let startOfDay = selectedDate.startOfDay(for: calendar)
        let endOfDay = selectedDate.endOfDay(for: calendar)
        let existing = skippedDays.first {
            $0.habitID == nil && $0.date >= startOfDay && $0.date <= endOfDay
        }

        Haptics.shared.vibrateIfEnabled()
        withErrorReporting {
            try dataBase.write { [selectedDate] db in
                if let existing {
                    try SkippedDay.delete(existing).execute(db)
                } else {
                    try SkippedDay
                        .upsert { SkippedDay.Draft(date: selectedDate, habitID: nil) }
                        .execute(db)
                }
            }
            WidgetRefresher.reload()
            Task { await notificationService.syncAllReminders() }
        }
    }

    private var cancelable = Set<AnyCancellable>()

    func updateMotivationalQuote() {
        withAnimation {
            if motivationalQuoteService.shouldShowQuote() {
                currentQuote = motivationalQuoteService.getRandomQuote()
                showMotivationalQuote = true
            } else {
                showMotivationalQuote = false
            }
        }
    }

    func dismissMotivationalQuote() {
        withAnimation {
            motivationalQuoteService.dismissQuoteForToday()
            showMotivationalQuote = false
        }
    }

    private func updateTodayHabits() -> [TodayHabit] {
        // Both hoisted out of the per-habit work: `userCalendar` builds a Calendar and reads
        // UserDefaults on every access, and re-filtering check-ins per habit walks the whole
        // table each time.
        let calendar = userCalendar
        let checkInsByHabit = Dictionary(grouping: checkIns, by: \.habitID)
        let restDays = RestDays(skippedDays, in: calendar)

        return HabitSchedule
            .habitsDue(on: selectedDate, habits: habits, checkIns: checkIns, calendar: calendar)
            .map { scheduled in
                let habit = scheduled.habit
                let checkInsForHabit = checkInsByHabit[habit.id] ?? []
                let habitRestDays = restDays.forHabit(habit.id)
                let streak = switch habit.frequency {
                case .fixedDaysInWeek:
                    calculateStreakForFixedDays(days: habit.daysOfWeek, unit: .weekday, checkIns: checkInsForHabit, restDays: habitRestDays, calendar: calendar)
                case .fixedDaysInMonth:
                    calculateStreakForFixedDays(days: habit.daysOfMonth, unit: .day, checkIns: checkInsForHabit, restDays: habitRestDays, calendar: calendar)
                case .nDaysEachWeek, .nDaysEachMonth:
                    calculateStreakForNDaysPerPeriod(habit: habit, checkIns: checkInsForHabit, calendar: calendar)
                }
                let streakDescription = streak > 0 && scheduled.isCompleted
                    ? String(localized: "🔥 \(streak)d streak")
                    : nil
                return TodayHabit(
                    habit: habit,
                    isCompleted: scheduled.isCompleted,
                    streakDescription: streakDescription,
                    frequencyDescription: scheduled.frequencyDescription
                )
            }
    }

    func onTapHabitItem(_ todayHabit: TodayHabit) {
        Haptics.shared.vibrateIfEnabled()
        withErrorReporting {
            if todayHabit.isCompleted {
                try dataBase.write { [selectedDate, userCalendar] db in
                    try CheckIn
                        .where { $0.habitID.eq(todayHabit.habit.id) }
                        .where {
                            $0.date.between(
                                selectedDate.startOfDay(for: userCalendar),
                                and: selectedDate.endOfDay(for: userCalendar)
                            )
                        }
                        .delete()
                        .execute(db)
                }
                Task {
                    await soundPlayer.playCancelCheckinSound()
                }
            } else {
                try dataBase.write { [selectedDate, userCalendar] db in
                    // A habit cannot be both done and rested on the same day. The day off from
                    // everything is left alone: doing one habit anyway does not contradict it.
                    try SkippedDay
                        .where { $0.habitID.eq(todayHabit.habit.id) }
                        .where {
                            $0.date.between(
                                selectedDate.startOfDay(for: userCalendar),
                                and: selectedDate.endOfDay(for: userCalendar)
                            )
                        }
                        .delete()
                        .execute(db)

                    let checkIn = CheckIn.Draft(date: selectedDate, habitID: todayHabit.habit.id)
                    let savedCheckIn = try CheckIn.upsert { checkIn }.returning(\.self).fetchOne(db)

                    // Check for achievements after adding check-in
                    if let savedCheckIn {
                        Task {
                            await achievementService.checkAchievementsAndShow(for: savedCheckIn)
                        }
                    }
                }
                Task {
                    await soundPlayer.playCheckinSound()
                }
            }
            WidgetRefresher.reload()
            Task { await notificationService.syncAllReminders() }
        }
    }

    /// The widget writes check-ins from its own process, which GRDB's observation does not
    /// see, so re-read once the app comes back to the foreground.
    func reloadFromSharedDatabase() async {
        await withErrorReporting {
            try await $habits.load()
            try await $checkIns.load()
            try await $skippedDays.load()
        }
    }

    func onTapAddHabit(category: HabitCategory? = nil) {
        let icon = if let category {
            category.icon
        } else {
            "🥑"
        }
        route = .createHabit(
            HabitFormViewModel(
                habit: Habit.Draft(
                    category: category ?? .diet,
                    icon: icon
                )
            ) { [weak self] _ in
                guard let self else { return }
                route = nil
            }
        )
    }

    func onTapEdit() {
        withAnimation {
            isEditing.toggle()
        }
    }
    
    func showDeleteAlert(_ habit: Habit) {
        route = .showDeleteAlert(habit)
    }
    
    func confirmDeleteHabit(_ habit: Habit) {
        withErrorReporting {
            notificationService.removeRemindersForHabit(habit.id)
            try  database.write { db in
                try Habit.delete(habit).execute(db)
            }
            WidgetRefresher.reload()
        }
    }

    // MARK: - Private

    private func calculateStreakForFixedDays(
        days: Set<Int>,
        unit: Calendar.Component,
        checkIns: [CheckIn],
        restDays: Set<Date>,
        calendar: Calendar
    ) -> Int {
        // A habit scheduled on no days is never due, so it has no streak — and without this
        // the walk below would step backwards forever looking for a day that never matches.
        guard !days.isEmpty else { return 0 }

        let checkedDays = Set(checkIns.map { $0.date.startOfDay(for: calendar) })
        var streak = 0
        var currentDate = selectedDate

        while true {
            let currentValue = calendar.component(unit, from: currentDate)
            if !days.contains(currentValue) {
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                continue
            }

            let startOfDay = currentDate.startOfDay(for: calendar)
            if checkedDays.contains(startOfDay) {
                streak += 1
            } else if !restDays.contains(startOfDay) {
                // Not done, and not a day off: this is where the streak ends.
                break
            }

            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }

        return streak
    }

    /// Quota habits take no `restDays`, on purpose: they owe a count over a period rather than
    /// anything on a particular day, so there is no day to take off. Marking a day off still
    /// bridges the overall streak on My Stats, and still lowers what the period owes when a
    /// perfect week is judged.
    private func calculateStreakForNDaysPerPeriod(habit: Habit, checkIns: [CheckIn], calendar: Calendar) -> Int {
        let isPerWeek = habit.frequency == .nDaysEachWeek
        let targetDays = isPerWeek ? habit.nDaysPerWeek : habit.nDaysPerMonth
        // A quota of zero is met by every period, so the walk below would never terminate.
        guard targetDays > 0 else { return 0 }

        var streak = 0
        var currentPeriodStart = isPerWeek ? selectedDate.startOfWeek(for: calendar) : selectedDate.startOfMonth(for: calendar)
        var periodEnd = selectedDate.endOfDay(for: calendar)
        let calendarComponent: Calendar.Component = isPerWeek ? .weekOfYear : .month
        let endOfPeriod: (Date, Calendar) -> Date = isPerWeek ? { $0.endOfWeek(for: $1) } : { $0.endOfMonth(for: $1) }

        while true {
            let uniqueDays = Set(
                checkIns
                    .filter { $0.date >= currentPeriodStart && $0.date <= periodEnd }
                    .map { calendar.component(.day, from: $0.date) }
            )

            if uniqueDays.count < targetDays {
                streak += uniqueDays.count
                break
            }

            streak += uniqueDays.count
            guard let previousPeriodStart = calendar.date(byAdding: calendarComponent, value: -1, to: currentPeriodStart) else {
                break
            }
            currentPeriodStart = previousPeriodStart
            periodEnd = endOfPeriod(currentPeriodStart, calendar)
        }

        return streak
    }
}
