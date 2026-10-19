//
// Created by Banghua Zhao on 19/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Testing
import UserNotifications
@testable import LongevityMaster

/// iOS keeps 64 pending notifications per app and drops the rest without a word. These are
/// the rules for which ones the app keeps when it has more than that to register.
@Suite("Staying within the notification limit")
struct NotificationLimitTests {
    /// Far enough ahead that every trigger here is still to come whenever the tests run.
    private func once(_ id: String, daysAhead: Int) -> UNNotificationRequest {
        let date = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date())!
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNNotificationRequest(
            identifier: id,
            content: UNMutableNotificationContent(),
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }

    @Test("Within the limit, everything is kept in its own order")
    func underLimit() {
        let requests = (1...10).map { once("r\($0)", daysAhead: 11 - $0) }
        let kept = NotificationService.soonestFirst(requests, limit: NotificationService.pendingLimit)
        #expect(kept.count == 10)
        #expect(Set(kept.map(\.identifier)) == Set(requests.map(\.identifier)))
    }

    @Test("Over the limit, the ones that fire soonest are kept")
    func overLimit() {
        // Ninety one-offs, registered furthest first, the way a long list of reminders can be.
        let requests = (1...90).reversed().map { once("d\($0)", daysAhead: $0) }
        let kept = NotificationService.soonestFirst(requests, limit: NotificationService.pendingLimit)
        #expect(kept.map(\.identifier) == (1...64).map { "d\($0)" })
    }

    @Test("A repeating reminder due this week beats one-offs months away")
    func repeatingSoonWins() {
        var requests = (1...64).map { once("later\($0)", daysAhead: 60 + $0) }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        requests.append(UNNotificationRequest(
            identifier: "weekly",
            content: UNMutableNotificationContent(),
            trigger: UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: 19, minute: 0, weekday: Calendar.current.component(.weekday, from: tomorrow)),
                repeats: true
            )
        ))
        let kept = NotificationService.soonestFirst(requests, limit: NotificationService.pendingLimit)
        #expect(kept.first?.identifier == "weekly")
        #expect(!kept.contains { $0.identifier == "later64" })
    }

    @Test("A request that can never fire again goes last")
    func pastGoesLast() {
        let past = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date(timeIntervalSinceNow: -86_400 * 30))
        let spent = UNNotificationRequest(
            identifier: "spent",
            content: UNMutableNotificationContent(),
            trigger: UNCalendarNotificationTrigger(dateMatching: past, repeats: false)
        )
        let kept = NotificationService.soonestFirst([spent, once("soon", daysAhead: 2)], limit: 1)
        #expect(kept.map(\.identifier) == ["soon"])
    }
}
