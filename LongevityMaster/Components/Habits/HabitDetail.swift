import Observation
import SharingGRDB
import SwiftUI
import SwiftUINavigation
import Dependencies

@Observable
@MainActor
class HabitDetailViewModel {
    var habit: Habit
    
    @ObservationIgnored
    @FetchAll(CheckIn.all, animation: .default) var allCheckIns: [CheckIn]

    @ObservationIgnored
    @FetchAll(Reminder.all, animation: .default) var allReminders

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    @ObservationIgnored
    @Dependency(\.calendar) var calendar
    
    @ObservationIgnored
    @Dependency(\.notificationService) var notificationService
    
    @ObservationIgnored
    @Dependency(\.achievementService) var achievementService

    @ObservationIgnored
    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true
    
    @ObservationIgnored
    @Dependency(\.soundPlayer) var soundPlayer

    var selectedMonth: Date = Date()
    var selectedYear: Int = Calendar.current.component(.year, from: Date())

    enum CalendarMode: String, CaseIterable, Identifiable {
        case monthly = "Monthly"
        case yearly = "Yearly"
        var id: String { rawValue }
    }

    var calendarMode: CalendarMode = .monthly

    @CasePathable
    enum Route {
        case editHabit(HabitFormViewModel)
        case deleteAlert
        case editReminder(ReminderFormViewModel)
    }

    var route: Route?

