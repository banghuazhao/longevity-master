//
// Created by Banghua Zhao on 04/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// A habit that belongs on a given day's list, and whether it has been checked in yet.
struct ScheduledHabit {
    let habit: Habit
    let isCompleted: Bool
    /// Running total for quota habits ("2/5 this week"). Fixed-day habits have no total, so nil.
    let frequencyDescription: String?
}

/// Decides which habits belong on a day's list. The Today tab and the home-screen widget both
/// go through here so the two can never disagree about what the user still owes today.
enum HabitSchedule {
    static func habitsDue(
        on date: Date,
        habits: [Habit],
        checkIns: [CheckIn],
        calendar: Calendar
    ) -> [ScheduledHabit] {
        let startOfDay = date.startOfDay(for: calendar)
        let endOfDay = date.endOfDay(for: calendar)

        // Grouped once instead of re-filtered per habit: otherwise every habit walks the whole
        // check-in table, every time the day's list is rebuilt.
        let checkInsByHabit = Dictionary(grouping: checkIns, by: \.habitID)

        return habits.compactMap { habit -> ScheduledHabit? in
            let checkInsForHabit = checkInsByHabit[habit.id] ?? []
            let isCompletedToday = checkInsForHabit.contains { checkIn in
                checkIn.date >= startOfDay && checkIn.date <= endOfDay
            }

            switch habit.frequency {
            case .fixedDaysInWeek:
                let dayOfWeek = calendar.component(.weekday, from: date)
                guard habit.daysOfWeek.contains(dayOfWeek) else { return nil }
                return ScheduledHabit(
                    habit: habit,
                    isCompleted: isCompletedToday,
                    frequencyDescription: nil
                )

            case .fixedDaysInMonth:
                let dayOfMonth = calendar.component(.day, from: date)
                guard habit.daysOfMonth.contains(dayOfMonth) else { return nil }
                return ScheduledHabit(
                    habit: habit,
                    isCompleted: isCompletedToday,
                    frequencyDescription: nil
                )

            case .nDaysEachWeek:
                let startOfWeek = date.startOfWeek(for: calendar)
                let endOfWeek = date.endOfWeek(for: calendar)
                let checkInsThisWeek = checkInsForHabit.filter { checkIn in
                    checkIn.date >= startOfWeek && checkIn.date <= endOfWeek
                }
                // Still on the list if the week's quota is unmet, or if it was done today and
                // so should stay visible as completed rather than vanishing under the user.
                guard habit.nDaysPerWeek > checkInsThisWeek.count || isCompletedToday else { return nil }
                let checkInsUntilToday = checkInsForHabit.filter { checkIn in
                    checkIn.date >= startOfWeek && checkIn.date <= endOfDay
                }
                return ScheduledHabit(
                    habit: habit,
                    isCompleted: isCompletedToday,
                    frequencyDescription: String(localized: "\(checkInsUntilToday.count)/\(habit.nDaysPerWeek) this week")
                )

            case .nDaysEachMonth:
                let startOfMonth = date.startOfMonth(for: calendar)
                let endOfMonth = date.endOfMonth(for: calendar)
                let checkInsThisMonth = checkInsForHabit.filter { checkIn in
                    checkIn.date >= startOfMonth && checkIn.date <= endOfMonth
                }
                guard habit.nDaysPerMonth > checkInsThisMonth.count || isCompletedToday else { return nil }
                let checkInsUntilToday = checkInsForHabit.filter { checkIn in
                    checkIn.date >= startOfMonth && checkIn.date <= endOfDay
                }
                return ScheduledHabit(
                    habit: habit,
                    isCompleted: isCompletedToday,
                    frequencyDescription: String(localized: "\(checkInsUntilToday.count)/\(habit.nDaysPerMonth) this month")
                )
            }
        }
    }
}
