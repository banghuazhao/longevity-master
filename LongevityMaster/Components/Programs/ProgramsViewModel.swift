//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData
import Sharing
import SwiftUI

/// The user's programs and where each one stands. One instance backs the program list, the
/// program pages opened from it and the Today card, so all three read the same numbers.
@Observable
@MainActor
final class ProgramsViewModel {
    /// A program the user started, with its progress worked out.
    struct Enrolled: Identifiable {
        let enrollment: ProgramEnrollment
        let program: Program
        let habits: [Habit]
        let progress: ProgramProgress

        var id: ProgramEnrollment.ID { enrollment.id }

        var shareCard: ShareCardContent {
            .program(program, progress: progress)
        }

        /// 1-based; the last week while the program is on its final days.
        var currentWeek: Int {
            min((progress.dayNumber - 1) / 7 + 1, program.durationWeeks)
        }
    }

    @ObservationIgnored
    @FetchAll(ProgramEnrollment.order { $0.startDate.desc() }, animation: .default)
    var enrollments

    @ObservationIgnored
    @FetchAll(ProgramHabit.all, animation: .default)
    var programHabits

    @ObservationIgnored
    @FetchAll(CustomProgram.order { $0.id.desc() }, animation: .default)
    var customProgramRows

    @ObservationIgnored
    @FetchAll(Habit.all, animation: .default)
    var habits

    @ObservationIgnored
    @FetchAll(CheckIn.all, animation: .default)
    var checkIns

    @ObservationIgnored
    @FetchAll(SkippedDay.all, animation: .default)
    var skippedDays

    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database

    @ObservationIgnored
    @Dependency(\.notificationService) private var notificationService

    @ObservationIgnored
    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true

    var userCalendar: Calendar {
        .userPreferred(startWeekOnMonday: startWeekOnMonday)
    }

    /// The user's own programs, newest first.
    var customPrograms: [Program] {
        customProgramRows.map(Program.init(custom:))
    }

    /// A guided program or one of the user's, by the id an enrollment records.
    func program(id: String) -> Program? {
        if let program = ProgramsDataStore.program(id: id) {
            return program
        }
        return customProgramRows
            .first { Program.id(forCustom: $0.id) == id }
            .map(Program.init(custom:))
    }

    /// The stored row behind a custom program, for editing it.
    func customRow(for program: Program) -> CustomProgram? {
        guard let customID = program.customID else { return nil }
        return customProgramRows.first { $0.id == customID }
    }

    /// Every enrollment whose program still exists — shipped with the app, or the user's own —
    /// newest first.
    var enrolled: [Enrolled] {
        let calendar = userCalendar
        let restDays = RestDays(skippedDays, in: calendar)
        let habitsByID = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
        let habitIDsByEnrollment = Dictionary(grouping: programHabits, by: \.enrollmentID)
        let now = Date()
        let customByID = Dictionary(
            uniqueKeysWithValues: customProgramRows.map { (Program.id(forCustom: $0.id), Program(custom: $0)) }
        )

        return enrollments.compactMap { enrollment in
            guard
                let program = ProgramsDataStore.program(id: enrollment.programID)
                    ?? customByID[enrollment.programID]
            else { return nil }
            let habits = (habitIDsByEnrollment[enrollment.id] ?? []).compactMap { habitsByID[$0.habitID] }
            let progress = ProgramProgress.make(
                durationDays: program.durationDays,
                startDate: enrollment.startDate,
                today: now,
                habits: habits,
                checkIns: checkIns,
                restDays: restDays,
                calendar: calendar
            )
            return Enrolled(enrollment: enrollment, program: program, habits: habits, progress: progress)
        }
    }

    /// What the Today tab shows: programs under way, and finished ones not yet dismissed.
    var current: [Enrolled] {
        enrolled.filter { !$0.enrollment.isArchived }
    }

    /// The run of `program` still going, if there is one.
    func active(_ program: Program, in enrolled: [Enrolled]) -> Enrolled? {
        enrolled.first { $0.program.id == program.id && !$0.progress.isFinished }
    }

    /// Earlier runs of `program` that were seen through.
    func finished(_ program: Program, in enrolled: [Enrolled]) -> [Enrolled] {
        enrolled.filter { $0.program.id == program.id && $0.progress.isFinished }
    }

    /// How each of a run's habits did over the run, best first — the completion screen's
    /// breakdown, judged by the same rules as the run's overall figure.
    func habitResults(for enrolled: Enrolled) -> [(habit: Habit, progress: ProgramProgress)] {
        let calendar = userCalendar
        let restDays = RestDays(skippedDays, in: calendar)
        let now = Date()
        return enrolled.habits
            .map { habit in
                (habit, ProgramProgress.make(
                    durationDays: enrolled.program.durationDays,
                    startDate: enrolled.enrollment.startDate,
                    today: now,
                    habits: [habit],
                    checkIns: checkIns,
                    restDays: restDays,
                    calendar: calendar
                ))
            }
            .sorted { ($0.1.adherence ?? -1) > ($1.1.adherence ?? -1) }
    }

    /// Guided programs to suggest once `finished` is over.
    func recommendations(after finished: Enrolled) -> [Program] {
        let enrolled = self.enrolled
        return ProgramRecommendations.next(
            after: finished.program,
            activeProgramIDs: Set(enrolled.filter { !$0.progress.isFinished }.map(\.program.id)),
            completedProgramIDs: Set(enrolled.filter(\.progress.isFinished).map(\.program.id))
        )
    }

    /// Clears a finished run off Today and starts `next` in its place — which may be the same
    /// program again.
    func startNext(_ next: Program, after finished: Enrolled) {
        archive(finished)
        start(next)
    }

    func start(_ program: Program) {
        Haptics.shared.vibrateIfEnabled()
        withErrorReporting {
            try database.write { db in
                try ProgramEnrollments.start(program, on: Date(), in: db)
            }
            afterHabitsChanged()
        }
    }

    func leave(_ enrolled: Enrolled) {
        withErrorReporting {
            try database.write { db in
                try ProgramEnrollments.leave(enrolled.id, in: db)
            }
            afterProgramsChanged()
        }
    }

    func delete(_ program: Program) {
        guard let customID = program.customID else { return }
        withErrorReporting {
            try database.write { db in
                try CustomPrograms.delete(customID, in: db)
            }
            afterProgramsChanged()
        }
    }

    func archive(_ enrolled: Enrolled) {
        withErrorReporting {
            try database.write { db in
                try ProgramEnrollments.archive(enrolled.id, in: db)
            }
        }
    }

    /// A run that is left or deleted must not announce its own finish later.
    private func afterProgramsChanged() {
        Task { await notificationService.syncProgramCompletions() }
    }

    /// Starting a program can add habits or bring archived ones back, which changes both the
    /// widget's list and what the reminders have to ask for.
    private func afterHabitsChanged() {
        WidgetRefresher.reload()
        Task { await notificationService.syncAllReminders() }
    }
}
