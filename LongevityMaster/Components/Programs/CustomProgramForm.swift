//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI

@Observable
@MainActor
final class CustomProgramFormModel: Identifiable {
    var draft: CustomProgram.Draft
    /// Only offered for a new program; one being edited has already been started or not.
    var startToday = true
    var isPickingHabits = false
    var isEditingIcon = false
    let isNew: Bool

    @ObservationIgnored
    @FetchAll(Habit.where { !$0.isArchived }.order { $0.name }, animation: .default)
    var userHabits

    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database

    @ObservationIgnored
    @Dependency(\.notificationService) private var notificationService

    init(program: CustomProgram? = nil) {
        if let program {
            draft = CustomProgram.Draft(program)
            isNew = false
        } else {
            draft = CustomProgram.Draft()
            isNew = true
        }
    }

    private static let durationOptions = [7, 14, 21, 28, 30, 42, 60, 90]

    /// The usual lengths, plus whatever the program already has.
    var durationOptions: [Int] {
        Array(Set(Self.durationOptions + [draft.durationDays])).sorted()
    }

    var weeks: Int {
        (draft.durationDays + 6) / 7
    }

    var canSave: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !draft.habits.isEmpty
    }

    /// Week `week`'s focus, 1-based. Weeks without one read as empty, and writing to a later
    /// week pads the ones before it.
    func focus(forWeek week: Int) -> Binding<String> {
        Binding(
            get: { [weak self] in
                guard let self, self.draft.weeklyFocus.indices.contains(week - 1) else { return "" }
                return self.draft.weeklyFocus[week - 1]
            },
            set: { [weak self] newValue in
                guard let self else { return }
                while self.draft.weeklyFocus.count < week {
                    self.draft.weeklyFocus.append("")
                }
                self.draft.weeklyFocus[week - 1] = newValue
            }
        )
    }

    func removeHabits(at offsets: IndexSet) {
        draft.habits.remove(atOffsets: offsets)
    }

    func save() {
        var draft = draft
        draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.summary = draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        // Only the weeks the program has, and none of the empty ones trailing after the
        // last written.
        var focus = draft.weeklyFocus
            .prefix(weeks)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        while focus.last?.isEmpty == true {
            focus.removeLast()
        }
        draft.weeklyFocus = Array(focus)

        let startToday = isNew && startToday
        withErrorReporting {
            try database.write { db in
                let saved = try CustomPrograms.save(draft, in: db)
                if startToday {
                    try ProgramEnrollments.start(Program(custom: saved), on: Date(), in: db)
                }
            }
            WidgetRefresher.reload()
            Task { await notificationService.syncAllReminders() }
        }
    }
}

/// Making or editing one of the user's own programs.
struct CustomProgramFormView: View {
    @State var model: CustomProgramFormModel

    @Environment(\.dismiss) private var dismiss
    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: AppSpacing.smallMedium) {
                        Button {
                            model.isEditingIcon = true
                        } label: {
                            Text(model.draft.icon)
                                .font(.system(size: 30))
                                .frame(width: 56, height: 56)
                                .background(Color(hex: model.draft.color), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Change icon"))

                        TextField("Program name", text: $model.draft.title)
                            .font(AppFont.headline)
                    }
                    TextField("What is it for? (optional)", text: $model.draft.summary, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Picker("Length", selection: $model.draft.durationDays) {
                        ForEach(model.durationOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                    .tint(themeManager.current.primaryColor)
                }

                Section {
                    ForEach(model.draft.habits, id: \.name) { template in
                        ProgramHabitTemplateRow(template: template)
                    }
                    .onDelete(perform: model.removeHabits)

                    Button {
                        model.isPickingHabits = true
                    } label: {
                        Label("Add Habits", systemImage: "plus.circle.fill")
                    }
                    .tint(themeManager.current.primaryColor)
                } header: {
                    Text("Habits")
                } footer: {
                    Text("Starting the program adds any of these you don't already track.")
                }

                Section {
                    ForEach(1...model.weeks, id: \.self) { week in
                        TextField("Week \(week) focus", text: model.focus(forWeek: week), axis: .vertical)
                    }
                } header: {
                    Text("Week by week")
                } footer: {
                    Text("Optional. A short goal for each week, shown on Today while the program runs.")
                }

                if model.isNew {
                    Section {
                        Toggle("Start today", isOn: $model.startToday)
                            .tint(themeManager.current.primaryColor)
                    }
                }
            }
            .navigationTitle(model.isNew ? "New Program" : "Edit Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.save()
                        dismiss()
                    }
                    .disabled(!model.canSave)
                }
            }
            .sheet(isPresented: $model.isEditingIcon) {
                HabitIconEditView(color: $model.draft.color, icon: $model.draft.icon)
                    .presentationDetents([.fraction(0.8), .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $model.isPickingHabits) {
                ProgramHabitPickerView(selection: $model.draft.habits, userHabits: model.userHabits)
            }
        }
    }
}

struct ProgramHabitTemplateRow: View {
    let template: ProgramHabitTemplate

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: AppSpacing.smallMedium) {
            Text(template.icon)
                .font(.system(size: 22))
                .frame(width: 38, height: 38)
                .background(Color(hex: template.color), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(AppFont.subheadline.weight(.semibold))
                    .foregroundStyle(themeManager.current.textPrimary)
                Text(template.draft.frequencyDescription)
                    .font(AppFont.footnote)
                    .foregroundStyle(themeManager.current.textSecondary)
            }
        }
    }
}

/// Picks a program's habits from the user's own and from the gallery. Gallery habits the user
/// already has are left out, so each name appears once.
struct ProgramHabitPickerView: View {
    @Binding var selection: [ProgramHabitTemplate]
    let userHabits: [Habit]

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        let owned = Set(userHabits.map(\.name))
        let mine = userHabits.filter { matches($0.name) }

        NavigationStack {
            List {
                if !mine.isEmpty {
                    Section("Your habits") {
                        ForEach(mine) { habit in
                            row(ProgramHabitTemplate(habit))
                        }
                    }
                }
                ForEach(HabitCategory.allCases, id: \.self) { category in
                    let gallery = HabitsDataStore.habits(forCategory: category)
                        .filter { !owned.contains($0.name) && matches($0.name) }
                    if !gallery.isEmpty {
                        Section(category.title) {
                            ForEach(gallery, id: \.name) { draft in
                                row(ProgramHabitTemplate(draft))
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Add Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .tint(themeManager.current.primaryColor)
    }

    private func row(_ template: ProgramHabitTemplate) -> some View {
        let isSelected = selection.contains { $0.name == template.name }
        return Button {
            Haptics.shared.vibrateIfEnabled()
            if let index = selection.firstIndex(where: { $0.name == template.name }) {
                selection.remove(at: index)
            } else {
                selection.append(template)
            }
        } label: {
            HStack {
                ProgramHabitTemplateRow(template: template)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? themeManager.current.primaryColor : themeManager.current.secondaryGray)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func matches(_ name: String) -> Bool {
        searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
    }
}
