//
// Created by Banghua Zhao on 03/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

/// The week under test runs Monday 2026-09-21 to Sunday 2026-09-27.
@Suite("Weekly review")
struct WeeklyReviewTests {
    let calendar = testCalendar()

    private func habit(_ id: Int, frequency: HabitFrequency = .fixedDaysInWeek, detail: String = "1,2,3,4,5,6,7") -> Habit {
        Habit(id: id, name: "Habit \(id)", frequency: frequency, frequencyDetail: detail)
    }

    private func checkIns(_ habitID: Int, _ days: [String]) -> [CheckIn] {
        days.enumerated().map { index, day in
            CheckIn(id: habitID * 1000 + index, date: testDate(day + " 09:00"), habitID: habitID)
        }
    }

    private func review(
        week: String = "2026-09-23",
        now: String = "2026-10-01 12:00",
        habits: [Habit],
        checkIns: [CheckIn],
        skippedDays: [SkippedDay] = []
    ) -> WeeklyReview {
        WeeklyReview.make(
            weekContaining: testDate(week),
            now: testDate(now),
            habits: habits,
            checkIns: checkIns,
            skippedDays: skippedDays,
            calendar: calendar
        )
    }

    /// Check-ins the week before, so a habit counts as existing for the whole week under test.
    private let history = ["2026-09-14"]

    @Test("A past week is judged on every day of it")
    func pastWeek() {
        let result = review(
            habits: [habit(1)],
            checkIns: checkIns(1, history + ["2026-09-21", "2026-09-22", "2026-09-23", "2026-09-24", "2026-09-25"])
        )
        #expect(result.weekStart == testDate("2026-09-21"))
        #expect(result.weekEnd == testDate("2026-09-27"))
        #expect(!result.isCurrentWeek)
        #expect(result.adherencePercent == 71)
        #expect(result.checkInCount == 5)
        #expect(result.activeDayCount == 5)
        #expect(result.days.map(\.checkInCount) == [1, 1, 1, 1, 1, 0, 0])
    }

    @Test("A habit first done mid-week is judged from that day")
    func firstCheckInStartsTheClock() {
        let result = review(
            habits: [habit(1)],
            checkIns: checkIns(1, ["2026-09-24", "2026-09-25", "2026-09-26", "2026-09-27"])
        )
        #expect(result.adherencePercent == 100)
    }

    @Test("A habit never checked in is judged only in the week under way")
    func neverCheckedIn() {
        let past = review(habits: [habit(1)], checkIns: [])
        #expect(past.adherence == nil)
        #expect(past.habits.isEmpty)

        let current = review(week: "2026-09-23", now: "2026-09-24 12:00", habits: [habit(1)], checkIns: [])
        #expect(current.habits.count == 1)
        // Monday to Wednesday are settled and missed; Thursday is not over yet.
        #expect(current.adherence == 0)
    }

    @Test("Rest days owe nothing")
    func restDays() {
        let result = review(
            habits: [habit(1)],
            checkIns: checkIns(1, history + ["2026-09-21", "2026-09-22", "2026-09-24", "2026-09-25", "2026-09-26", "2026-09-27"]),
            skippedDays: [SkippedDay(id: 1, date: testDate("2026-09-23"), habitID: nil)]
        )
        #expect(result.adherencePercent == 100)
        #expect(result.days[2].isRestDay)
    }

    @Test("In the week under way, today counts only once it is done, and later days not at all")
    func currentWeek() {
        let notYet = review(
            now: "2026-09-23 12:00",
            habits: [habit(1)],
            checkIns: checkIns(1, history + ["2026-09-21", "2026-09-22"])
        )
        #expect(notYet.isCurrentWeek)
        #expect(notYet.adherencePercent == 100)
        #expect(notYet.days.map(\.isFuture) == [false, false, false, true, true, true, true])

        let doneToday = review(
            now: "2026-09-23 12:00",
            habits: [habit(1)],
            checkIns: checkIns(1, history + ["2026-09-21", "2026-09-23"])
        )
        #expect(doneToday.adherencePercent == 67)
    }

    @Test("A weekly quota met in full is on track")
    func quota() {
        let result = review(
            habits: [habit(1, frequency: .nDaysEachWeek, detail: "3")],
            checkIns: checkIns(1, history + ["2026-09-21", "2026-09-23", "2026-09-26"])
        )
        #expect(result.adherencePercent == 100)
    }

    @Test("Habits are added up by what they owe, not averaged")
    func weighting() {
        // A daily habit done every day, and a Monday-only habit missed: 7 of 8.
        let result = review(
            habits: [habit(1), habit(2, detail: "2")],
            checkIns: checkIns(1, history + ["2026-09-21", "2026-09-22", "2026-09-23", "2026-09-24", "2026-09-25", "2026-09-26", "2026-09-27"])
                + checkIns(2, ["2026-09-14"])
        )
        #expect(result.adherencePercent == 88)
        #expect(result.strongest.map(\.habit.id) == [1])
        #expect(result.needsAttention.map(\.habit.id) == [2])
    }

