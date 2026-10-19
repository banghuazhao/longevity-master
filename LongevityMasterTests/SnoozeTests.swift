//
// Created by Banghua Zhao on 20/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
import UserNotifications
@testable import LongevityMaster

@Suite("Snoozing a reminder")
struct SnoozeTests {
    private func reminder(id: String = "reminder_1-w3", habitID: Int? = 7) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Walk"
        content.userInfo = [NotificationService.reminderKey: "reminder_1"]
        if let habitID {
            content.userInfo[NotificationService.habitIDKey] = habitID
            content.categoryIdentifier = NotificationService.habitReminderCategory
        }
        return UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 20, minute: 0), repeats: true)
        )
    }

    @Test("A snooze is the same notification an hour later, one per reminder")
    func snoozeRequest() throws {
        let delivered = testDate("2026-10-20 20:00")
        let snoozed = try #require(NotificationService.snoozeRequest(for: reminder(), deliveredAt: delivered))
        #expect(snoozed.identifier == "snooze_reminder_1")
        #expect(snoozed.content.title == "Walk")
        #expect(snoozed.content.categoryIdentifier == NotificationService.habitReminderCategory)
        #expect(snoozed.content.userInfo[NotificationService.habitIDKey] as? Int == 7)
        #expect((snoozed.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval == 3600)
        #expect(snoozed.content.userInfo[NotificationService.firstDeliveredKey] as? TimeInterval == delivered.timeIntervalSince1970)
    }

    @Test("Snoozing a snooze keeps the time the reminder first came")
    func snoozeAgain() throws {
        let first = try #require(NotificationService.snoozeRequest(for: reminder(), deliveredAt: testDate("2026-10-20 20:00")))
        let second = try #require(NotificationService.snoozeRequest(for: first, deliveredAt: testDate("2026-10-20 21:00")))
        #expect(second.identifier == first.identifier)
        #expect(second.content.userInfo[NotificationService.firstDeliveredKey] as? TimeInterval == testDate("2026-10-20 20:00").timeIntervalSince1970)
    }

    @Test("Mark as Done on a snooze that arrives after midnight files the day the reminder was about")
    func markDoneAfterMidnight() throws {
        let calendar = testCalendar()
        let snoozed = try #require(NotificationService.snoozeRequest(for: reminder(), deliveredAt: testDate("2026-10-20 23:30")))
        let checkIn = try #require(NotificationService.markDoneCheckIn(
            userInfo: snoozed.content.userInfo,
            deliveredAt: testDate("2026-10-21 00:30"),
            now: testDate("2026-10-21 00:35"),
            calendar: calendar
        ))
        #expect(checkIn.habitID == 7)
        #expect(calendar.isDate(checkIn.date, inSameDayAs: testDate("2026-10-20")))
    }

    @Test("A reminder from before this version still snoozes, under its own id")
    func legacyReminder() throws {
        let content = UNMutableNotificationContent()
        content.title = "Time to check in"
        let old = UNNotificationRequest(identifier: "reminder_9", content: content, trigger: nil)
        let snoozed = try #require(NotificationService.snoozeRequest(for: old, deliveredAt: Date()))
        #expect(snoozed.identifier == "snooze_reminder_9")
    }
}
