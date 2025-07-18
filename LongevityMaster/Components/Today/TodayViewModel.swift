//
// Created by Banghua Zhao on 06/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Combine
import Foundation
import Observation
import SharingGRDB
import SwiftUI
import SwiftUINavigation

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
        var cal = Calendar.current
        cal.firstWeekday = startWeekOnMonday ? 2 : 1 // 2 = Monday, 1 = Sunday
        return cal
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
        habits
            .compactMap { habit -> TodayHabit? in
                let checkInsForHabit = checkIns.filter { $0.habitID == habit.id }
                let startOfDay = selectedDate.startOfDay(for: userCalendar)
                let endOfDay = selectedDate.endOfDay(for: userCalendar)
                let checkInsToday = checkInsForHabit.filter { checkIn in
                    checkIn.date >= startOfDay &&
                        checkIn.date <= endOfDay
                }
                let isCompletedToday = checkInsToday.count > 0
                switch habit.frequency {
                case .fixedDaysInWeek:
                    // Day of the week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
                    let dayOfWeek = userCalendar.component(.weekday, from: selectedDate)
                    if habit.daysOfWeek.contains(dayOfWeek) {
                        let streak = calculateStreakForFixedDays(habit: habit, days: habit.daysOfWeek, unit: .weekday, checkIns: checkInsForHabit)
                        let streakDescription = streak > 0 && isCompletedToday ? String(localized: "🔥 \(streak)d streak") : nil
                        return TodayHabit(
                            habit: habit,
                            isCompleted: isCompletedToday,
                            streakDescription: streakDescription
                        )
                    } else {
                        return nil
                    }
                case .fixedDaysInMonth:
                    // Get the day of the month (1–31)
                    let dayOfMonth = userCalendar.component(.day, from: selectedDate)
                    if habit.daysOfMonth.contains(dayOfMonth) {
                        let streak = calculateStreakForFixedDays(habit: habit, days: habit.daysOfMonth, unit: .day, checkIns: checkInsForHabit)
                        let streakDescription = streak > 0 && isCompletedToday ? String(localized: "🔥 \(streak)d streak") : nil
                        return TodayHabit(
                            habit: habit,
                            isCompleted: isCompletedToday,
                            streakDescription: streakDescription
                        )
                    } else {
                        return nil
                    }
                case .nDaysEachWeek:
                    let startOfWeek = selectedDate.startOfWeek(for: userCalendar)
                    let endOfWeek = selectedDate.endOfWeek(for: userCalendar)
                    let checkInsThisWeek = checkInsForHabit.filter { checkIn in
                        checkIn.date >= startOfWeek &&
                            checkIn.date <= endOfWeek
                    }
                    if habit.nDaysPerWeek > checkInsThisWeek.count || isCompletedToday {
                        let streak = calculateStreakForNDaysPerPeriod(habit: habit, checkIns: checkInsForHabit)
                        let streakDescription = streak > 0 && isCompletedToday ? String(localized: "🔥 \(streak)d streak") : nil
                        let checkInsThisWeekUntilToday = checkInsForHabit.filter { checkIn in
                            checkIn.date >= startOfWeek &&
                                checkIn.date <= endOfDay
                        }
                        let frequencyDescription = String(localized: "\(checkInsThisWeekUntilToday.count)/\(habit.nDaysPerWeek) this week")
                        return TodayHabit(
                            habit: habit,
                            isCompleted: isCompletedToday,
                            streakDescription: streakDescription,
                            frequencyDescription: frequencyDescription
                        )
                    } else {
                        return nil
                    }
                case .nDaysEachMonth:
                    let startOfMonth = selectedDate.startOfMonth(for: userCalendar)
                    let endOfMonth = selectedDate.endOfMonth(for: userCalendar)
                    let checkInsThisMonth = checkInsForHabit.filter { checkIn in
                        checkIn.date >= startOfMonth &&
                            checkIn.date <= endOfMonth
                    }
                    if habit.nDaysPerMonth > checkInsThisMonth.count || isCompletedToday {
                        let streak = calculateStreakForNDaysPerPeriod(habit: habit, checkIns: checkInsForHabit)
                        let streakDescription = streak > 0 && isCompletedToday ? String(localized: "🔥 \(streak)d streak") : nil
                        let checkInsThisMonthUntilToday = checkInsForHabit.filter { checkIn in
                            checkIn.date >= startOfMonth &&
                                checkIn.date <= endOfDay
                        }
                        let frequencyDescription = String(localized: "\(checkInsThisMonthUntilToday.count)/\(habit.nDaysPerMonth) this month")
                        return TodayHabit(
                            habit: habit,
                            isCompleted: isCompletedToday,
                            streakDescription: streakDescription,
                            frequencyDescription: frequencyDescription
                        )
                    } else {
                        return nil
                    }
                }
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