    var userCalendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = startWeekOnMonday ? 2 : 1 // 2 = Monday, 1 = Sunday
        return cal
    }

    var checkIns: [CheckIn] {
        allCheckIns.filter { $0.habitID == habit.id }
    }

    var todayHabit: TodayHabit {
        habit.toTodayHabit(
            isCompleted: true,
            streakDescription: habit.frequencyDescription
        )
    }

    var reminders: [Reminder.Draft] {
        allReminders.filter { $0.habitID == habit.id }.map(Reminder.Draft.init)
    }

    var showFavoriteInfo: Bool = false
    var showArchivedInfo: Bool = false

    init(habit: Habit) {
        self.habit = habit
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: selectedMonth)
    }

    var weekdaySymbols: [String] {
        let symbols = userCalendar.shortWeekdaySymbols
        // Start from Monday
        let idx = userCalendar.firstWeekday - 1
        return Array(symbols[idx...] + symbols[..<idx])
    }

    var calendarDays: [Date?] {
        let now = Date()
        let currentHour = userCalendar.component(.hour, from: now)
        let currentMinute = userCalendar.component(.minute, from: now)
        let startOfMonth = selectedMonth.startOfMonth(for: userCalendar)
        let range = userCalendar.range(of: .day, in: .month, for: startOfMonth)!
        let numDays = range.count
        let firstWeekday = userCalendar.component(.weekday, from: startOfMonth)
        let firstWeekdayIdx = (firstWeekday - userCalendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekdayIdx)
        for day in 1 ... numDays {
            if let date = userCalendar.date(bySetting: .day, value: day, of: startOfMonth),
               let dateWithTime = userCalendar.date(bySettingHour: currentHour, minute: currentMinute, second: 0, of: date) {
                days.append(dateWithTime)
            }
        }
        // Fill to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    func isToday(day: Date?) -> Bool {
        guard let day = day else { return false }
        return userCalendar.isDateInToday(day)
    }

    func isChecked(day: Date?) -> Bool {
        guard let day = day else { return false }
        return checkIns.contains { userCalendar.isDate($0.date, inSameDayAs: day) }
    }

    func isCurrentMonth(day: Date?) -> Bool {
        guard let day = day else { return false }
        return userCalendar.isDate(day, equalTo: selectedMonth, toGranularity: .month)
    }

    func previousMonth() {
        if let prev = userCalendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = prev
        }
    }

    func nextMonth() {
        if let next = userCalendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = next
        }
    }

    func toggleCheckIn(for day: Date?) {
        guard let day, isCurrentMonth(day: day) else { return }
        let startOfDay = day.startOfDay(for: userCalendar)
        let endOfDay = day.endOfDay(for: userCalendar)
        if let checkIn = checkIns.first(
            where: {
                $0.date >= startOfDay &&
                    $0.date <= endOfDay &&
                    $0.habitID == habit.id
            }) {
            // Remove check-in
            withErrorReporting {
                try database.write { db in
                    try CheckIn.delete(checkIn).execute(db)
                }
            }
            Task {
                await soundPlayer.playCancelCheckinSound()
            }
        } else {
            // Add check-in
            withErrorReporting {
                try database.write { db in
                    let draft = CheckIn.Draft(date: day, habitID: habit.id)
                    let savedCheckIn = try CheckIn
                        .upsert { draft }
                        .returning(\.self)
                        .fetchOne(db)
                    
                    // Check for achievements after adding check-in
                    if let savedCheckIn {
                        Task {
                            await achievementService.checkAchievementsAndShow(for: savedCheckIn)
                        }
                    }
                }
                Task {
                    await soundPlayer.playCheckinSound()
                }
            }
        }
        print("Toggle check-in called")
        Haptics.vibrateIfEnabled()
    }

    func onTapEditHabit() {
        route = .editHabit(
            HabitFormViewModel(
                habit: Habit.Draft(habit)
            ) { [weak self] updatedHabit in
                guard let self else { return }
                habit = updatedHabit
            }
        )
    }

    func onTapDeleteHabit() {
        route = .deleteAlert
    }

    func deleteHabit() {
        withErrorReporting {
            notificationService.removeRemindersForHabit(habit.id)
            try database.write { db in
                try Habit.delete(habit).execute(db)
            }
        }
    }

    // For yearly view: get all check-ins for a year, grouped by month and day
    func yearlyCheckIns(for year: Int) -> [Int: Set<Int>] {
        // [month: Set<day>]
        var result: [Int: Set<Int>] = [:]
        for checkIn in checkIns {
            let comps = userCalendar.dateComponents([.year, .month, .day], from: checkIn.date)
            if comps.year == year, let month = comps.month, let day = comps.day {
                result[month, default: []].insert(day)
            }
        }
        return result
    }

    func previousYear() {
        selectedYear -= 1
    }

    func nextYear() {
        selectedYear += 1
    }

    func onTapEditReminder(_ reminder: Reminder.Draft) {
        route = .editReminder(
            ReminderFormViewModel(
                reminder: reminder,
                onSave: { [weak self] reminderDraft in
                    guard let self else { return }
                    onUpdateReminder(reminderDraft)
                    route = nil
                }
            )
        )
    }

    func onTapDeleteReminder(_ reminder: Reminder.Draft) {
        onDeleteReminder(reminder)
    }
    
    private func onUpdateReminder(_ reminder: Reminder.Draft) {
        Task {
            await withErrorReporting {
                let updatedReminder = try await database.write { db in
                    try Reminder
                        .upsert { reminder }
                        .returning(\.self)
                        .fetchOne(db)
                }
                if let updatedReminder {
                    await notificationService.scheduleReminder(updatedReminder)
                }
            }
        }
    }
    
    private func onDeleteReminder(_ reminder: Reminder.Draft) {
        Task {
            await withErrorReporting {
                guard let reminderID = reminder.id else { return }
                let reminderToDelete = try await database.read { db in
                    try Reminder.find(reminderID).fetchOne(db)
                }
                if let reminderToDelete {
                    notificationService.removeReminder(reminderToDelete)
                    try await database.write { db in
                        try Reminder.delete(reminderToDelete).execute(db)
                    }
                }
            }
        }
    }
}

struct HabitDetailView: View {
    @State var viewModel: HabitDetailViewModel
    @Dependency(\.themeManager) var themeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                // Main habit card
                HabitItemView(todayHabit: viewModel.todayHabit, onTap: {})
                    .padding(.top, 8)
                    .opacity(viewModel.habit.isArchived ? 0.6 : 1.0)

