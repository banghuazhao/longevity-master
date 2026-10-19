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

    /// Set at launch when the database could not be opened. The app is then running on an
    /// empty stand-in, and re-deriving the reminders from that would remove every one of them,
    /// so nothing here touches the notification centre for the rest of the run.
    var isSuspended = false

    /// iOS keeps at most this many pending notifications for an app and silently drops the
    /// rest. A reminder on a habit with set days of the month registers one per day, so a
    /// few of those were enough to lose reminders — including ones due tomorrow — without
    /// any sign of it. `syncAllReminders()` registers only this many, soonest first.
    static let pendingLimit = 64

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            debugLog("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    /// Dumps the pending reminder schedule while developing. Release skips the fetch as well
    /// as the output: it runs at launch, and nobody is reading the result.
    func printAllNotifications() async {
        #if DEBUG
            let notifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            for notification in notifications {
                debugLog("Notification ID: \(notification.identifier)")
                if let content = notification.content as? UNMutableNotificationContent {
                    debugLog("Title: \(content.title)")
                    debugLog("Body: \(content.body)")
                    debugLog("Trigger: \(String(describing: notification.trigger))")
                }
            }
        #endif
    }
        

    // MARK: - Reminder Management

    /// Registers everything `reminder` should fire, replacing whatever it had registered
    /// before. Safe to call as often as you like — the result depends only on the reminder,
    /// its habit's schedule, and what is still outstanding today, so re-running it just
    /// brings the notification centre back in line.
    ///
    /// This is the quick path for a reminder just edited, and does not count against
    /// `pendingLimit`; the next `syncAllReminders()` puts the whole set back within it.
    func scheduleReminder(_ reminder: Reminder) async {
        guard !isSuspended else { return }
        // Remove existing notifications first
        removeReminder(reminder)

        let schedule = requests(for: reminder, now: Date(), calendar: .current)
        for request in schedule {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                debugLog("Failed to schedule notification \(request.identifier): \(error)")
            }
        }
        debugLog("Scheduled \(schedule.count) notification(s) for reminder: \(reminder.id)")
    }

    /// What `reminder` should have registered right now.
    private func requests(for reminder: Reminder, now: Date, calendar: Calendar) -> [UNNotificationRequest] {
        // An archived habit is off the Today list, so its reminder has nothing to ask for.
        // Unarchiving it and the next sync bring the reminder back.
        if let habitID = reminder.habitID, habit(withID: habitID)?.isArchived == true {
            return []
        }

        let content = UNMutableNotificationContent()
        content.title = reminder.displayTitle
        content.body = reminder.displayBody
        content.sound = .default
        if let habitID = reminder.habitID {
            content.categoryIdentifier = Self.habitReminderCategory
            content.userInfo = [Self.habitIDKey: habitID]
        }

        let schedule = Self.requests(
            notificationID: reminder.notificationID,
            time: calendar.dateComponents([.hour, .minute], from: reminder.time),
            days: days(for: reminder),
            isSatisfiedToday: isSatisfiedToday(reminder, now: now, calendar: calendar),
            now: now,
            calendar: calendar
        )

        return schedule.map { entry in
            let trigger = switch entry.trigger {
            case let .repeating(components):
                UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            case let .once(components):
                UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            }
            return UNNotificationRequest(identifier: entry.id, content: content, trigger: trigger)
        }
    }

    /// Re-derives every reminder's schedule. Call this after anything that changes whether a
    /// reminder still has something to ask for — a check-in, a rest day, coming back to the
    /// foreground on a new day.
    ///
    /// This is also what restores a slot that was stepped over: a one-off request is spent
    /// once it fires, and the next sync registers the repeating one again.
    ///
    /// Works out every notification the app should have pending — reminders, the weekly
    /// review, program completions — and registers the `pendingLimit` that fire soonest.
    /// Anything else still pending is removed, which also clears requests left behind by
    /// reminders that no longer exist, such as after restoring a backup. The ones left out
    /// come back as the sooner ones fire and the app re-syncs on its next trip to the
    /// foreground.
    func syncAllReminders() async {
        guard !isSuspended else { return }
        @Dependency(\.defaultDatabase) var database
        let now = Date()
        let calendar = Calendar.current

        // Without the reminders there is no knowing what should stay, so leave things as
        // they are rather than clearing out what may still be right.
        let reminders: [Reminder]
        do {
            reminders = try await database.read { db in try Reminder.all.fetchAll(db) }
        } catch {
            reportIssue(error)
            return
        }

        var planned = reminders.flatMap { requests(for: $0, now: now, calendar: calendar) }
        if let weeklyReview = weeklyReviewRequest() {
            planned.append(weeklyReview)
        }
        planned += programCompletionRequests(now: now)

        let kept = Self.soonestFirst(planned, limit: Self.pendingLimit)
        let keptIDs = Set(kept.map(\.identifier))
        if kept.count < planned.count {
            debugLog("Registering \(kept.count) of \(planned.count) notifications, soonest first")
        }

        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { !keptIDs.contains($0) }
        )
        // Adding a request under an identifier already pending replaces it.
        for request in kept {
            do {
                try await center.add(request)
            } catch {
                debugLog("Failed to schedule notification \(request.identifier): \(error)")
            }
        }
    }

    /// The first `limit` of `requests` by when they next fire. A request that will never fire
    /// again goes last; ties keep their original order, so the result is stable.
    static func soonestFirst(_ requests: [UNNotificationRequest], limit: Int) -> [UNNotificationRequest] {
        let ranked = requests.enumerated().map { index, request in
            (index: index, request: request, next: (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate())
        }
        return ranked
            .sorted { lhs, rhs in
                switch (lhs.next, rhs.next) {
                case let (left?, right?) where left != right: return left < right
                case (.some, .none): return true
                case (.none, .some): return false
                default: return lhs.index < rhs.index
                }
            }
            .prefix(limit)
            .map(\.request)
    }

    // MARK: - Mark as done

    static let habitReminderCategory = "HABIT_REMINDER"
    static let markDoneAction = "MARK_DONE"
    static let habitIDKey = "habitID"

    /// The "Mark as Done" button on a habit's reminder. Registered at every launch: the
    /// category is looked up when a notification is shown, not when it was scheduled, and its
    /// title has to follow the app's language.
    static func registerNotificationActions() {
        let markDone = UNNotificationAction(
            identifier: markDoneAction,
            title: String(localized: "Mark as Done"),
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "checkmark.circle")
        )
        let category = UNNotificationCategory(
            identifier: habitReminderCategory,
            actions: [markDone],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Which habit a "Mark as Done" press checks in, and for which moment. The reminder is
    /// about the day it arrived on, so one answered after midnight still files yesterday's
    /// check-in; answered the same day, it carries the time it was pressed, as a tap on Today
    /// does, for the early-bird and night-owl achievements.
    static func markDoneCheckIn(
        userInfo: [AnyHashable: Any],
        deliveredAt delivered: Date,
        now: Date,
        calendar: Calendar
    ) -> (habitID: Habit.ID, date: Date)? {
        guard let habitID = userInfo[habitIDKey] as? Int else { return nil }
        let date = calendar.isDate(delivered, inSameDayAs: now) ? now : delivered
        return (habitID, date)
    }

    /// Checks the habit in without opening the app. Only ever checks in: pressing the button on
    /// a habit already done that day changes nothing. An archived or deleted habit is left
    /// alone, in case the notification outlived it.
    func markDone(habitID: Habit.ID, on date: Date) async {
        withErrorReporting {
            guard let habit = try WidgetDatabase.habits(ids: [habitID]).first, !habit.isArchived else { return }
            try WidgetDatabase.setCheckIn(habitID: habit.id, on: date, done: true)
        }
        // Wait for the reminders to settle before the system suspends the app again; the
        // sync `setCheckIn` starts is not awaited.
        await syncAllReminders()
    }

    // MARK: - Weekly review

    static let weeklyReviewEnabledKey = "weeklyReviewEnabled"
    static let weeklyReviewID = "weekly_review"

    /// On unless the user turned it off in Settings.
    static var isWeeklyReviewEnabled: Bool {
        UserDefaults.standard.object(forKey: weeklyReviewEnabledKey) as? Bool ?? true
    }

    /// One repeating notification at 7pm on the last day of the user's week, inviting them to
    /// look back at it. The text is deliberately free of figures: it is registered days before
    /// it fires, and any number in it would be out of date by then. The review it opens is
    /// worked out when it is read.
    func syncWeeklyReview() async {
        guard !isSuspended else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.weeklyReviewID])
        guard let request = weeklyReviewRequest() else { return }
        do {
            try await center.add(request)
        } catch {
            debugLog("Failed to schedule weekly review: \(error)")
        }
    }

    /// The weekly review's request, or `nil` when there should be none.
    private func weeklyReviewRequest() -> UNNotificationRequest? {
        guard Self.isWeeklyReviewEnabled else { return nil }

        @Dependency(\.defaultDatabase) var database
        let hasHabits = withErrorReporting {
            try database.read { db in
                try Habit.where { !$0.isArchived }.fetchCount(db) > 0
            }
        } ?? false
        // Nothing to look back on yet.
        guard hasHabits else { return nil }

        let startWeekOnMonday = UserDefaults.standard.object(forKey: "startWeekOnMonday") as? Bool ?? true
        let calendar = Calendar.userPreferred(startWeekOnMonday: startWeekOnMonday)

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Your week in review")
        content.body = String(localized: "See how your habits went this week, and pick one to focus on next.")
        content.sound = .default
        content.userInfo = [AppRouter.NotificationKey.destination: AppRouter.NotificationKey.weeklyReview]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: 19, minute: 0, weekday: WeeklyReview.lastWeekday(of: calendar)),
            repeats: true
        )
        return UNNotificationRequest(identifier: Self.weeklyReviewID, content: content, trigger: trigger)
    }

    // MARK: - Program completion

    private static let programCompletionPrefix = "program_complete_"

    /// A one-off notification the morning a program is over, for each run still under way.
    /// Re-derived from the enrollments every time, so leaving a program, or deleting the custom
    /// program behind it, takes its notification with it.
    func syncProgramCompletions(now: Date = Date()) async {
        guard !isSuspended else { return }
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.programCompletionPrefix) }
        )
        for request in programCompletionRequests(now: now) {
            do {
                try await center.add(request)
            } catch {
                debugLog("Failed to schedule program completion \(request.identifier): \(error)")
            }
        }
    }

    /// One request for each program run still under way.
    private func programCompletionRequests(now: Date) -> [UNNotificationRequest] {
        @Dependency(\.defaultDatabase) var database
        let runs = withErrorReporting {
            try database.read { db in
                (
                    try ProgramEnrollment.where { !$0.isArchived }.fetchAll(db),
                    try CustomProgram.all.fetchAll(db)
                )
            }
        }
        guard let runs else { return [] }
        let (enrollments, customPrograms) = runs
        let customByID = Dictionary(
            uniqueKeysWithValues: customPrograms.map { (Program.id(forCustom: $0.id), Program(custom: $0)) }
        )

        let calendar = Calendar.current
        return enrollments.compactMap { enrollment in
            guard let program = ProgramsDataStore.program(id: enrollment.programID) ?? customByID[enrollment.programID],
                  let finishDay = calendar.date(byAdding: .day, value: program.durationDays, to: calendar.startOfDay(for: enrollment.startDate)),
                  let fireDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: finishDay),
                  fireDate > now
            else { return nil }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "🎉 Program complete")
            content.body = String(localized: "You finished “\(program.title)”. See how you did, and what to try next.")
            content.sound = .default
            content.userInfo = [
                AppRouter.NotificationKey.destination: AppRouter.NotificationKey.programCompletion,
                AppRouter.NotificationKey.enrollmentID: enrollment.id,
            ]
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                repeats: false
            )
            return UNNotificationRequest(
                identifier: Self.programCompletionPrefix + String(enrollment.id),
                content: content,
                trigger: trigger
            )
        }
    }

    // MARK: - Working out what to register

    /// When a reminder comes due.
    enum ReminderDays: Equatable {
        case everyDay
        /// 1 = Sunday ... 7 = Saturday, as `Calendar` numbers them.
        case weekdays(Set<Int>)
        case monthDays(Set<Int>)
    }

    enum ReminderTrigger: Equatable {
        /// Fires at these components from now on.
        case repeating(DateComponents)
        /// Fires once, at this fully specified date. Used to step over a slot due later today
        /// that the user has already settled, without giving up the slot itself.
        case once(DateComponents)
    }

    struct ReminderRequest: Equatable {
        let id: String
        let trigger: ReminderTrigger
    }

    /// What a reminder should have registered, given when it is due and whether the user has
    /// anything left to do about it today.
    ///
    /// A repeating calendar trigger cannot skip a single occurrence, so a slot still ahead of
    /// the user today that they have already satisfied is re-registered around today instead.
    /// That is the difference between a reminder that congratulates you at 8pm for something
    /// you did at 7am and one that stays quiet — without going quiet for good.
    static func requests(
        notificationID: String,
        time: DateComponents,
        days: ReminderDays,
        isSatisfiedToday: Bool,
        now: Date,
        calendar: Calendar
    ) -> [ReminderRequest] {
        let slots: [(suffix: String, components: DateComponents)]
        switch days {
        case .everyDay:
            slots = [("", time)]
        case let .weekdays(weekdays):
            let sorted = weekdays.sorted()
            // Every day of the week is just a daily reminder, in one request instead of seven.
            if sorted.isEmpty || sorted.count >= 7 {
                slots = [("", time)]
            } else {
                slots = sorted.map { weekday in
                    var components = time
                    components.weekday = weekday
                    return ("-w\(weekday)", components)
                }
            }
        case let .monthDays(monthDays):
            let sorted = monthDays.sorted()
            if sorted.isEmpty {
                slots = [("", time)]
            } else {
                slots = sorted.map { day in
                    var components = time
                    components.day = day
                    return ("-d\(day)", components)
                }
            }
        }

        return slots.flatMap { slot -> [ReminderRequest] in
            let id = notificationID + slot.suffix

            // Only a slot that is both still ahead today and already settled needs stepping
            // over. One that has already passed has nothing left to suppress.
            guard isSatisfiedToday,
                  let nextFire = calendar.nextDate(after: now, matching: slot.components, matchingPolicy: .nextTime),
                  calendar.isDate(nextFire, inSameDayAs: now)
            else {
                return [ReminderRequest(id: id, trigger: .repeating(slot.components))]
            }

            // A daily slot stepped over with a single one-off would go quiet for good once that
            // one-off fired, since nothing re-registers it until the app is next opened — and
            // the people who stop opening the app are the ones a reminder is for. So it becomes
            // the other six weekdays, still repeating, plus a one-off for this weekday next week.
            // Opening the app on any later day collapses it back to one daily request.
            if slot.components.weekday == nil, slot.components.day == nil {
                let today = calendar.component(.weekday, from: now)
                var requests = (1...7).filter { $0 != today }.map { weekday in
                    var components = slot.components
                    components.weekday = weekday
                    return ReminderRequest(id: "\(notificationID)-w\(weekday)", trigger: .repeating(components))
                }
                var thisWeekday = slot.components
                thisWeekday.weekday = today
                if let nextWeek = calendar.nextDate(
                    after: now.endOfDay(for: calendar),
                    matching: thisWeekday,
                    matchingPolicy: .nextTime
                ) {
                    requests.append(ReminderRequest(
                        id: "\(notificationID)-w\(today)",
                        trigger: .once(calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextWeek))
                    ))
                }
                return requests
            }

            // A slot on particular days only loses this one occurrence; the others keep
            // repeating on their own.
            guard let following = calendar.nextDate(
                after: now.endOfDay(for: calendar),
                matching: slot.components,
                matchingPolicy: .nextTime
            ) else { return [] }

            return [ReminderRequest(
                id: id,
                trigger: .once(calendar.dateComponents([.year, .month, .day, .hour, .minute], from: following))
            )]
        }
    }

    /// A reminder attached to a habit should only fire on the days that habit is actually
    /// scheduled — nagging every morning about a Mon/Wed/Fri habit trains people to ignore it.
    /// Habits with an "n days per week/month" target can be done on any day, so those, and
    /// reminders not attached to a habit at all, stay daily.
    private func days(for reminder: Reminder) -> ReminderDays {
        guard let habitID = reminder.habitID,
              let habit = habit(withID: habitID)
        else { return .everyDay }

        switch habit.frequency {
        case .fixedDaysInWeek: return .weekdays(habit.daysOfWeek)
        case .fixedDaysInMonth: return .monthDays(habit.daysOfMonth)
        case .nDaysEachWeek, .nDaysEachMonth: return .everyDay
        }
    }

    /// Whether the reminder has anything left to ask for today. A reminder tied to a habit is
    /// settled once that habit is checked in or rested; the general reminder is settled once
    /// nothing at all is still due. A day off from everything settles both.
    private func isSatisfiedToday(_ reminder: Reminder, now: Date, calendar: Calendar) -> Bool {
        @Dependency(\.defaultDatabase) var database
        let startOfDay = now.startOfDay(for: calendar)
        let endOfDay = now.endOfDay(for: calendar)

        return withErrorReporting {
            try database.read { db in
                let restingToday = try SkippedDay
                    .where { $0.date.between(startOfDay, and: endOfDay) }
                    .fetchAll(db)
                if restingToday.contains(where: { $0.habitID == nil }) { return true }

                guard let habitID = reminder.habitID else {
                    // Nothing outstanding on today's list — which is also true on a day with
                    // nothing scheduled at all.
                    let habits = try Habit.where { !$0.isArchived }.fetchAll(db)
                    let checkIns = try CheckIn.all.fetchAll(db)
                    return HabitSchedule
                        .habitsDue(on: now, habits: habits, checkIns: checkIns, calendar: calendar)
                        .allSatisfy(\.isCompleted)
                }

                if restingToday.contains(where: { $0.habitID == habitID }) { return true }

                return try CheckIn
                    .where { $0.habitID.eq(habitID) }
                    .where { $0.date.between(startOfDay, and: endOfDay) }
                    .fetchCount(db) > 0
            }
        } ?? false
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
        debugLog("Removed notifications for reminder: \(reminder.id)")
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
            
            debugLog("Removed notifications for \(reminders.count) reminders associated with habit ID: \(habitID)")
        }
    }

    func removeAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        debugLog("Removed all pending notifications")
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

