//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

/// A guided plan: a handful of gallery habits followed together for a fixed number of days,
/// with a focus for each week and the research behind it.
///
/// Programs are defined in code (`ProgramsDataStore`) rather than stored, so they are translated
/// like the rest of the app and can be revised in an update. What the database records is only
/// that the user started one — see `ProgramEnrollment`.
struct Program: Identifiable, Hashable {
    /// Written to the database when the program is started, so it must never change once
    /// shipped, and is never translated.
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Int
    let durationDays: Int
    let summary: String
    /// One line per week, in order. A program shorter than its last line simply ends early.
    let weeklyFocus: [String]
    let habits: [Habit.Draft]
    let sources: [EvidenceSource]

    var durationWeeks: Int {
        (durationDays + 6) / 7
    }
}

/// A published study behind a program, shown so the claims can be checked.
struct EvidenceSource: Hashable {
    /// Authors, journal and year, as a reference list prints them. Not translated.
    let citation: String
    /// The paper's own title, in its own language. Not translated: it is also what the link
    /// searches for.
    let title: String
    /// What the study found, in a sentence the reader can use.
    let finding: String

    /// A PubMed search for the exact title rather than a stored link, which cannot rot and
    /// always lands on the paper's abstract.
    var url: URL? {
        var components = URLComponents(string: "https://pubmed.ncbi.nlm.nih.gov/")
        components?.queryItems = [URLQueryItem(name: "term", value: title)]
        return components?.url
    }
}

/// A program the user has started. Leaving the program deletes this row; the habits it added
/// stay, because by then they are the user's own.
@Table
struct ProgramEnrollment: Identifiable {
    let id: Int
    /// A `Program.id`. A program since removed from the app leaves rows that match nothing,
    /// and those are skipped wherever enrollments are listed.
    var programID: String
    @Column(as: Date.self)
    var startDate: Date
    /// Set once the user has seen the program through and dismissed it from Today. It stays
    /// listed under the program as a past result.
    var isArchived: Bool = false
}

extension ProgramEnrollment.Draft: Identifiable {}

/// Which of the user's habits an enrollment is tracking. A join rather than a match on names,
/// so renaming a habit after starting the program keeps it counted.
@Table
struct ProgramHabit: Identifiable {
    let id: Int
    var enrollmentID: ProgramEnrollment.ID
    var habitID: Habit.ID
}

// MARK: - Custom programs

/// A program the user put together. Stored rather than defined in code, and turned into a
/// `Program` for everything downstream, so starting, tracking and sharing one works exactly as
/// it does for the guided programs.
@Table
struct CustomProgram: Identifiable {
    let id: Int
    var title: String = ""
    var icon: String = "🎯"
    var color: Int = 0x4DD0AE99
    var durationDays: Int = 21
    var summary: String = ""
    @Column(as: [String].JSONRepresentation.self)
    var weeklyFocus: [String] = []
    /// Snapshots of the habits, not references to them: a program is a plan that can be
    /// started again later, and starting it matches these to the user's habits by name the
    /// same way the guided programs do.
    @Column(as: [ProgramHabitTemplate].JSONRepresentation.self)
    var habits: [ProgramHabitTemplate] = []
}

extension CustomProgram.Draft: Identifiable {}

/// A habit as a program describes it. `Habit.Draft` itself is not `Codable`; this is the
/// part of it worth keeping.
struct ProgramHabitTemplate: Codable, Hashable {
    var name: String
    var category: HabitCategory
    var frequency: Int
    var frequencyDetail: String
    var antiAgingRating: Int
    var icon: String
    var color: Int
    var note: String

    init(_ draft: Habit.Draft) {
        name = draft.name
        category = draft.category
        frequency = draft.frequency.rawValue
        frequencyDetail = draft.frequencyDetail
        antiAgingRating = draft.antiAgingRating
        icon = draft.icon
        color = draft.color
        note = draft.note
    }

    init(_ habit: Habit) {
        self.init(Habit.Draft(habit))
    }

    var draft: Habit.Draft {
        Habit.Draft(
            name: name,
            category: category,
            frequency: HabitFrequency(rawValue: frequency) ?? .fixedDaysInWeek,
            frequencyDetail: frequencyDetail,
            antiAgingRating: antiAgingRating,
            icon: icon,
            color: color,
            note: note
        )
    }
}

extension Program {
    private static let customPrefix = "custom-"

    /// What an enrollment in `custom` records as its program.
    static func id(forCustom customID: CustomProgram.ID) -> String {
        customPrefix + String(customID)
    }

    /// The stored program behind this one, if the user made it.
    var customID: CustomProgram.ID? {
        guard id.hasPrefix(Self.customPrefix) else { return nil }
        return Int(id.dropFirst(Self.customPrefix.count))
    }

    var isCustom: Bool {
        customID != nil
    }

    init(custom: CustomProgram) {
        self.init(
            id: Self.id(forCustom: custom.id),
            title: custom.title,
            subtitle: custom.summary.isEmpty ? String(localized: "My program") : custom.summary,
            icon: custom.icon,
            color: custom.color,
            durationDays: max(custom.durationDays, 1),
            summary: custom.summary,
            weeklyFocus: custom.weeklyFocus,
            habits: custom.habits.map(\.draft),
            sources: []
        )
    }
}
