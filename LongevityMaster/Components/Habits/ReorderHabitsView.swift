//
// Created by Banghua Zhao on 10/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI

@Observable
@MainActor
final class ReorderHabitsViewModel {
    @ObservationIgnored
    @FetchAll(Habit.where { !$0.isArchived }, animation: .default) var habits

    @ObservationIgnored
    @FetchAll(HabitPosition.all, animation: .default) var positions

    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database

    var orderedHabits: [Habit] {
        Habit.inUserOrder(habits, positions: positions)
    }

    var hasCustomOrder: Bool {
        !positions.isEmpty
    }

    func move(from source: IndexSet, to destination: Int) {
        var ordered = orderedHabits
        ordered.move(fromOffsets: source, toOffset: destination)
        save(ordered.map(\.id))
    }

    /// One step up or down, for VoiceOver, which has no way to drag a row.
    func move(_ habit: Habit, by offset: Int) {
        var ids = orderedHabits.map(\.id)
        guard let index = ids.firstIndex(of: habit.id) else { return }
        let target = index + offset
        guard ids.indices.contains(target) else { return }
        ids.swapAt(index, target)
        save(ids)
    }

    func resetOrder() {
        withErrorReporting {
            try database.write { db in
                try HabitPosition.all.delete().execute(db)
            }
        }
        WidgetRefresher.reload()
    }

    private func save(_ ids: [Habit.ID]) {
        withErrorReporting {
            try database.write { db in
                try Self.saveOrder(ids, in: db)
            }
        }
        WidgetRefresher.reload()
    }

    /// Writes `ids` as the order, from scratch. Archived habits are not in the list being
    /// arranged, so they lose their place and rejoin at the end if they are brought back.
    nonisolated static func saveOrder(_ ids: [Habit.ID], in db: Database) throws {
        try HabitPosition.all.delete().execute(db)
        for (position, habitID) in ids.enumerated() {
            try HabitPosition
                .insert { HabitPosition.Draft(habitID: habitID, position: position) }
                .execute(db)
        }
    }
}

struct ReorderHabitsView: View {
    @State private var viewModel = ReorderHabitsViewModel()
    @State private var isConfirmingReset = false
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        let habits = viewModel.orderedHabits

        NavigationStack {
            List {
                Section {
                    ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                        row(for: habit)
                            .accessibilityElement(children: .combine)
                            .accessibilityHint(Text("Position \(index + 1) of \(habits.count)"))
                            .accessibilityAction(named: Text("Move Up")) {
                                viewModel.move(habit, by: -1)
                            }
                            .accessibilityAction(named: Text("Move Down")) {
                                viewModel.move(habit, by: 1)
                            }
                    }
                    .onMove(perform: viewModel.move)
                } footer: {
                    Text("Today, the Habits tab and the widgets follow this order. On Today, habits stay grouped by category. New habits are added at the end.")
                }
            }
            .environment(\.editMode, .constant(.active))
            .overlay {
                if habits.isEmpty {
                    Text("No habits to arrange yet.")
                        .font(AppFont.subheadline)
                        .foregroundStyle(themeManager.current.textSecondary)
                }
            }
            .navigationTitle("Reorder Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.hasCustomOrder {
                        Button("Reset") {
                            isConfirmingReset = true
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Go back to the default order?",
                isPresented: $isConfirmingReset,
                titleVisibility: .visible
            ) {
                Button("Reset Order", role: .destructive) {
                    withAnimation {
                        viewModel.resetOrder()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Favorites come first, then the rest in the order you added them.")
            }
        }
    }

    private func row(for habit: Habit) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Text(habit.icon)
                .font(.title2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(AppFont.body)
                Text(habit.category.briefTitle)
                    .font(AppFont.caption)
                    .foregroundStyle(themeManager.current.textSecondary)
            }
            Spacer(minLength: 0)
            if habit.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel(Text("Favorite"))
            }
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    ReorderHabitsView()
}
