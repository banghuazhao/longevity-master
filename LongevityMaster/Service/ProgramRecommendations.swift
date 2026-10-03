//
// Created by Banghua Zhao on 03/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// What to suggest once a program is over. The end of a program is the moment people drift
/// off; offering a next step keeps the momentum the program built.
enum ProgramRecommendations {
    /// Guided programs worth starting after `finished`, best first.
    ///
    /// Programs already under way are left out, and so is the one just finished — running it
    /// again is offered separately. What is left is ranked by:
    /// 1. never completed before, ahead of ones the user has done;
    /// 2. a different area of health from the finished program and from anything running —
    ///    someone fresh off a sleep program is better served by strength or diet than by more
    ///    sleep;
    /// 3. the catalog's own order.
    static func next(
        after finished: Program,
        activeProgramIDs: Set<String>,
        completedProgramIDs: Set<String>,
        catalog: [Program] = ProgramsDataStore.all,
        limit: Int = 2
    ) -> [Program] {
        let coveredAreas = Set(
            catalog
                .filter { activeProgramIDs.contains($0.id) }
                .compactMap(\.primaryCategory)
        ).union([finished.primaryCategory].compactMap { $0 })

        let candidates = catalog.enumerated().filter { _, program in
            program.id != finished.id && !activeProgramIDs.contains(program.id)
        }

        return candidates
            .sorted { lhs, rhs in
                let lhsKey = rank(lhs.element, order: lhs.offset, completed: completedProgramIDs, covered: coveredAreas)
                let rhsKey = rank(rhs.element, order: rhs.offset, completed: completedProgramIDs, covered: coveredAreas)
                return lhsKey < rhsKey
            }
            .prefix(limit)
            .map(\.element)
    }

    private static func rank(
        _ program: Program,
        order: Int,
        completed: Set<String>,
        covered: Set<HabitCategory>
    ) -> (Int, Int, Int) {
        let isRepeat = completed.contains(program.id) ? 1 : 0
        let isSameArea = program.primaryCategory.map(covered.contains) ?? false ? 1 : 0
        return (isRepeat, isSameArea, order)
    }
}

extension Program {
    /// The area of health most of the program's habits belong to; on a tie, the first habit's.
    var primaryCategory: HabitCategory? {
        let counts = Dictionary(grouping: habits, by: \.category).mapValues(\.count)
        guard let most = counts.values.max() else { return nil }
        return habits.first { counts[$0.category] == most }?.category
    }
}