                // Habit note/description section
                if !viewModel.habit.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    NoteSection(note: viewModel.habit.note)
                }

                // Segmented control for calendar mode
                Picker("Mode", selection: $viewModel.calendarMode) {
                    ForEach(HabitDetailViewModel.CalendarMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                if viewModel.calendarMode == .monthly {
                    monthlyCalendarGrid
                } else {
                    yearlyCalendarGrid
                }

                VStack(spacing: AppSpacing.medium) {
                    FavoriteToggleWithInfo(isOn: $viewModel.habit.isFavorite)
                    Divider()
                    ArchivedToggleWithInfo(isOn: $viewModel.habit.isArchived)
                }
                .appCardStyle(theme: themeManager.current)

                // Reminders Section
                if !viewModel.reminders.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(themeManager.current.primaryColor)
                            Text("Reminders")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        VStack(spacing: AppSpacing.small) {
                            ForEach(viewModel.reminders, id: \.id) { reminder in
                                ReminderRow(
                                    time: reminder.time,
                                    title: "Every Day",
                                    onDelete: {
                                        viewModel.onTapDeleteReminder(reminder)
                                    }
                                )
                                .onTapGesture {
                                    viewModel.onTapEditReminder(reminder)
                                }
                            }
                        }
                    }
                    .appCardStyle(theme: themeManager.current)
                }
            }
            .padding(AppSpacing.medium)
        }
        .background(themeManager.current.background.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    viewModel.onTapDeleteHabit()
                } label: {
                    Image(systemName: "trash")
                }

                Button {
                    viewModel.onTapEditHabit()
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(item: $viewModel.route.editHabit, id: \.self) { habitFormViewModel in
            HabitFormView(
                viewModel: habitFormViewModel
            )
        }
        .alert(
            "Delete '\(viewModel.habit.truncatedName)'?",
            isPresented: Binding($viewModel.route.deleteAlert)
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteHabit()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the habit '\(viewModel.habit.truncatedName)' and all its check-in history. This action cannot be undone. Are you sure you want to proceed?")
        }
    }
    
    private var monthlyCalendarGrid: some View {
        VStack(spacing: AppSpacing.medium) {
            HStack {
                Button(action: { viewModel.previousMonth() }) {
                    Text("< Previous")
                        .font(.subheadline)
                }
                .tint(themeManager.current.primaryColor)
                Spacer()
                Text(viewModel.monthTitle)
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.nextMonth() }) {
                    Text("Next >")
                        .font(.subheadline)
                }
                .tint(themeManager.current.primaryColor)
            }

            // Weekday headers
            HStack {
                ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(themeManager.current.textSecondary)
                }
            }

            // Calendar grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8
            ) {
                ForEach(viewModel.calendarDays, id: \.self) { day in
                    CalendarDayCell(
                        day: day,
                        isToday: viewModel.isToday(day: day),
                        isChecked: viewModel.isChecked(day: day),
                        isCurrentMonth: viewModel.isCurrentMonth(day: day),
                        theme: themeManager.current
                    )
                    .onTapGesture {
                        viewModel.toggleCheckIn(for: day)
                    }
                }
                .opacity(viewModel.habit.isArchived ? 0.6 : 1.0)
                .disabled(viewModel.habit.isArchived)
            }
        }
        .appCardStyle(theme: themeManager.current)
    }
    
    private var yearlyCalendarGrid: some View {
        VStack(spacing: AppSpacing.medium) {
            HStack {
                Button(action: { viewModel.previousYear() }) {
                    Text("< Previous")
                        .font(.subheadline)
                }
                .tint(themeManager.current.primaryColor)
                Spacer()
                Text("\(viewModel.selectedYear)")
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.nextYear() }) {
                    Text("Next >")
                        .font(.subheadline)
                }
                .tint(themeManager.current.primaryColor)
            }
            YearlyCalendarGrid(
                year: viewModel.selectedYear,
                checkInsByMonth: viewModel.yearlyCheckIns(for: viewModel.selectedYear),
                calendar: viewModel.userCalendar,
                theme: themeManager.current
            )
            .opacity(viewModel.habit.isArchived ? 0.6 : 1.0)
            .disabled(viewModel.habit.isArchived)
        }
        .appCardStyle(theme: themeManager.current)
    }
}

struct CalendarDayCell: View {
    let day: Date?
    let isToday: Bool
    let isChecked: Bool
    let isCurrentMonth: Bool
    let theme: AppTheme

