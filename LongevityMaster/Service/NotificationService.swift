//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import UserNotifications
import SQLiteData

@Observable
class NotificationService {
    static let shared = NotificationService()

    private init() {}

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func printAllNotifications() async {
        let notifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
        for notification in notifications {
            print("Notification ID: \(notification.identifier)")
            if let content = notification.content as? UNMutableNotificationContent {
                print("Title: \(content.title)")
                print("Body: \(content.body)")
                print("Trigger: \(String(describing: notification.trigger))")
            }
        }
    }
        

    // MARK: - Reminder Management

    func scheduleReminder(_ reminder: Reminder) async {
        // Remove existing notifications first
        removeReminder(reminder)

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default

        let schedule = notificationSchedule(for: reminder)
        for entry in schedule {
            let trigger = UNCalendarNotificationTrigger(dateMatching: entry.dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: entry.id,
                content: content,
                trigger: trigger
            )
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Failed to schedule notification \(entry.id): \(error)")
            }
        }
        print("Scheduled \(schedule.count) notification(s) for reminder: \(reminder.id)")
    }

    /// A reminder attached to a habit should only fire on the days that habit is actually
    /// scheduled — nagging every morning about a Mon/Wed/Fri habit trains people to ignore it.
    /// Habits with an "n days per week/month" target can be done on any day, so those, and
    /// reminders not attached to a habit at all, stay daily.
    private func notificationSchedule(for reminder: Reminder) -> [(id: String, dateComponents: DateComponents)] {
        let time = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
        let daily = [(id: reminder.notificationID, dateComponents: time)]

        guard let habitID = reminder.habitID,
              let habit = habit(withID: habitID)
        else { return daily }

        switch habit.frequency {
        case .fixedDaysInWeek:
            let days = habit.daysOfWeek.sorted()
            // Every day of the week is just a daily reminder, in one request instead of seven.
            guard !days.isEmpty, days.count < 7 else { return daily }
            return days.map { weekday in
                var components = time
                components.weekday = weekday
                return (id: "\(reminder.notificationID)-w\(weekday)", dateComponents: components)
            }
        case .fixedDaysInMonth:
            let days = habit.daysOfMonth.sorted()
            guard !days.isEmpty else { return daily }
            return days.map { day in
                var components = time
                components.day = day
                return (id: "\(reminder.notificationID)-d\(day)", dateComponents: components)
            }
        case .nDaysEachWeek, .nDaysEachMonth:
            return daily
        }
    }

    private func habit(withID id: Habit.ID) -> Habit? {
        @Dependency(\.defaultDatabase) var database
        return withErrorReporting {
            try database.read { db in
                try Habit.find(id).fetchOne(db)
            }
        } ?? nil
    }

    /// One reminder can own several requests depending on its habit's schedule, and that
    /// schedule may have changed since they were registered, so clear every id it could hold.
    private func notificationIdentifiers(for reminder: Reminder) -> [String] {
        var identifiers = [reminder.notificationID]
        identifiers += (1 ... 7).map { "\(reminder.notificationID)-w\($0)" }
        identifiers += (1 ... 31).map { "\(reminder.notificationID)-d\($0)" }
        return identifiers
    }

    func removeReminder(_ reminder: Reminder) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: notificationIdentifiers(for: reminder))
        print("Removed notifications for reminder: \(reminder.id)")
    }
    
    func removeRemindersForHabit(_ habitID: Int) {
        withErrorReporting {
            @Dependency(\.defaultDatabase) var database
            let reminders = try database.read { db in
                try Reminder
                    .where { $0.habitID.eq(habitID) }
                    .fetchAll(db)
            }
            
            for reminder in reminders {
                removeReminder(reminder)
            }
            
            print("Removed notifications for \(reminders.count) reminders associated with habit ID: \(habitID)")
        }
    }

    func removeAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Removed all pending notifications")
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    func createDefaultDailyReminder() -> Reminder.Draft {
        let defaultTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        return Reminder.Draft(time: defaultTime)
    }

    // MARK: - Permission Status
    
    enum NotificationAuthorizationStatus {
        case notDetermined, denied, authorized, provisional, ephemeral
    }
    
    func getAuthorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        @unknown default:
            return .notDetermined
        }
    }
}

// Dependency injection
extension DependencyValues {
    var notificationService: NotificationService {
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }
}

private enum NotificationServiceKey: DependencyKey {
    static let liveValue = NotificationService.shared
}
