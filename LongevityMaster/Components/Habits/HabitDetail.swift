import Observation
import SharingGRDB
import SwiftUI
import SwiftUINavigation

@Observable
@MainActor
class HabitDetailViewModel {
    var habit: Habit
    
    @ObservationIgnored
    @FetchAll(CheckIn.all, animation: .default) var allCheckIns: [CheckIn]

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    @ObservationIgnored
    @Dependency(\.calendar) var calendar

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
    }
    var route: Route?

    init(habit: Habit) {
        self.habit = habit
    }

    var checkIns: [CheckIn] {
        allCheckIns.filter { $0.habitID == habit.id }
    }

    var todayHabit: TodayHabit {
        habit.toTodayHabit(isCompleted: true)
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: selectedMonth)
    }

    var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        // Start from Monday
        let idx = calendar.firstWeekday - 1
        return Array(symbols[idx...] + symbols[..<idx])
    }

    var calendarDays: [Date?] {
        let startOfMonth = selectedMonth.startOfMonth(for: calendar)
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let numDays = range.count
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let firstWeekdayIdx = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekdayIdx)
        for day in 1 ... numDays {
            if let date = calendar.date(bySetting: .day, value: day, of: startOfMonth) {
                days.append(date)
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
        return calendar.isDateInToday(day)
    }

    func isChecked(day: Date?) -> Bool {
        guard let day = day else { return false }
        return checkIns.contains { calendar.isDate($0.date, inSameDayAs: day) }
    }

    func isCurrentMonth(day: Date?) -> Bool {
        guard let day = day else { return false }
        return calendar.isDate(day, equalTo: selectedMonth, toGranularity: .month)
    }

    func previousMonth() {
        if let prev = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = prev
        }
    }

    func nextMonth() {
        if let next = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = next
        }
    }

    func toggleCheckIn(for day: Date?) {
        guard let day = day, isCurrentMonth(day: day) else { return }
        let startOfDay = day.startOfDay(for: calendar)
        let endOfDay = day.endOfDay(for: calendar)
        if let checkIn = checkIns.first(
            where: {
                $0.date >= startOfDay &&
                $0.date <= endOfDay &&
                $0.habitID == habit.id
            })
        {
            // Remove check-in
            withErrorReporting {
                try database.write { db in
                    try CheckIn.delete(checkIn).execute(db)
                }
            }
        } else {
            // Add check-in
            withErrorReporting {
                try database.write { db in
                    let draft = CheckIn.Draft(date: day, habitID: habit.id)
                    try CheckIn.upsert(draft).execute(db)
                }
            }
        }
    }
    
    func onTapEditHabit() {
        route = .editHabit(
            HabitFormViewModel(
                habit: Habit.Draft(habit)
            ) { [weak self] updatedHabit in
                guard let self else { return }
                habit = updatedHabit.toHabit(id: habit.id)
            }
        )
    }

    // For yearly view: get all check-ins for a year, grouped by month and day
    func yearlyCheckIns(for year: Int) -> [Int: Set<Int>] {
        // [month: Set<day>]
        var result: [Int: Set<Int>] = [:]
        for checkIn in checkIns {
            let comps = calendar.dateComponents([.year, .month, .day], from: checkIn.date)
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
}

struct HabitDetailView: View {
    @State var viewModel: HabitDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HabitItemView(todayHabit: viewModel.todayHabit, onTap: {})
                    .padding(.top, 8)
                
                Text(viewModel.habit.frequencyDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                // Segmented control for calendar mode
                Picker("Mode", selection: $viewModel.calendarMode) {
                    ForEach(HabitDetailViewModel.CalendarMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if viewModel.calendarMode == .monthly {
                    // Calendar
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: { viewModel.previousMonth() }) {
                                Text("< Previous")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text(viewModel.monthTitle)
                                .font(.headline)
                            Spacer()
                            Button(action: { viewModel.nextMonth() }) {
                                Text("Next >")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)
                        // Weekday headers
                        HStack {
                            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                                Text(symbol)
                                    .font(.caption2)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.secondary)
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
                                    isCurrentMonth: viewModel.isCurrentMonth(day: day)
                                )
                                .onTapGesture {
                                    viewModel.toggleCheckIn(for: day)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                } else {
                    
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: { viewModel.previousYear() }) {
                                Text("< Previous")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text("\(viewModel.selectedYear)")
                                .font(.headline)
                            Spacer()
                            Button(action: { viewModel.nextYear() }) {
                                Text("Next >")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)
                        // Yearly grid
                        YearlyCalendarGrid(
                            year: viewModel.selectedYear,
                            checkInsByMonth: viewModel.yearlyCheckIns(for: viewModel.selectedYear),
                            calendar: viewModel.calendar
                        )
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
                Spacer()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
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
    }
}

struct CalendarDayCell: View {
    let day: Date?
    let isToday: Bool
    let isChecked: Bool
    let isCurrentMonth: Bool

    var body: some View {
        Group {
            if let day {
                ZStack {
                    Circle()
                        .fill(isChecked ? Color.accentColor : Color.clear)
                        .stroke(Color.black, lineWidth: isToday ? 2 : 0)
                        .frame(width: 32, height: 32)
                    
                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(.body)
                        .foregroundColor(isCurrentMonth ? (isChecked ? .white : .primary) : .gray)
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
    
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.fixed(30))] + Array(repeating: GridItem(.flexible(minimum: 8, maximum: 20), spacing: 2), count: 31),
            spacing: 10
        ) {
            ForEach(1...12, id: \ .self) { month in
                Text(shortMonthName(for: month))
                    .font(.caption)
                    .frame(width: 30, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                
                ForEach(1...31, id: \ .self) { day in
                    if day <= daysCount(for: month) {
                        Circle()
                            .fill(checkInsByMonth[month]?.contains(day) == true ? Color.accentColor : Color(.systemGray5))
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

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    NavigationStack {
        HabitDetailView(
            viewModel: HabitDetailViewModel(
                habit: HabitsDataStore.eatSalmon
            )
        )
    }
}