    var body: some View {
        Group {
            if let day {
                ZStack {
                    Circle()
                        .fill(isChecked ? theme.primaryColor : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(theme.primaryColor, lineWidth: isToday ? 2 : 0)
                        )
                        .frame(width: 32, height: 32)

                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(.body)
                        .foregroundColor(isCurrentMonth ? (isChecked ? .white : theme.textPrimary) : theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 36)
            } else {
                Text("")
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
        }
    }
}

// Add a new view for yearly grid
struct YearlyCalendarGrid: View {
    let year: Int
    let checkInsByMonth: [Int: Set<Int>]
    let calendar: Calendar
    let theme: AppTheme

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.fixed(30))] + Array(repeating: GridItem(.flexible(minimum: 8, maximum: 20), spacing: 2), count: 31),
            spacing: 10
        ) {
            ForEach(1 ... 12, id: \ .self) { month in
                Text(shortMonthName(for: month))
                    .font(.caption)
                    .frame(width: 30, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                ForEach(1 ... 31, id: \ .self) { day in
                    if day <= daysCount(for: month) {
                        Circle()
                            .fill(checkInsByMonth[month]?.contains(day) == true ? theme.primaryColor : theme.secondaryGray.opacity(0.15))
                    } else {
                        Color.clear
                    }
                }
            }
        }
    }

    func daysCount(for month: Int) -> Int {
        let comps = DateComponents(year: year, month: month)
        return calendar.range(of: .day, in: .month, for: calendar.date(from: comps)!)?.count ?? 30
    }

    func shortMonthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.shortMonthSymbols[month - 1]
    }
}

private struct FavoriteToggleWithInfo: View {
    @Dependency(\.themeManager) var themeManager
    @Binding var isOn: Bool
    @State private var showInfo = false
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $isOn) {
                HStack {
                    Label("Favorite", systemImage: isOn ? "heart.fill" : "heart")
                    Button(action: { withAnimation { showInfo.toggle() } }) {
                        Image(systemName: "info.circle")
                    }
                    .foregroundStyle(themeManager.current.secondaryGray)
                    .buttonStyle(.plain)
                }
            }
            .toggleStyle(SwitchToggleStyle())
            if showInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Once favorited, the habit will be ordered first in today's habits list.")
                        .font(.caption)
                        .foregroundColor(themeManager.current.textPrimary)
                        .appInfoSection()
                }
                .onTapGesture { showInfo = false }
            }
        }
    }
}

private struct ArchivedToggleWithInfo: View {
    @Dependency(\.themeManager) var themeManager
    @Binding var isOn: Bool
    @State private var showInfo = false
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $isOn) {
                HStack {
                    Label("Archived", systemImage: isOn ? "archivebox.fill" : "archivebox")
                    Button(action: { withAnimation { showInfo.toggle() } }) {
                        Image(systemName: "info.circle")
                    }
                    .foregroundStyle(themeManager.current.secondaryGray)
                    .buttonStyle(.plain)
                }
            }
            .toggleStyle(SwitchToggleStyle())
            if showInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Once archived, the habit will be hidden from today's habits list, but its check-ins will be kept.")
                        .font(.caption)
                        .foregroundColor(themeManager.current.textPrimary)
                        .appInfoSection()
                }
                .onTapGesture { showInfo = false }
            }
        }
    }
}

private struct NoteSection: View {
    @Dependency(\.themeManager) var themeManager
    let note: String
    @State private var expanded = false
    @State var showMore: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note)
                .font(.footnote)
                .foregroundColor(themeManager.current.textPrimary)
                .lineLimit(expanded ? nil : 2)

            if note.count > 100 {
                Button {
                    withAnimation {
                        expanded.toggle()
                    }
                } label: {
                    Text(expanded ? "Show less" : "Show more")
                        .font(.footnote)
                        .foregroundColor(themeManager.current.primaryColor)
                }
                .buttonStyle(.plain)
            }
        }
        .appInfoSection()
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    NavigationStack {
        HabitDetailView(
            viewModel: HabitDetailViewModel(
                habit: HabitsDataStore.eatSalmon.toMock
            )
        )
    }
}
