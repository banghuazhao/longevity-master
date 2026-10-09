//
// Created by Banghua Zhao on 10/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
@testable import LongevityMaster

/// The "Mark as Done" button on a habit's reminder. Notifications cannot be driven in the
/// simulator, so the decision behind the button is tested on its own.
@Suite("Marking a habit done from its reminder")
struct MarkDoneActionTests {
    private let calendar = testCalendar()

    @Test("Pressed the day it arrived, it carries the time it was pressed")
    func sameDay() {
        let checkIn = NotificationService.markDoneCheckIn(
            userInfo: [NotificationService.habitIDKey: 4],
            deliveredAt: testDate("2026-10-10 07:00"),
            now: testDate("2026-10-10 07:05"),
            calendar: calendar
        )
        #expect(checkIn?.habitID == 4)
        #expect(checkIn?.date == testDate("2026-10-10 07:05"))
    }

    @Test("Pressed after midnight, it still files the day the reminder was about")
    func nextDay() {
        let checkIn = NotificationService.markDoneCheckIn(
            userInfo: [NotificationService.habitIDKey: 4],
            deliveredAt: testDate("2026-10-10 21:00"),
            now: testDate("2026-10-11 00:30"),
            calendar: calendar
        )
        #expect(checkIn?.date == testDate("2026-10-10 21:00"))
    }

    @Test("A reminder without a habit has nothing to mark done")
    func generalReminder() {
        let checkIn = NotificationService.markDoneCheckIn(
            userInfo: [:],
            deliveredAt: testDate("2026-10-10 21:00"),
            now: testDate("2026-10-10 21:00"),
            calendar: calendar
        )
        #expect(checkIn == nil)
    }
}