    @Test("The change is measured against the week before")
    func change() {
        let result = review(
            habits: [habit(1)],
            checkIns: checkIns(1, ["2026-09-14", "2026-09-15", "2026-09-16", "2026-09-17", "2026-09-18", "2026-09-19", "2026-09-20"]
                + ["2026-09-21", "2026-09-22", "2026-09-23", "2026-09-24", "2026-09-25"])
        )
        #expect(result.previousAdherence == 1)
        #expect(result.change == -29)
    }

    @Test("Archived habits are left out")
    func archived() {
        var archived = habit(2)
        archived.isArchived = true
        let result = review(
            habits: [habit(1), archived],
            checkIns: checkIns(1, history + ["2026-09-21"]) + checkIns(2, history + ["2026-09-21", "2026-09-22"])
        )
        #expect(result.habits.map(\.habit.id) == [1])
        #expect(result.checkInCount == 1)
    }

    @Test("The week ends on the day before it starts again")
    func lastWeekday() {
        #expect(WeeklyReview.lastWeekday(of: testCalendar(startWeekOnMonday: true)) == 1)
        #expect(WeeklyReview.lastWeekday(of: testCalendar(startWeekOnMonday: false)) == 7)
    }

    @Test("The first day of a week reviews the week just ended; any other day, the one under way")
    func defaultWeek() {
        #expect(WeeklyReview.defaultWeek(now: testDate("2026-09-28 08:00"), calendar: calendar) == testDate("2026-09-21"))
        #expect(WeeklyReview.defaultWeek(now: testDate("2026-09-27 19:00"), calendar: calendar) == testDate("2026-09-21"))
        #expect(WeeklyReview.defaultWeek(now: testDate("2026-09-24 08:00"), calendar: calendar) == testDate("2026-09-21"))
    }
}

@Suite("Program recommendations")
struct ProgramRecommendationTests {
    private func program(_ id: String, _ categories: [HabitCategory]) -> Program {
        Program(
            id: id,
            title: id,
            subtitle: "",
            icon: "🎯",
            color: 0,
            durationDays: 21,
            summary: "",
            weeklyFocus: [],
            habits: categories.enumerated().map { index, category in
                testHabitDraft(name: "\(id) \(index)", category: category)
            },
            sources: []
        )
    }

    private var catalog: [Program] {
        [
            program("sleep-a", [.sleep, .sleep]),
            program("sleep-b", [.sleep, .mentalHealth, .sleep]),
            program("diet", [.diet, .diet, .exercise]),
            program("strength", [.exercise]),
            program("calm", [.mentalHealth]),
        ]
    }

    @Test("The primary category is the most common one, the first habit's on a tie")
    func primaryCategory() {
        #expect(program("x", [.diet, .exercise, .exercise]).primaryCategory == .exercise)
        #expect(program("x", [.diet, .exercise]).primaryCategory == .diet)
        #expect(program("x", []).primaryCategory == nil)
    }

    @Test("Suggests a different area of health first, and never the one just finished")
    func differentArea() {
        let next = ProgramRecommendations.next(
            after: catalog[0],
            activeProgramIDs: [],
            completedProgramIDs: ["sleep-a"],
            catalog: catalog,
            limit: 10
        )
        #expect(next.map(\.id) == ["diet", "strength", "calm", "sleep-b"])
    }

    @Test("Leaves out programs under way, and steers clear of their area")
    func activePrograms() {
        let next = ProgramRecommendations.next(
            after: catalog[0],
            activeProgramIDs: ["diet"],
            completedProgramIDs: [],
            catalog: catalog,
            limit: 10
        )
        #expect(next.map(\.id) == ["strength", "calm", "sleep-b"])
    }

    @Test("Programs already completed come after ones not yet tried")
    func completedLast() {
        let next = ProgramRecommendations.next(
            after: catalog[0],
            activeProgramIDs: [],
            completedProgramIDs: ["diet", "strength"],
            catalog: catalog
        )
        #expect(next.map(\.id) == ["calm", "sleep-b"])
    }
}

@Suite("Notification routing")
struct NotificationRoutingTests {
    @Test("A weekly review notification opens the week it was delivered in")
    func weeklyReview() {
        let delivered = testDate("2026-09-27 19:00")
        let destination = AppRouter.destination(
            userInfo: [AppRouter.NotificationKey.destination: AppRouter.NotificationKey.weeklyReview],
            deliveredAt: delivered
        )
        #expect(destination == .weeklyReview(weekOf: delivered))
    }

    @Test("A program-complete notification opens that run")
    func programCompletion() {
        let destination = AppRouter.destination(
            userInfo: [
                AppRouter.NotificationKey.destination: AppRouter.NotificationKey.programCompletion,
                AppRouter.NotificationKey.enrollmentID: 7,
            ],
            deliveredAt: Date()
        )
        #expect(destination == .programCompletion(enrollmentID: 7))
    }

    @Test("A reminder leads nowhere in particular")
    func reminder() {
        #expect(AppRouter.destination(userInfo: [:], deliveredAt: Date()) == nil)
        #expect(AppRouter.destination(
            userInfo: [AppRouter.NotificationKey.destination: AppRouter.NotificationKey.programCompletion],
            deliveredAt: Date()
        ) == nil)
    }
}
