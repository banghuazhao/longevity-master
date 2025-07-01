//
// Created by Banghua Zhao on 22/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import EasyToast
import SharingGRDB
import SwiftNavigation
import SwiftUI

@Observable
@MainActor
class HabitFormViewModel: HashableObject {
    var habit: Habit.Draft
    
    var draftReminders: [Reminder.Draft] = []
    private var originalReminderIDs: Set<Int> = []

    var todayHabit: TodayHabit {
        let frequencyDescription: String? = switch habit.frequency {
        case .nDaysEachWeek: "1/\(habit.nDaysPerWeek) this week"
        case .nDaysEachMonth: "1/\(habit.nDaysPerMonth) this month"
        default: nil
        }
        return habit.toTodayHabit(
            streakDescription: "🔥 1d streak",
            frequencyDescription: frequencyDescription
        )
    }

    @CasePathable
    enum Route: Equatable {
        case editHabitIcon
        case habitsGallery
        case addReminder(ReminderFormViewModel)
        case editReminder(ReminderFormViewModel)
    }

    var route: Route?

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    @ObservationIgnored
    @Dependency(\.notificationService) var notificationService

    var showTitleEmptyToast = false
    let isEdit: Bool
    let onSaveHabit: ((Habit.Draft) -> Void)?

    init(
        habit: Habit.Draft,
        onSaveHabit: ((Habit.Draft) -> Void)? = nil
    ) {
        self.habit = habit
        self.onSaveHabit = onSaveHabit
        isEdit = habit.id != nil
        if let habitID = habit.id, isEdit {
            if let reminders = try? appDatabase().read({ db in
                try Reminder
                    .where { $0.habitID.eq(habitID) }
                    .fetchAll(db)
            }) {
                self.draftReminders = reminders.map { Reminder.Draft($0) }
                self.originalReminderIDs = Set(reminders.map { $0.id })
            }
        } else {
            self.draftReminders = []
            self.originalReminderIDs = []
        }
    }

    func toggleWeekDay(_ weekDay: WeekDays) {
        guard habit.frequency == .fixedDaysInWeek else { return }
        var daysOfWeek = habit.daysOfWeek
        if hasSelectedWeekDay(weekDay) {
            daysOfWeek.remove(weekDay.rawValue)
        } else {
            daysOfWeek.insert(weekDay.rawValue)
        }
        habit.frequencyDetail = daysOfWeek.sorted().map(String.init).joined(separator: ",")
    }

    func toggleMonthDay(_ monthDay: Int) {
        guard habit.frequency == .fixedDaysInMonth else { return }
        var daysOfMonth = habit.daysOfMonth
        if hasSelectedMonthDay(monthDay) {
            daysOfMonth.remove(monthDay)
        } else {
            daysOfMonth.insert(monthDay)
        }
        habit.frequencyDetail = daysOfMonth.sorted().map(String.init).joined(separator: ",")
    }

    func hasSelectedWeekDay(_ weekDay: WeekDays) -> Bool {
        guard habit.frequency == .fixedDaysInWeek else { return false }
        return habit.daysOfWeek.contains(weekDay.rawValue)
    }

    func hasSelectedMonthDay(_ monthDay: Int) -> Bool {
        guard habit.frequency == .fixedDaysInMonth else { return false }
        return habit.daysOfMonth.contains(monthDay)
    }

    func onSelectNDays(_ nDays: Int) {
        habit.frequencyDetail = "\(nDays)"
    }

    func onChangeOfHabitFrequency() {
        switch habit.frequency {
        case .fixedDaysInWeek:
            habit.frequencyDetail = "1,2,3,4,5,6,7"
        case .fixedDaysInMonth:
            habit.frequencyDetail = "1"
        case .nDaysEachWeek:
            habit.frequencyDetail = "1"
        case .nDaysEachMonth:
            habit.frequencyDetail = "1"
        }
    }

    func onTapTodayHabit() {
        route = .editHabitIcon
    }

    func onTapSaveHabit() async -> Bool {
        guard !habit.name.isEmpty else {
            showTitleEmptyToast = true
            return false
        }
        await withErrorReporting {
            let updatedHabit = try await database.write { [habit] db in
                try Habit
                    .upsert(habit)
                    .returning { $0 }
                    .fetchOne(db)
            }
            
            guard let updatedHabit else { return }
            
            for var draftReminder in draftReminders {
                draftReminder.habitID = updatedHabit.id
                draftReminder.title = "\(updatedHabit.icon) \(updatedHabit.name)"
                let reminder = try await database.write { [draftReminder] db in
                    try Reminder
                        .upsert(draftReminder)
                        .returning { $0 }
                        .fetchOne(db)
                }
                
                if let reminder {
                    await notificationService.scheduleReminder(reminder)
                }
            }
            
            let currentIDs = Set(draftReminders.compactMap { $0.id })
            let toDelete = originalReminderIDs.subtracting(currentIDs)
            for id in toDelete {
                let reminderToDelete = try await database.read { db in
                    try Reminder
                        .where { $0.id.eq(id) }
                        .fetchOne(db)
                }
                if let reminderToDelete {
                    try await database.write { db in
                        try Reminder
                            .delete(reminderToDelete)
                            .execute(db)
                    }
                    notificationService.removeReminder(reminderToDelete)
                }
            }
        }
        onSaveHabit?(habit)
        return true
    }

