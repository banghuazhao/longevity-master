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
        HabitSchedule
            .habitsDue(on: selectedDate, habits: habits, checkIns: checkIns, calendar: userCalendar)
            .map { scheduled in
                let habit = scheduled.habit
                let checkInsForHabit = checkIns.filter { $0.habitID == habit.id }
                let streak = switch habit.frequency {
                case .fixedDaysInWeek:
                    calculateStreakForFixedDays(habit: habit, days: habit.daysOfWeek, unit: .weekday, checkIns: checkInsForHabit)
                case .fixedDaysInMonth:
                    calculateStreakForFixedDays(habit: habit, days: habit.daysOfMonth, unit: .day, checkIns: checkInsForHabit)
                case .nDaysEachWeek, .nDaysEachMonth:
                    calculateStreakForNDaysPerPeriod(habit: habit, checkIns: checkInsForHabit)
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
                try dataBase.write { [selectedDate] db in
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
        }
    }

    /// The widget writes check-ins from its own process, which GRDB's observation does not
    /// see, so re-read once the app comes back to the foreground.
    func reloadFromSharedDatabase() async {
        await withErrorReporting {
            try await $habits.load()
            try await $checkIns.load()
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

    var hasCompletedToday: Bool {
        todayHabits.allSatisfy { $0.isCompleted }
    }

    var todayCompletionText: String {
        return "\(todayHabits.filter(\.isCompleted).count) / \(todayHabits.count)"
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

    private func calculateStreakForFixedDays(habit: Habit, days: Set<Int>, unit: Calendar.Component, checkIns: [CheckIn]) -> Int {
        var streak = 0
        var currentDate = selectedDate
        let sortedCheckIns = checkIns.sorted { $0.date < $1.date }

        while true {
            let currentValue = userCalendar.component(unit, from: currentDate)
            if !days.contains(currentValue) {
                currentDate = userCalendar.date(byAdding: .day, value: -1, to: currentDate)!
                continue
            }

            let startOfDay = currentDate.startOfDay(for: userCalendar)
            let endOfDay = currentDate.endOfDay(for: userCalendar)

            let hasCheckIn = sortedCheckIns.contains { checkIn in
                checkIn.date >= startOfDay && checkIn.date <= endOfDay
            }

            if !hasCheckIn {
                break
            }

            streak += 1
            guard let previousDate = userCalendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }

        return streak
    }

    private func calculateStreakForNDaysPerPeriod(habit: Habit, checkIns: [CheckIn]) -> Int {
        var streak = 0
        let isPerWeek = habit.frequency == .nDaysEachWeek
        var currentPeriodStart = isPerWeek ? selectedDate.startOfWeek(for: userCalendar) : selectedDate.startOfMonth(for: userCalendar)
        var periodEnd = selectedDate.endOfDay(for: userCalendar)
        let sortedCheckIns = checkIns.filter { $0.habitID == habit.id }
            .sorted { $0.date < $1.date }
        let targetDays = isPerWeek ? habit.nDaysPerWeek : habit.nDaysPerMonth
        let calendarComponent: Calendar.Component = isPerWeek ? .weekOfYear : .month
        let endOfPeriod: (Date, Calendar) -> Date = isPerWeek ? { $0.endOfWeek(for: $1) } : { $0.endOfMonth(for: $1) }

        while true {
            let checkInsInPeriod = sortedCheckIns.filter { checkIn in
                checkIn.date >= currentPeriodStart && checkIn.date <= periodEnd
            }
            let uniqueDays = Set(checkInsInPeriod.map { userCalendar.component(.day, from: $0.date) })

            if uniqueDays.count < targetDays {
                streak += uniqueDays.count
                break
            }

            streak += uniqueDays.count
            guard let previousPeriodStart = userCalendar.date(byAdding: calendarComponent, value: -1, to: currentPeriodStart) else {
                break
            }
            currentPeriodStart = previousPeriodStart
            periodEnd = endOfPeriod(currentPeriodStart, userCalendar)
        }

        return streak
    }
}
