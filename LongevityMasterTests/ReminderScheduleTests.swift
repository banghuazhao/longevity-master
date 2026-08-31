//
// Created by Banghua Zhao on 31/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

/// A reminder that fires at 8pm about something done at 7am is the reason people turn
/// notifications off. These are the rules that decide when it stays quiet.
@Suite("What a reminder registers")
struct ReminderScheduleTests {
    private let calendar = testCalendar()

    /// 2026-08-25 is a Tuesday. `weekday` 3 in Calendar's numbering.
    private let tuesdayMorning = testDate("2026-08-25 09:00")

    private func eightInTheEvening() -> DateComponents {
        DateComponents(hour: 20, minute: 0)
    }

    private func requests(
        days: NotificationService.ReminderDays = .everyDay,
        isSatisfiedToday: Bool,
        now: Date? = nil
    ) -> [NotificationService.ReminderRequest] {
        NotificationService.requests(
            notificationID: "reminder_1",
            time: eightInTheEvening(),
            days: days,
            isSatisfiedToday: isSatisfiedToday,
            now: now ?? tuesdayMorning,
            calendar: calendar
        )
    }

    // MARK: - Stepping over a slot already settled

    @Test("With something still to do, the reminder repeats as normal")
    func outstandingWorkKeepsTheRepeatingTrigger() {
        let result = requests(isSatisfiedToday: false)
        #expect(result == [
            .init(id: "reminder_1", trigger: .repeating(DateComponents(hour: 20, minute: 0)))
        ])
    }

    @Test("Already done, and tonight's slot still ahead: it fires tomorrow instead")
    func settledTodayStepsOverTonight() {
        let result = requests(isSatisfiedToday: true)
        #expect(result.count == 1)
        #expect(result.first?.id == "reminder_1")
        #expect(
            result.first?.trigger
                == .once(DateComponents(year: 2026, month: 8, day: 26, hour: 20, minute: 0))
        )
    }

    @Test("Already done, but the slot has passed: nothing left to suppress")
    func settledAfterTheSlotHasPassedKeepsRepeating() {
        let result = requests(isSatisfiedToday: true, now: testDate("2026-08-25 21:30"))
        #expect(result == [
            .init(id: "reminder_1", trigger: .repeating(DateComponents(hour: 20, minute: 0)))
        ])
    }

    // MARK: - Which days a reminder is due on

    @Test("A habit on three days of the week gets one request per day")
    func fixedWeekdaysGetOneRequestEach() {
        // Monday, Wednesday, Friday.
        let result = requests(days: .weekdays([2, 4, 6]), isSatisfiedToday: false)
        #expect(result.map(\.id) == ["reminder_1-w2", "reminder_1-w4", "reminder_1-w6"])
        #expect(result.allSatisfy {
            if case let .repeating(components) = $0.trigger { return components.hour == 20 }
            return false
        })
    }

    @Test("Every day of the week is one daily request, not seven")
    func sevenWeekdaysCollapseToOneRequest() {
        let result = requests(days: .weekdays([1, 2, 3, 4, 5, 6, 7]), isSatisfiedToday: false)
        #expect(result == [
            .init(id: "reminder_1", trigger: .repeating(DateComponents(hour: 20, minute: 0)))
        ])
    }

    @Test("Only the slot due today is stepped over; the rest keep repeating")
    func onlyTodaysSlotIsSteppedOver() {
        // Tuesday is weekday 3, and today is a Tuesday.
        let result = requests(days: .weekdays([2, 3, 5]), isSatisfiedToday: true)
        #expect(result.count == 3)

        let tuesday = result.first { $0.id == "reminder_1-w3" }
        // A week on: 2026-09-01.
        #expect(
            tuesday?.trigger
                == .once(DateComponents(year: 2026, month: 9, day: 1, hour: 20, minute: 0))
        )

        let others = result.filter { $0.id != "reminder_1-w3" }
        #expect(others.allSatisfy {
            if case .repeating = $0.trigger { return true }
            return false
        })
    }

    @Test("A habit on fixed days of the month gets one request per day")
    func fixedMonthDaysGetOneRequestEach() {
        let result = requests(days: .monthDays([1, 15]), isSatisfiedToday: false)
        #expect(result.map(\.id) == ["reminder_1-d1", "reminder_1-d15"])
    }

    @Test("A habit with no days set still reminds daily rather than never")
    func noDaysSetFallsBackToDaily() {
        #expect(requests(days: .weekdays([]), isSatisfiedToday: false).map(\.id) == ["reminder_1"])
        #expect(requests(days: .monthDays([]), isSatisfiedToday: false).map(\.id) == ["reminder_1"])
    }

    // MARK: - Identifiers

    @Test("The ids match the ones removal clears, so nothing is left stranded")
    func idsMatchTheRemovalPattern() {
        let result = requests(days: .weekdays([2, 4]), isSatisfiedToday: false)
        let cleared = ["reminder_1"]
            + (1 ... 7).map { "reminder_1-w\($0)" }
            + (1 ... 31).map { "reminder_1-d\($0)" }
        #expect(result.allSatisfy { cleared.contains($0.id) })
    }
}