    func onTapGallery() {
        route = .habitsGallery
    }
    
    func onTapAddReminder() {
        route = .addReminder(
            ReminderFormViewModel(
                reminder: Reminder.Draft(),
                onSave: { [weak self] draft in
                    guard let self else { return }
                    draftReminders.append(draft)
                    route = nil
                }
            )
        )
    }
    
    func onTapEditReminder(_ reminder: Reminder.Draft) {
        route = .editReminder(
            ReminderFormViewModel(
                reminder: reminder,
                onSave: { [weak self] updatedDraft in
                    guard let self else { return }
                    if let idx = draftReminders.firstIndex(where: { $0.id == updatedDraft.id }) {
                        draftReminders[idx] = updatedDraft
                    }
                    route = nil
                },
                onDelete: { [weak self] reminder in
                    guard let self else { return }
                    if let idx = draftReminders.firstIndex(where: { $0.id == reminder.id }) {
                        draftReminders.remove(at: idx)
                    }
                    route = nil
                }
            )
        )
    }
    
    func onTapDeleteReminder(_ reminder: Reminder.Draft) {
        if let idx = draftReminders.firstIndex(where: { $0.id == reminder.id }) {
            draftReminders.remove(at: idx)
        }
    }
}

enum WeekDays: Int, CaseIterable {
    case mon = 2
    case tue = 3
    case wed = 4
    case thu = 5
    case fri = 6
    case sat = 7
    case sun = 1

    var title: String {
        switch self {
        case .mon:
            "Mon"
        case .tue:
            "Tue"
        case .wed:
            "Wed"
        case .thu:
            "Thu"
        case .fri:
            "Fri"
        case .sat:
            "Sat"
        case .sun:
            "Sun"
        }
    }
}

struct HabitFormView: View {
    @State var viewModel: HabitFormViewModel

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HabitItemView(todayHabit: viewModel.todayHabit) {
                        viewModel.onTapTodayHabit()
                    }
                    .sheet(isPresented: Binding($viewModel.route.editHabitIcon)) {
                        HabitIconEditView(
                            color: $viewModel.habit.color,
                            icon: $viewModel.habit.icon
                        )
                        .presentationDetents([.fraction(0.8), .large])
                        .presentationDragIndicator(.visible)
                    }

                    HStack {
                        Image(systemName: "list.bullet.clipboard.fill")
                        TextField("New habit name", text: $viewModel.habit.name)
                        Button {
                            viewModel.onTapGallery()
                        } label: {
                            Text("Gallery")
                                .cornerRadius(8)
                        }
                        .sheet(isPresented: Binding($viewModel.route.habitsGallery)) {
                            HabitsGalleryView(
                                habit: $viewModel.habit
                            )
                            .presentationDetents([.fraction(0.8), .large])
                            .presentationDragIndicator(.visible)
                        }
                    }

