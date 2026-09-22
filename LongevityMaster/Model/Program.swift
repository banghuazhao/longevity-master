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