/// Tapping a reminder brings someone into the app to check in. Greeting them with an ad is the
/// quickest way to teach them to stop tapping, so a tap holds the next app-open ad back.
///
/// A weekly review or program-complete notification also says which screen to open, and the
/// tap hands that to `AppRouter`.
///
/// Only the tap is handled. Reminders that arrive while the app is open are left as iOS shows
/// them by default — not at all — which is how the app has always behaved.
final class ReminderTapObserver: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ReminderTapObserver()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // "Mark as Done" runs in the background and never brings the app forward, so it has no
        // ad to hold back and nothing to present.
        if response.actionIdentifier == NotificationService.markDoneAction {
            let checkIn = NotificationService.markDoneCheckIn(
                userInfo: response.notification.request.content.userInfo,
                deliveredAt: response.notification.date,
                now: Date(),
                calendar: .userPreferred(startWeekOnMonday: AppGroup.startWeekOnMonday)
            )
            guard let checkIn else {
                completionHandler()
                return
            }
            Task {
                await NotificationService.shared.markDone(habitID: checkIn.habitID, on: checkIn.date)
                completionHandler()
            }
            return
        }

        AppOpenAdPolicy.skipNextReturn()
        let destination = AppRouter.destination(
            userInfo: response.notification.request.content.userInfo,
            deliveredAt: response.notification.date
        )
        if let destination {
            Task { @MainActor in
                AppRouter.shared.presented = destination
            }
        }
        completionHandler()
    }
}