                    HStack(spacing: 10) {
                        HStack {
                            Image(systemName: "folder.fill.badge.person.crop")
                            Text("Category")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        Picker("Category", selection: $viewModel.habit.category) {
                            ForEach(HabitCategory.allCases, id: \.self) { habitCategory in
                                Text(habitCategory.title)
                                    .tag(habitCategory.rawValue)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack {
                                Image(systemName: "clock.fill")
                                Text("Frequency")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            Picker("Frequency", selection: $viewModel.habit.frequency) {
                                ForEach(HabitFrequency.allCases, id: \.self) { habitFrequency in
                                    Text(habitFrequency.title)
                                        .tag(habitFrequency.rawValue)
                                }
                            }
                        }

                        switch viewModel.habit.frequency {
                        case .fixedDaysInWeek:
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible()), count: 7)
                            ) {
                                ForEach(WeekDays.allCases, id: \.self) { weekDay in
                                    Button(action: { viewModel.toggleWeekDay(weekDay) }) {
                                        VStack(spacing: 8) {
                                            Text(weekDay.title)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                            if viewModel.hasSelectedWeekDay(weekDay) {
                                                Image(systemName: "checkmark.circle.fill")
                                            }
                                        }
                                        .padding(8)
                                    }
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        case .fixedDaysInMonth:
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible()), count: 7)
                            ) {
                                ForEach(1 ... 28, id: \.self) { monthDay in
                                    Button(action: { viewModel.toggleMonthDay(monthDay) }) {
                                        VStack(spacing: 8) {
                                            Text("\(monthDay)")
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                        }
                                        .padding(8)
                                    }
                                    .background(
                                        viewModel.hasSelectedMonthDay(monthDay) ?
                                            Color.green.opacity(0.1) :
                                            Color.gray.opacity(0.1)
                                    )
                                    .cornerRadius(8)
                                }
                            }
                        case .nDaysEachWeek:
                            HStack {
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { viewModel.habit.nDaysPerWeek },
                                    set: { viewModel.onSelectNDays($0) }
                                )) {
                                    ForEach(1 ... 7, id: \.self) { nDays in
                                        if nDays == 1 {
                                            Text("\(nDays) day")
                                                .tag(nDays)
                                        } else {
                                            Text("\(nDays) days")
                                                .tag(nDays)
                                        }
                                    }
                                }
                            }
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color.gray)
                                    .font(.caption)
                                if viewModel.habit.nDaysPerWeek == 1 {
                                    Text("After being completed on \(viewModel.habit.nDaysPerWeek) day, the habit will not show up again this week.")
                                        .foregroundStyle(Color.gray)
                                        .font(.caption)
                                } else {
                                    Text("After being completed on \(viewModel.habit.nDaysPerWeek) days, the habit will not show up again this week.")
                                        .foregroundStyle(Color.gray)
                                        .font(.caption)
                                }
                            }
                        case .nDaysEachMonth:
                            HStack {
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { viewModel.habit.nDaysPerMonth },
                                    set: { viewModel.onSelectNDays($0) }
                                )) {
                                    ForEach(1 ... 28, id: \.self) { nDays in
                                        if nDays == 1 {
                                            Text("\(nDays) day")
                                                .tag(nDays)
                                        } else {
                                            Text("\(nDays) days")
                                                .tag(nDays)
                                        }
                                    }
                                }
                            }
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color.gray)
                                    .font(.caption)
                                if viewModel.habit.nDaysPerMonth == 1 {
                                    Text("After being completed on \(viewModel.habit.nDaysPerWeek) day, the habit will not show up again this month.")
                                        .foregroundStyle(Color.gray)
                                        .font(.caption)
                                } else {
                                    Text("After being completed on \(viewModel.habit.nDaysPerWeek) days, the habit will not show up again this month.")
                                        .foregroundStyle(Color.gray)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Anti-Aging Rating")
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { starIndex in
                                Button(action: {
                                    viewModel.habit.antiAgingRating = starIndex
                                }) {
                                    Image(systemName: starIndex <= viewModel.habit.antiAgingRating ? "star.fill" : "star")
                                        .foregroundColor(starIndex <= viewModel.habit.antiAgingRating ? .yellow : .gray)
                                        .font(.title2)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.quote")
                            Text("Description")
                                .fontWeight(.semibold)
                        }
                        
                        TextEditor(text: $viewModel.habit.note)
                            .frame(minHeight: 50)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Reminders Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Reminders")
                                .fontWeight(.semibold)
                            Spacer()
                            Button("Add Reminder") {
                                viewModel.onTapAddReminder()
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        
                        if viewModel.draftReminders.isEmpty {
                            Text("No reminders set for this habit")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.draftReminders, id: \ .id) { draft in
                                    ReminderDraftRow(
                                        reminder: draft,
                                        onDelete: {
                                            viewModel.onTapDeleteReminder(draft)
                                        }
                                    )
                                    .onTapGesture {
                                        viewModel.onTapEditReminder(draft)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
            .navigationTitle(
                viewModel.isEdit
                ? "Edit Habit"
                : "New Habit"
            )
            .scrollDismissesKeyboard(.immediately)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.isEdit ? "Update" : "Save") {
                        Task {
                            if await viewModel.onTapSaveHabit() {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.habit.frequency) { _, _ in
                viewModel.onChangeOfHabitFrequency()
            }
            .easyToast(isPresented: $viewModel.showTitleEmptyToast, message: "Habit name is empty")
            .sheet(isPresented: Binding($viewModel.route.addReminder)) {
                if case .addReminder(let formViewModel) = viewModel.route {
                    ReminderFormView(viewModel: formViewModel) 
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
                }
            }
            .sheet(isPresented: Binding($viewModel.route.editReminder)) {
                if case .editReminder(let formViewModel) = viewModel.route {
                    ReminderFormView(viewModel: formViewModel)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
                }
            }
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }

    HabitFormView(
        viewModel: HabitFormViewModel(
            habit: Habit.Draft(
                Habit(
                    id: 0,
                    frequency: .nDaysEachWeek
                )
            )
        )
    )
}
