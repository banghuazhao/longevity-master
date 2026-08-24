//
// Created by Banghua Zhao on 25/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

/// `HabitSchedule` is the one place that decides what the user owes on a given day. The Today
/// tab and the home-screen widget both go through it precisely so the two cannot disagree, so
/// what it says is worth pinning down.
@Suite("What is due on a day")
struct HabitScheduleTests {
    private let calendar = testCalendar()

    /// 2026-08-25 is a Tuesday — weekday 3 in Calendar's 1 = Sunday numbering.
    private let tuesday = testDate("2026-08-25")

    private func habit(
        id: Int,
        frequency: HabitFrequency,
        detail: String,
        isArchived: Bool = false
    ) -> Habit {
        Habit(
            id: id,
            name: "Habit \(id)",
            category: .diet,
            frequency: frequency,
            frequencyDetail: detail,
            antiAgingRating: 3,
            icon: "🥑",
            color: 0,
            note: "",
            isFavorite: false,
            isArchived: isArchived
        )
    }

    private func checkIn(_ id: Int, _ day: String, habitID: Int) -> CheckIn {
        CheckIn(id: id, date: testDate(day, calendar), habitID: habitID)
    }

    // MARK: - Fixed days of the week

    @Test("A habit set for Tuesday is due on Tuesday")
    func fixedWeekdayIsDue() {
        let tuesdayHabit = habit(id: 1, frequency: .fixedDaysInWeek, detail: "3")
        let due = HabitSchedule.habitsDue(on: tuesday, habits: [tuesdayHabit], checkIns: [], calendar: calendar)
        #expect(due.map(\.habit.id) == [1])
        #expect(due.first?.isCompleted == false)
        // Fixed-day habits carry no running total; there is nothing to count towards.
        #expect(due.first?.frequencyDescription == nil)
    }

    @Test("A habit set for other days is not due")
    func fixedWeekdayNotDue() {
        let mondayHabit = habit(id: 1, frequency: .fixedDaysInWeek, detail: "2")
        let due = HabitSchedule.habitsDue(on: tuesday, habits: [mondayHabit], checkIns: [], calendar: calendar)
        #expect(due.isEmpty)
    }

    @Test("A habit with no days set is never due, rather than due every day")
    func fixedWeekdayWithNoDays() {
        let unscheduled = habit(id: 1, frequency: .fixedDaysInWeek, detail: "")
        #expect(HabitSchedule.habitsDue(on: tuesday, habits: [unscheduled], checkIns: [], calendar: calendar).isEmpty)
    }

    @Test("A check-in on the day marks it complete, at any hour")
    func fixedWeekdayCompleted() {
        let tuesdayHabit = habit(id: 1, frequency: .fixedDaysInWeek, detail: "3")
        let due = HabitSchedule.habitsDue(
            on: tuesday,
            habits: [tuesdayHabit],
            checkIns: [checkIn(1, "2026-08-25 23:30", habitID: 1)],
            calendar: calendar
        )
        #expect(due.first?.isCompleted == true)
    }

    @Test("A check-in on a neighbouring day does not count")
    func fixedWeekdayNotCompletedByAnotherDay() {
        let tuesdayHabit = habit(id: 1, frequency: .fixedDaysInWeek, detail: "3")
        let due = HabitSchedule.habitsDue(
            on: tuesday,
            habits: [tuesdayHabit],
            checkIns: [checkIn(1, "2026-08-24 23:59", habitID: 1)],
            calendar: calendar
        )
        #expect(due.first?.isCompleted == false)
    }

    @Test("Another habit's check-in does not complete this one")
    func checkInsAreScopedToTheirHabit() {
        let mine = habit(id: 1, frequency: .fixedDaysInWeek, detail: "3")
        let due = HabitSchedule.habitsDue(
            on: tuesday,
            habits: [mine],
            checkIns: [checkIn(1, "2026-08-25", habitID: 2)],
            calendar: calendar
        )
        #expect(due.first?.isCompleted == false)
    }

    // MARK: - Fixed days of the month

