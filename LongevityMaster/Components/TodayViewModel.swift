//
// Created by Banghua Zhao on 06/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Observation
import SharingGRDB
import SwiftUI
import SwiftUINavigation
import Combine

@Observable
@MainActor
class TodayViewModel {
    var todayHabits: [TodayHabit] = []
    var selectedDate: Date = Date()

    @CasePathable
    enum Destination {
        case createHabit(HabitFormViewModel)
    }

    var destination: Destination?

    @ObservationIgnored
    @FetchAll(Habit.all)
    var habits

    @ObservationIgnored
    @FetchAll(CheckIn.all)
    var checkIns

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var dataBase

    @ObservationIgnored
    @Dependency(\.calendar) var calendar
    
    private var cancelable = Set<AnyCancellable>()

    init() {
        $habits
            .publisher
            .dropFirst()
            .sink { _ in
                Task {
                    await self.updateTodayHabits()
                }
            }
            .store(in: &cancelable)
    }

    func updateTodayHabits() async {
        withAnimation {
            todayHabits = habits.compactMap { habit -> TodayHabit? in
                let checkInsForHabit = checkIns.filter { $0.habitID == habit.id }
                let startOfDay = selectedDate.startOfDay(for: calendar)
                let endOfDay = selectedDate.endOfDay(for: calendar)
                let checkInsToday = checkInsForHabit.filter { checkIn in
                    checkIn.date >= startOfDay &&
                        checkIn.date <= endOfDay
                }
                let isCompletedToday = checkInsToday.count > 0
                switch habit.frequency {
                case .fixedDaysInWeek:
                    // Day of the week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
                    let dayOfWeek = calendar.component(.weekday, from: selectedDate)
                    if habit.daysOfWeek.contains(dayOfWeek) {
                        let streak = calculateStreakForFixedDays(habit: habit, days: habit.daysOfWeek, unit: .weekday, checkIns: checkInsForHabit)
                        let streakDescription = streak > 0 && isCompletedToday ? "🔥 \(streak)d streak" : nil
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
                    let dayOfMonth = calendar.component(.day, from: selectedDate)
                    if habit.daysOfMonth.contains(dayOfMonth) {
                        let streak = calculateStreakForFixedDays(habit: habit, days: habit.daysOfMonth, unit: .day, checkIns: checkInsForHabit)
                        let streakDescription = streak > 0 && isCompletedToday ? "🔥 \(streak)d streak" : nil
                        return TodayHabit(
                            habit: habit,
                            isCompleted: isCompletedToday,
                            streakDescription: streakDescription
                        )
                    } else {
                        return nil
                    }
                case .nDaysEachWeek:
                    let startOfWeek = selectedDate.startOfWeek(for: calendar)
                    let endOfWeek = selectedDate.endOfWeek(for: calendar)
                    let checkInsThisWeek = checkInsForHabit.filter { checkIn in
                        checkIn.date >= startOfWeek &&
                            checkIn.date <= endOfWeek
                    }
                    if habit.nDaysPerWeek > checkInsThisWeek.count || isCompletedToday {
                        let streak = calculateStreakForNDaysPerPeriod(habit: habit, checkIns: checkInsForHabit)
                        let streakDescription = streak > 0 && isCompletedToday ? "🔥 \(streak)d streak" : nil
                        let checkInsThisWeekUntilToday = checkInsForHabit.filter { checkIn in
                            checkIn.date >= startOfWeek &&
                                checkIn.date <= endOfDay
                        }
                        let frequencyDescription = "\(checkInsThisWeekUntilToday.count)/\(habit.nDaysPerWeek) this week"
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
                    let startOfMonth = selectedDate.startOfMonth(for: calendar)
                    let endOfMonth = selectedDate.endOfMonth(for: calendar)
                    let checkInsThisMonth = checkInsForHabit.filter { checkIn in
                        checkIn.date >= startOfMonth &&
                            checkIn.date <= endOfMonth
                    }
                    if habit.nDaysPerMonth > checkInsThisMonth.count || isCompletedToday {
                        let streak = calculateStreakForNDaysPerPeriod(habit: habit, checkIns: checkInsForHabit)
                        let streakDescription = streak > 0 && isCompletedToday ? "🔥 \(streak)d streak" : nil
                        let checkInsThisMonthUntilToday = checkInsForHabit.filter { checkIn in
                            checkIn.date >= startOfMonth &&
                                checkIn.date <= endOfDay
                        }
                        let frequencyDescription = "\(checkInsThisMonthUntilToday.count)/\(habit.nDaysPerMonth) this month"
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
    }

    func onTapHabitItem(_ todayHabit: TodayHabit) async {
        await withErrorReporting {
            if todayHabit.isCompleted {
                try await dataBase.write { [selectedDate, calendar] db in
                    try CheckIn
                        .where { $0.habitID.eq(todayHabit.habit.id) }
                        .where {
                            $0.date.between(
                                selectedDate.startOfDay(for: calendar),
                                and: selectedDate.endOfDay(for: calendar)
                            )
                        }
                        .delete()
                        .execute(db)
                }
            } else {
                try await dataBase.write { [selectedDate] db in
                    let checkIn = CheckIn.Draft(date: selectedDate, habitID: todayHabit.habit.id)
                    try CheckIn.upsert(checkIn)
                        .execute(db)
                }
            }
            try await $checkIns.load()
            await updateTodayHabits()
        }
    }

    func onTapAddHabit() {
        destination = .createHabit(HabitFormViewModel(habit: Habit.Draft()))
    }

    // MARK: - Private

    private func calculateStreakForFixedDays(habit: Habit, days: Set<Int>, unit: Calendar.Component, checkIns: [CheckIn]) -> Int {
        var streak = 0
        var currentDate = selectedDate
        let sortedCheckIns = checkIns.sorted { $0.date < $1.date }

        while true {
            let currentValue = calendar.component(unit, from: currentDate)
            if !days.contains(currentValue) {
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                continue
            }

            let startOfDay = currentDate.startOfDay(for: calendar)
            let endOfDay = currentDate.endOfDay(for: calendar)

            let hasCheckIn = sortedCheckIns.contains { checkIn in
                checkIn.date >= startOfDay && checkIn.date <= endOfDay
            }

            if !hasCheckIn {
                break
            }

            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }

        return streak
    }

    private func calculateStreakForNDaysPerPeriod(habit: Habit, checkIns: [CheckIn]) -> Int {
        var streak = 0
        let isPerWeek = habit.frequency == .nDaysEachWeek
        var currentPeriodStart = isPerWeek ? selectedDate.startOfWeek(for: calendar) : selectedDate.startOfMonth(for: calendar)
        var periodEnd = selectedDate.endOfDay(for: calendar)
        let sortedCheckIns = checkIns.filter { $0.habitID == habit.id }
            .sorted { $0.date < $1.date }
        let targetDays = isPerWeek ? habit.nDaysPerWeek : habit.nDaysPerMonth
        let calendarComponent: Calendar.Component = isPerWeek ? .weekOfYear : .month
        let endOfPeriod: (Date, Calendar) -> Date = isPerWeek ? { $0.endOfWeek(for: $1) } : { $0.endOfMonth(for: $1) }

        while true {
            let checkInsInPeriod = sortedCheckIns.filter { checkIn in
                checkIn.date >= currentPeriodStart && checkIn.date <= periodEnd
            }
            let uniqueDays = Set(checkInsInPeriod.map { calendar.component(.day, from: $0.date) })

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
