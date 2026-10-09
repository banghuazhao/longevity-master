//
// Created by Banghua Zhao on 10/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import LongevityMaster

@Suite("Ordering habits")
struct HabitOrderTests {
    private func habit(_ id: Int, favorite: Bool = false) -> Habit {
        Habit(id: id, name: "Habit \(id)", isFavorite: favorite)
    }

    private func position(_ habitID: Int, _ position: Int) -> HabitPosition {
        HabitPosition(id: habitID, habitID: habitID, position: position)
    }

    @Test("Without an order of their own, favourites come first, then oldest first")
    func defaultOrder() {
        let habits = [habit(3), habit(1), habit(4, favorite: true), habit(2, favorite: true)]
        let ordered = Habit.inUserOrder(habits, positions: [])
        #expect(ordered.map(\.id) == [2, 4, 1, 3])
    }

    @Test("Placed habits follow the user's order, whatever is a favourite")
    func userOrder() {
        let habits = [habit(1, favorite: true), habit(2), habit(3)]
        let ordered = Habit.inUserOrder(habits, positions: [position(3, 0), position(1, 1), position(2, 2)])
        #expect(ordered.map(\.id) == [3, 1, 2])
    }

    @Test("A habit added after the order was set goes at the end")
    func newHabitGoesLast() {
        let habits = [habit(1), habit(2), habit(3, favorite: true)]
        let ordered = Habit.inUserOrder(habits, positions: [position(2, 0), position(1, 1)])
        #expect(ordered.map(\.id) == [2, 1, 3])
    }

    @Test("Saving an order replaces the last one, and deleting a habit takes its place with it")
    func savingAndDeleting() async throws {
        try await withTestDatabase { database in
            let ids = try await database.write { db in
                try ["A", "B", "C"].map { name in
                    try Habit.upsert { testHabitDraft(name: name) }.returning(\.id).fetchOne(db)!
                }
            }

            try await database.write { db in
                try ReorderHabitsViewModel.saveOrder([ids[2], ids[0], ids[1]], in: db)
                try ReorderHabitsViewModel.saveOrder([ids[1], ids[2], ids[0]], in: db)
            }
            let (habits, positions) = try await database.read { db in
                (try Habit.all.fetchAll(db), try HabitPosition.all.fetchAll(db))
            }
            #expect(positions.count == 3)
            #expect(Habit.inUserOrder(habits, positions: positions).map(\.id) == [ids[1], ids[2], ids[0]])

            try await database.write { db in
                try Habit.find(ids[2]).delete().execute(db)
            }
            let remaining = try await database.read { db in
                try HabitPosition.all.fetchAll(db)
            }
            #expect(Set(remaining.map(\.habitID)) == [ids[0], ids[1]])
        }
    }
}