    @Test("A habit set for the 25th is due on the 25th and not the 24th")
    func fixedMonthDay() {
        let monthly = habit(id: 1, frequency: .fixedDaysInMonth, detail: "25")
        #expect(HabitSchedule.habitsDue(on: tuesday, habits: [monthly], checkIns: [], calendar: calendar).count == 1)
        #expect(
            HabitSchedule
                .habitsDue(on: testDate("2026-08-24"), habits: [monthly], checkIns: [], calendar: calendar)
                .isEmpty
        )
    }

    // MARK: - A quota each week

    @Test("A weekly quota stays on the list until it is met")
    func weeklyQuotaOutstanding() {
        let threeAWeek = habit(id: 1, frequency: .nDaysEachWeek, detail: "3")
        let due = HabitSchedule.habitsDue(
            on: tuesday,
            habits: [threeAWeek],
            checkIns: [checkIn(1, "2026-08-24", habitID: 1)],
            calendar: calendar
        )
        #expect(due.count == 1)
        #expect(due.first?.frequencyDescription == String(localized: "\(1)/\(3) this week"))
    }

    @Test("A met weekly quota drops off the list")
    func weeklyQuotaMet() {
        let twoAWeek = habit(id: 1, frequency: .nDaysEachWeek, detail: "2")
        let due = HabitSchedule.habitsDue(
            on: testDate("2026-08-26"),
            habits: [twoAWeek],
            checkIns: [
                checkIn(1, "2026-08-24", habitID: 1),
                checkIn(2, "2026-08-25", habitID: 1),
            ],
            calendar: calendar
        )
        #expect(due.isEmpty)
    }

    @Test("A habit done today stays visible even once its quota is met")
    func weeklyQuotaMetToday() {
        let twoAWeek = habit(id: 1, frequency: .nDaysEachWeek, detail: "2")
        let due = HabitSchedule.habitsDue(
            on: tuesday,
            habits: [twoAWeek],
            checkIns: [
                checkIn(1, "2026-08-24", habitID: 1),
                checkIn(2, "2026-08-25", habitID: 1),
            ],
            calendar: calendar
        )
        #expect(due.count == 1)
        #expect(due.first?.isCompleted == true)
    }

    @Test("The running total counts only up to today, not the rest of the week")
    func weeklyTotalStopsAtToday() {
        let fiveAWeek = habit(id: 1, frequency: .nDaysEachWeek, detail: "5")
        let due = HabitSchedule.habitsDue(
            on: tuesday,
            habits: [fiveAWeek],
            checkIns: [
                checkIn(1, "2026-08-24", habitID: 1),
                checkIn(2, "2026-08-25", habitID: 1),
                // Dated later this week, so not yet part of "so far".
                checkIn(3, "2026-08-28", habitID: 1),
            ],
            calendar: calendar
        )
        #expect(due.first?.frequencyDescription == String(localized: "\(2)/\(5) this week"))
    }

    @Test("Last week's check-ins do not count towards this week")
    func weeklyQuotaResetsEachWeek() {
        let twoAWeek = habit(id: 1, frequency: .nDaysEachWeek, detail: "2")
        let due = HabitSchedule.habitsDue(
            on: tuesday,
            habits: [twoAWeek],
            // The Monday-start week containing 25 Aug 2026 begins on 24 Aug.
            checkIns: [
                checkIn(1, "2026-08-22", habitID: 1),
                checkIn(2, "2026-08-23", habitID: 1),
            ],
            calendar: calendar
        )
        #expect(due.count == 1)
        #expect(due.first?.frequencyDescription == String(localized: "\(0)/\(2) this week"))
    }

    @Test("Where the week starts follows the user's setting")
    func weekStartFollowsThePreference() {
        let twoAWeek = habit(id: 1, frequency: .nDaysEachWeek, detail: "2")
        // Sunday 23 Aug is last week when weeks start on Monday, and this week when they
        // start on Sunday.
        let sundayCheckIn = [checkIn(1, "2026-08-23", habitID: 1)]

        let mondayStart = HabitSchedule.habitsDue(
            on: tuesday, habits: [twoAWeek], checkIns: sundayCheckIn, calendar: testCalendar(startWeekOnMonday: true)
        )
        let sundayStart = HabitSchedule.habitsDue(
            on: tuesday, habits: [twoAWeek], checkIns: sundayCheckIn, calendar: testCalendar(startWeekOnMonday: false)
        )

        #expect(mondayStart.first?.frequencyDescription == String(localized: "\(0)/\(2) this week"))
        #expect(sundayStart.first?.frequencyDescription == String(localized: "\(1)/\(2) this week"))
    }

    // MARK: - A quota each month

    @Test("A monthly quota counts within the month and reports its total")
    func monthlyQuota() {
        let fourAMonth = habit(id: 1, frequency: .nDaysEachMonth, detail: "4")
        let due = HabitSchedule.habitsDue(
            on: tuesday,
            habits: [fourAMonth],
            checkIns: [
                checkIn(1, "2026-07-31", habitID: 1),
                checkIn(2, "2026-08-03", habitID: 1),
                checkIn(3, "2026-08-19", habitID: 1),
            ],
            calendar: calendar
        )
        #expect(due.first?.frequencyDescription == String(localized: "\(2)/\(4) this month"))
    }

    // MARK: - Ordering and mixtures

    @Test("Habits come back in the order they were given")
    func orderIsPreserved() {
        let habits = [
            habit(id: 7, frequency: .fixedDaysInWeek, detail: "3"),
            habit(id: 2, frequency: .nDaysEachWeek, detail: "5"),
            habit(id: 5, frequency: .fixedDaysInMonth, detail: "25"),
        ]
        let due = HabitSchedule.habitsDue(on: tuesday, habits: habits, checkIns: [], calendar: calendar)
        #expect(due.map(\.habit.id) == [7, 2, 5])
    }

    @Test("Nothing is due when there are no habits")
    func noHabits() {
        #expect(HabitSchedule.habitsDue(on: tuesday, habits: [], checkIns: [], calendar: calendar).isEmpty)
    }
}
