import Observation
import SQLiteData
import SwiftUI
import SwiftUINavigation
import Dependencies
import Sharing

@Observable
@MainActor
class HabitDetailViewModel {
    var habit: Habit
    
    /// Scoped to this habit in `init`. The detail screen only ever shows one habit's history,
    /// so reading the whole table meant holding — and re-filtering — every other habit's
    /// check-ins as well.
    @ObservationIgnored
    @FetchAll var checkIns: [CheckIn]

    /// Not scoped to this habit: a day off from everything counts here too, and the table
    /// holds a handful of rows at most.
    @ObservationIgnored
    @FetchAll(SkippedDay.all, animation: .default) var allSkippedDays

    @ObservationIgnored
    @FetchAll(Reminder.all, animation: .default) var allReminders

    @ObservationIgnored
    @FetchAll(Achievement.all, animation: .default) var allAchievements

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    @ObservationIgnored
    @Dependency(\.calendar) var calendar
    
    @ObservationIgnored
    @Dependency(\.notificationService) var notificationService
    
    @ObservationIgnored
    @Dependency(\.achievementService) var achievementService
    
    @ObservationIgnored
    @Dependency(\.appRatingService) var appRatingService

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
        
        var displayName: String {
            switch self {
            case .monthly: String(localized: "Monthly")
            case .yearly: String(localized: "Yearly")
            }
        }
    }

    var calendarMode: CalendarMode = .monthly

    @CasePathable
    enum Route {
        case editHabit(HabitFormViewModel)
        case deleteAlert
        case editReminder(ReminderFormViewModel)
        case showAchievement(Achievement)
    }

    var route: Route?

    var userCalendar: Calendar {
        .userPreferred(startWeekOnMonday: startWeekOnMonday)
    }

    /// The days off that count for this habit: its own, plus the days off from everything.
    var restDays: Set<Date> {
        RestDays(allSkippedDays, in: userCalendar).forHabit(habit.id)
    }

    var todayHabit: TodayHabit {
        let calendar = Calendar.current
        let activeDays = Set(checkIns.map { calendar.startOfDay(for: $0.date) })
        let streak = calendar.currentDayStreak(
            in: activeDays,
            skipping: RestDays(allSkippedDays, in: calendar).forHabit(habit.id)
        )
        let streakDescription = streak > 0 ? String(localized: "🔥 \(streak)d streak") : nil
        return habit.toTodayHabit(
            isCompleted: true,
            streakDescription: streakDescription,
            frequencyDescription: habit.frequencyDescription
        )
    }

    var reminders: [Reminder.Draft] {
        allReminders.filter { $0.habitID == habit.id }.map(Reminder.Draft.init)
    }

    var habitAchievements: [Achievement] {
        allAchievements.filter { achievement in
            achievement.habitID == habit.id
        }.sorted { $0.unlockedDate ?? Date() > $1.unlockedDate ?? Date() }
    }

    var showFavoriteInfo: Bool = false
    var showArchivedInfo: Bool = false

    init(habit: Habit) {
        self.habit = habit
        _checkIns = FetchAll(CheckIn.where { $0.habitID.eq(habit.id) }, animation: .default)
    }

    private static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    var monthTitle: String {
        Self.monthTitleFormatter.string(from: selectedMonth)
    }

    var weekdaySymbols: [String] {
        let symbols = userCalendar.shortWeekdaySymbols
        // Start from Monday
        let idx = userCalendar.firstWeekday - 1
        return Array(symbols[idx...] + symbols[..<idx])
    }

    /// One cell of the month grid, with everything it needs already decided.
    struct CalendarCell: Identifiable {
        /// Position in the grid. The leading and trailing blanks are not distinguishable by
        /// value, so they need a positional identity of their own.
        let id: Int
        let date: Date?
        let isToday: Bool
        let isChecked: Bool
        /// A day declared off. It is drawn differently and counts for neither side of the
        /// streak — see `SkippedDay`.
        let isRestDay: Bool
        let isCurrentMonth: Bool
    }

    /// The month's grid, built in a single pass. Asking each cell in turn meant deriving a
    /// Calendar — and re-reading UserDefaults — three times per cell, and answering "is this
    /// day checked?" by rescanning the check-ins with a calendar comparison apiece.
    var calendarCells: [CalendarCell] {
        let cal = userCalendar
        let checkedDays = Set(checkIns.map { cal.startOfDay(for: $0.date) })
        let restDays = RestDays(allSkippedDays, in: cal).forHabit(habit.id)

        return calendarDays(for: cal).enumerated().map { index, day in
            guard let day else {
                return CalendarCell(
                    id: index,
                    date: nil,
                    isToday: false,
                    isChecked: false,
                    isRestDay: false,
                    isCurrentMonth: false
                )
            }
            let startOfDay = cal.startOfDay(for: day)
            return CalendarCell(
                id: index,
                date: day,
                isToday: cal.isDateInToday(day),
                isChecked: checkedDays.contains(startOfDay),
                isRestDay: restDays.contains(startOfDay),
                isCurrentMonth: cal.isDate(day, equalTo: selectedMonth, toGranularity: .month)
            )
        }
    }

    private func calendarDays(for cal: Calendar) -> [Date?] {
        let now = Date()
        let currentHour = cal.component(.hour, from: now)
        let currentMinute = cal.component(.minute, from: now)
        let startOfMonth = selectedMonth.startOfMonth(for: cal)
        let range = cal.range(of: .day, in: .month, for: startOfMonth)!
        let numDays = range.count
        let firstWeekday = cal.component(.weekday, from: startOfMonth)
        let firstWeekdayIdx = (firstWeekday - cal.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekdayIdx)
        for day in 1 ... numDays {
            if let date = cal.date(bySetting: .day, value: day, of: startOfMonth),
               let dateWithTime = cal.date(bySettingHour: currentHour, minute: currentMinute, second: 0, of: date) {
                days.append(dateWithTime)
            }
        }
        // Fill to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
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
                try database.write { [habit] db in
                    // A day cannot be both done and rested.
                    try SkippedDay
                        .where { $0.habitID.eq(habit.id) }
                        .where { $0.date.between(startOfDay, and: endOfDay) }
                        .delete()
                        .execute(db)

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
        Task { await notificationService.syncAllReminders() }
        Haptics.shared.vibrateIfEnabled()
    }

    /// Declares a day off for this habit, or takes the declaration back. A rest day and a
    /// check-in are mutually exclusive — resting is not doing — so marking one clears the
    /// other.
    func toggleRestDay(for day: Date?) {
        guard let day, isCurrentMonth(day: day) else { return }
        let calendar = userCalendar
        let startOfDay = day.startOfDay(for: calendar)
        let endOfDay = day.endOfDay(for: calendar)
        // Only this habit's own rest days are the user's to toggle here. A day off from
        // everything is set on the Today tab and would be surprising to clear from inside one
        // habit's calendar.
        let existing = allSkippedDays.first {
            $0.habitID == habit.id && $0.date >= startOfDay && $0.date <= endOfDay
        }

        withErrorReporting {
            try database.write { [habit] db in
                if let existing {
                    try SkippedDay.delete(existing).execute(db)
                } else {
                    try CheckIn
                        .where { $0.habitID.eq(habit.id) }
                        .where { $0.date.between(startOfDay, and: endOfDay) }
                        .delete()
                        .execute(db)
                    try SkippedDay
                        .upsert { SkippedDay.Draft(date: day, habitID: habit.id) }
                        .execute(db)
                }
            }
            WidgetRefresher.reload()
            Task { await notificationService.syncAllReminders() }
        }
        Haptics.shared.vibrateIfEnabled()
    }

    func onTapEditHabit() {
        route = .editHabit(
            HabitFormViewModel(
                habit: Habit.Draft(habit)
            ) { [weak self] updatedHabit in
                guard let self else { return }
                habit = updatedHabit
                // Increment habit modification count for rating prompts
                appRatingService.incrementHabitModificationCount()
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
        let cal = userCalendar
        var result: [Int: Set<Int>] = [:]
        for checkIn in checkIns {
            let comps = cal.dateComponents([.year, .month, .day], from: checkIn.date)
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
    
    func onTapAchievement(_ achievement: Achievement) {
        route = .showAchievement(achievement)
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
                        Text(mode.displayName).tag(mode)
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
                                    title: viewModel.habit.frequencyDescription,
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

                // Achievements Section
                if !viewModel.habitAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(themeManager.current.primaryColor)
                            Text("Achievements")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        VStack(spacing: AppSpacing.small) {
                            ForEach(viewModel.habitAchievements, id: \.id) { achievement in
                                HabitAchievementRowView(achievement: achievement)
                                    .onTapGesture {
                                        viewModel.onTapAchievement(achievement)
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
                        .appToolbarCircularButtonStyle(overrideColor: .red)
                }

                Button {
                    viewModel.onTapEditHabit()
                } label: {
                    Image(systemName: "pencil")
                        .appToolbarCircularButtonStyle()
                }
            }
        }
        .sheet(item: $viewModel.route.editHabit, id: \.self) { habitFormViewModel in
            HabitFormView(
                viewModel: habitFormViewModel
            )
        }
        .sheet(item: $viewModel.route.showAchievement) { achievement in
            AchievementPopupView(
                achievement: achievement,
                isPresented: Binding(
                    get: { viewModel.route.showAchievement != nil },
                    set: { if !$0 { viewModel.route = nil } }
                )
            )
        }
        .alert(
            "Delete ‘\(viewModel.habit.truncatedName)’?",
            isPresented: Binding($viewModel.route.deleteAlert)
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteHabit()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the habit ‘\(viewModel.habit.truncatedName)’ and all its check-in history. This action cannot be undone. Are you sure you want to proceed?")
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
                ForEach(viewModel.calendarCells) { cell in
                    CalendarDayCell(
                        day: cell.date,
                        isToday: cell.isToday,
                        isChecked: cell.isChecked,
                        isRestDay: cell.isRestDay,
                        isCurrentMonth: cell.isCurrentMonth,
                        theme: themeManager.current
                    )
                    .onTapGesture {
                        viewModel.toggleCheckIn(for: cell.date)
                    }
                    .onLongPressGesture {
                        viewModel.toggleRestDay(for: cell.date)
                    }
                }
                .opacity(viewModel.habit.isArchived ? 0.6 : 1.0)
                .disabled(viewModel.habit.isArchived)
            }

            restDayLegend
        }
        .appCardStyle(theme: themeManager.current)
    }

    /// The long press has nothing to advertise it, so the calendar says what it does.
    private var restDayLegend: some View {
        HStack(spacing: AppSpacing.small) {
            Circle()
                .strokeBorder(themeManager.current.secondaryGray, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(width: 14, height: 14)
            Text("Hold a day to mark it a rest day — your streak counts straight through it.")
                .font(AppFont.footnote)
                .foregroundColor(themeManager.current.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
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
                // Not "\(selectedYear)": interpolating an Int into a LocalizedStringKey runs it
                // through a number formatter, which renders 2026 as "2,026".
                Text(verbatim: String(viewModel.selectedYear))
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
    var isRestDay: Bool = false
    let isCurrentMonth: Bool
    let theme: AppTheme

    /// A rest day is drawn as an outline rather than a fill: it is deliberately not a
    /// check-in, and should not read as one at a glance.
    private var dayNumberColor: Color {
        guard isCurrentMonth else { return theme.textSecondary }
        if isChecked { return .white }
        if isRestDay { return theme.textSecondary }
        return theme.textPrimary
    }

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

                    if isRestDay, !isChecked {
                        Circle()
                            .strokeBorder(
                                theme.secondaryGray,
                                style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])
                            )
                            .frame(width: 32, height: 32)
                    }

                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(.body)
                        .foregroundColor(dayNumberColor)
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

    private static let monthSymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.shortMonthSymbols
    }()

    func shortMonthName(for month: Int) -> String {
        Self.monthSymbols[month - 1]
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

struct HabitAchievementRowView: View {
    let achievement: Achievement
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Text(achievement.icon)
                    .font(.title3)
            }
            
            // Achievement details
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.current.textPrimary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(themeManager.current.textSecondary)
                    .lineLimit(2)
                
                if let unlockDate = achievement.unlockedDate {
                    Text("Unlocked \(unlockDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                ShareLink(
                    item: createAchievementShareText(achievement),
                    subject: Text("Achievement Unlocked!"),
                    message: Text("Check out this achievement I unlocked in LongevityMaster!")
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(themeManager.current.primaryColor)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.current.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.current.card)
        )
    }
    
    func createAchievementShareText(_ achievement: Achievement) -> String {
        let appName = "LongevityMaster"
        let appStoreURL = "https://apps.apple.com/app/id\(Constants.AppID.longevityMasterID)"
        
        var shareText = "🎉 Achievement Unlocked! 🎉\n\n"
        shareText += "🏆 \(achievement.title)\n"
        shareText += "📝 \(achievement.description)\n\n"
        
        if let unlockDate = achievement.unlockedDate {
            shareText += "📅 Unlocked on \(DateFormatter.mediumDate.string(from: unlockDate))\n\n"
        }
        
        shareText += "💪 Keep building healthy habits with \(appName)!\n"
        shareText += "📱 Download: \(appStoreURL)"
        
        return shareText
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
