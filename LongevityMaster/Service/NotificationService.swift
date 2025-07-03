//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import UserNotifications
import SharingGRDB

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
        // Remove existing notification first
        removeReminder(reminder)

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default

        await scheduleDailyReminder(reminder, content: content)
    }

    private func scheduleDailyReminder(_ reminder: Reminder, content: UNNotificationContent) async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: reminder.notificationID,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled daily notification for reminder: \(reminder.id)")
        } catch {
            print("Failed to schedule daily notification: \(error)")
        }
    }

    func removeReminder(_ reminder: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.notificationID])
        print("Removed notification for reminder: \(reminder.id)")
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
