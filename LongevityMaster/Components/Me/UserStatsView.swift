//
//  UserStatsView.swift
//  LongevityMaster
//
//  Created by Banghua Zhao on 2025/1/1
//  Copyright Apps Bay Limited. All rights reserved.
//

import Charts
import SwiftUI
import SQLiteData
import Dependencies
import Sharing

@MainActor
@Observable
class UserStatsViewModel {
    @ObservationIgnored
    @FetchAll(Habit.all, animation: .default) var allHabits
    @ObservationIgnored
    @FetchAll(CheckIn.all, animation: .default) var allCheckIns
    @ObservationIgnored
    @FetchAll(Achievement.all, animation: .default) var allAchievements
    @ObservationIgnored
    @FetchAll(SkippedDay.all, animation: .default) var allSkippedDays
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    @ObservationIgnored
    @Dependency(\.themeManager) var themeManager
    @ObservationIgnored
    @Dependency(\.ratingService) var ratingService
    
    @ObservationIgnored
    @Shared(.appStorage("userName")) var userName: String = String(localized: "Your Name")
    @ObservationIgnored
    @Shared(.appStorage("userAvatar")) var userAvatar: String = "😀"
    
    var totalHabits: Int { allHabits.filter { !$0.isArchived }.count }
    var totalCheckIns: Int { allCheckIns.count }
    var totalAchievements: Int { allAchievements.filter { $0.isUnlocked }.count }
    var totalDaysActive: Int { calculateTotalDaysActive() }
    var longestStreak: Int { calculateLongestStreak() }
    var currentStreak: Int { calculateCurrentStreak() }
    var earliestCheckIn: CheckIn? { findEarliestCheckIn() }
    var earliestCheckInString: String? {
        earliestCheckIn.map { DateFormatter.mediumDate.string(from: $0.date) }
    }
    var categoryStats: [HabitCategory: Int] { calculateCategoryStats() }
    var totalRestDays: Int { allSkippedDays.count }
    
    /// Reading this recomputes the score from every habit, achievement and check-in — so take
    /// one breakdown and read the parts you need off it, rather than asking once per value.
    var longevityScore: LongevityScoreBreakdown { ratingService.calculateLongevityScore() }
    
    /// The start of every day carrying a check-in. Days active and both streak figures are all
    /// questions about this one set, and asking it directly beats sorting the whole table and
    /// then comparing calendar days one check-in at a time.
    private func activeDays(_ calendar: Calendar) -> Set<Date> {
        Set(allCheckIns.map { calendar.startOfDay(for: $0.date) })
    }

    /// The days off that count for the overall streak — the ones taken from every habit at
    /// once. A rest day from a single habit says nothing about whether the user showed up
    /// that day, and several of them did.
    private func restDays(_ calendar: Calendar) -> Set<Date> {
        RestDays(allSkippedDays, in: calendar).everyHabit
    }

    private func calculateTotalDaysActive() -> Int {
        activeDays(Calendar.current).count
    }

    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        return calendar.longestDayStreak(in: activeDays(calendar), skipping: restDays(calendar))
    }

    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        return calendar.currentDayStreak(in: activeDays(calendar), skipping: restDays(calendar))
    }
    
    private func findEarliestCheckIn() -> CheckIn? {
        return allCheckIns.min(by: { $0.date < $1.date })
    }

    /// One habit, and the number the insight row is about it.
    struct HabitInsight {
        let habit: Habit
        let value: Int
    }

    struct HabitInsights {
        /// Most check-ins of any habit.
        let best: HabitInsight?
        /// Longest run of consecutive days any habit was checked in on. A different question
        /// from `best` — these two rows used to run the identical computation and so always
        /// named the same habit, with the same number, under two headings.
        let mostConsistent: HabitInsight?
    }

    /// Derived in one pass. Read this once and take both rows off it rather than asking
    /// separately, which walked the check-ins twice over.
    var habitInsights: HabitInsights {
        let calendar = Calendar.current
        var checkInsByHabit: [Habit.ID: Int] = [:]
        var daysByHabit: [Habit.ID: Set<Date>] = [:]
        for checkIn in allCheckIns {
            checkInsByHabit[checkIn.habitID, default: 0] += 1
            daysByHabit[checkIn.habitID, default: []].insert(calendar.startOfDay(for: checkIn.date))
        }

        let restDays = RestDays(allSkippedDays, in: calendar)

        var best: HabitInsight?
        var mostConsistent: HabitInsight?
        for habit in allHabits {
            if let count = checkInsByHabit[habit.id], count > best?.value ?? 0 {
                best = HabitInsight(habit: habit, value: count)
            }
            if let days = daysByHabit[habit.id] {
                let streak = calendar.longestDayStreak(in: days, skipping: restDays.forHabit(habit.id))
                if streak > mostConsistent?.value ?? 0 {
                    mostConsistent = HabitInsight(habit: habit, value: streak)
                }
            }
        }

        return HabitInsights(best: best, mostConsistent: mostConsistent)
    }
    
    /// One day of the activity chart.
    struct DailyActivity: Identifiable {
        var id: Date { day }
        let day: Date
        let count: Int
        /// Drawn differently, so an empty bar on a day off does not read as a day missed.
        let isRestDay: Bool
    }

    /// Check-ins per day over the last four weeks, empty days included — plotting only the
    /// days that have data draws a run of activity that never happened.
    var recentActivity: [DailyActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let rest = restDays(calendar)

        var countsByDay: [Date: Int] = [:]
        for checkIn in allCheckIns {
            countsByDay[calendar.startOfDay(for: checkIn.date), default: 0] += 1
        }

        return (0 ..< 28).reversed().compactMap { daysAgo in
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            return DailyActivity(
                day: day,
                count: countsByDay[day] ?? 0,
                isRestDay: rest.contains(day)
            )
        }
    }

    /// One bar of the category chart.
    struct CategoryTotal: Identifiable {
        var id: Int { category.rawValue }
        let category: HabitCategory
        let count: Int
    }

    /// Biggest first, and only the categories the user actually has check-ins in.
    var categoryTotals: [CategoryTotal] {
        let stats = categoryStats
        return HabitCategory.allCases
            .compactMap { category in
                guard let count = stats[category], count > 0 else { return nil }
                return CategoryTotal(category: category, count: count)
            }
            .sorted { $0.count > $1.count }
    }

    private func calculateCategoryStats() -> [HabitCategory: Int] {
        // Tallied in one pass. Filtering the whole check-in table once per habit meant every
        // habit walked every check-in.
        var countsByHabit: [Habit.ID: Int] = [:]
        for checkIn in allCheckIns {
            countsByHabit[checkIn.habitID, default: 0] += 1
        }

        var stats: [HabitCategory: Int] = [:]
        for habit in allHabits where !habit.isArchived {
            stats[habit.category, default: 0] += countsByHabit[habit.id] ?? 0
        }

        return stats
    }
    
    func generateShareText() -> String {
        let score = longevityScore
        let bestHabitName = habitInsights.best?.habit.name ?? String(localized: "No habits yet")
        let earliestDate = earliestCheckIn?.date ?? Date()
        
        return """
        📊 My Longevity Master Stats
        
        🏆 Longevity Rating: \(score.rating.displayName) (\(score.rating.description))
        📈 Total Score: \(score.totalScore) points
        🎯 Total Habits: \(totalHabits)
        ✅ Total Check-ins: \(totalCheckIns)
        🏆 Achievements Unlocked: \(totalAchievements)
        📅 Days Active: \(totalDaysActive)
        🔥 Longest Streak: \(longestStreak) days
        ⚡ Current Streak: \(currentStreak) days
        🌟 Best Habit: \(bestHabitName)
        🕐 Started: \(DateFormatter.mediumDate.string(from: earliestDate))
        
        #LongevityMaster #HealthyHabits #Wellness
        """
    }
}

struct UserStatsView: View {
    @State private var viewModel = UserStatsViewModel()
    @Environment(\.openURL) private var openURL
    @State private var showShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                // Header Section
                headerSection
                
                // Longevity Rating Section
                longevityRatingSection
                
                // Key Stats Section
                keyStatsSection
                
                // Streak Section
                streakSection

                // Activity Section
                activitySection
                
                // Habit Insights Section
                habitInsightsSection
                
                // Category Breakdown Section
                categoryBreakdownSection
                
                // Share Section
                shareSection
            }
            .padding(.horizontal)
        }
        .background(viewModel.themeManager.current.background)
        .navigationTitle("My Stats")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [viewModel.generateShareText()])
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: AppSpacing.medium) {
            Text(viewModel.userAvatar)
                .font(.system(size: 60))
                .frame(width: 80, height: 80)
                .background(viewModel.themeManager.current.card)
                .clipShape(Circle())
                .shadow(color: AppShadow.card.color, radius: 8, x: 0, y: 4)
            
            Text(viewModel.userName)
                .font(AppFont.title)
                .fontWeight(.bold)
                .foregroundColor(viewModel.themeManager.current.textPrimary)
        }
        .appCardStyle()
    }
    
    private var longevityRatingSection: some View {
        let score = viewModel.longevityScore

        return VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Longevity Rating"))
                .appSectionHeader(theme: viewModel.themeManager.current)
            
            VStack(spacing: AppSpacing.medium) {
                // Rating Display
                HStack(spacing: AppSpacing.large) {
                    VStack(spacing: AppSpacing.small) {
                        Text(score.rating.displayName)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(score.rating.color)
                        
                        Text(score.rating.description)
                            .font(AppFont.subheadline)
                            .foregroundColor(viewModel.themeManager.current.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: AppSpacing.small) {
                        Text("\(score.totalScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(viewModel.themeManager.current.primaryColor)
                        
                        Text(String(localized: "points"))
                            .font(AppFont.caption)
                            .foregroundColor(viewModel.themeManager.current.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .appCardStyle()
    }
    
    private var keyStatsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Key Statistics"))
                .appSectionHeader(theme: viewModel.themeManager.current)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.medium) {
                statCard(
                    icon: "list.bullet",
                    title: String(localized: "Total Habits"),
                    value: "\(viewModel.totalHabits)",
                    color: .blue
                )
                
                statCard(
                    icon: "checkmark.circle.fill",
                    title: String(localized: "Total Check-ins"),
                    value: "\(viewModel.totalCheckIns)",
                    color: .green
                )
                
                statCard(
                    icon: "trophy.fill",
                    title: String(localized: "Achievements"),
                    value: "\(viewModel.totalAchievements)",
                    color: .orange
                )
                
                statCard(
                    icon: "calendar",
                    title: String(localized: "Days Active"),
                    value: "\(viewModel.totalDaysActive)",
                    color: .purple
                )
            }
        }
        .appCardStyle()
    }
    
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Streak Information"))
                .appSectionHeader(theme: viewModel.themeManager.current)
            
            HStack(spacing: AppSpacing.large) {
                VStack(spacing: AppSpacing.small) {
                    Text("🔥")
                        .font(.system(size: 40))
                    Text("\(viewModel.longestStreak)")
                        .font(AppFont.title)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.themeManager.current.primaryColor)
                    Text(String(localized: "Longest Streak"))
                        .font(AppFont.caption)
                        .foregroundColor(viewModel.themeManager.current.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: AppSpacing.small) {
                    Text("⚡")
                        .font(.system(size: 40))
                    Text("\(viewModel.currentStreak)")
                        .font(AppFont.title)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.themeManager.current.primaryColor)
                    Text(String(localized: "Current Streak"))
                        .font(AppFont.caption)
                        .foregroundColor(viewModel.themeManager.current.textSecondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: AppSpacing.small) {
                    Text("😌")
                        .font(.system(size: 40))
                    Text("\(viewModel.totalRestDays)")
                        .font(AppFont.title)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.themeManager.current.primaryColor)
                    Text(String(localized: "Rest Days"))
                        .font(AppFont.caption)
                        .foregroundColor(viewModel.themeManager.current.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .appCardStyle()
    }

    private var activitySection: some View {
        let theme = viewModel.themeManager.current

        return VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Last 4 Weeks"))
                .appSectionHeader(theme: theme)

            Chart {
                ForEach(viewModel.recentActivity) { day in
                    BarMark(
                        x: .value(String(localized: "Day"), day.day, unit: .day),
                        y: .value(String(localized: "Check-ins"), day.count)
                    )
                    .foregroundStyle(day.isRestDay ? theme.secondaryGray : theme.primaryColor)
                    .cornerRadius(2)
                }

                // A rest day usually has no check-ins, and a bar of height zero is invisible —
                // which would leave the chart unable to tell a day off from a day missed, the
                // one distinction it is here to draw. A marker on the baseline says "nothing
                // here on purpose" without claiming a count the day did not have.
                ForEach(viewModel.recentActivity.filter(\.isRestDay)) { day in
                    PointMark(
                        x: .value(String(localized: "Day"), day.day, unit: .day),
                        y: .value(String(localized: "Check-ins"), 0)
                    )
                    .symbol(.square)
                    .symbolSize(30)
                    .foregroundStyle(theme.secondaryGray)
                }
            }
            .chartXAxis {
                // A label per day is unreadable at this width; a week apart is the most that
                // fits and is what the eye is looking for anyway.
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 140)

            HStack(spacing: AppSpacing.small) {
                Circle()
                    .fill(theme.secondaryGray)
                    .frame(width: 8, height: 8)
                Text("Grey marks are rest days.")
                    .font(AppFont.footnote)
                    .foregroundColor(theme.textSecondary)
                Spacer(minLength: 0)
            }
        }
        .appCardStyle()
    }
    
    @ViewBuilder
    private var habitInsightsSection: some View {
        // Read once: both rows come off the same pass over the check-ins.
        let insights = viewModel.habitInsights

        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Habit Insights"))
                .appSectionHeader(theme: viewModel.themeManager.current)
            
            VStack(spacing: AppSpacing.medium) {
                if let best = insights.best {
                    insightRow(
                        icon: "🌟",
                        title: String(localized: "Best Habit"),
                        subtitle: best.habit.name,
                        detail: String(localized: "\(best.value) check-ins")
                    )
                }
                
                if let earliestCheckInString = viewModel.earliestCheckInString {
                    insightRow(
                        icon: "🕐",
                        title: String(localized: "Started Journey"),
                        subtitle: earliestCheckInString,
                        detail: String(localized: "First check-in")
                    )
                }
                
                if let mostConsistent = insights.mostConsistent {
                    insightRow(
                        icon: "📈",
                        title: String(localized: "Most Consistent"),
                        subtitle: mostConsistent.habit.name,
                        // Two keys rather than one, the way the habit form already handles it:
                        // the catalog has no plural rule to lean on.
                        detail: mostConsistent.value == 1
                            ? String(localized: "\(mostConsistent.value) day in a row")
                            : String(localized: "\(mostConsistent.value) days in a row")
                    )
                }
            }
        }
        .appCardStyle()
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Category Breakdown"))
                .appSectionHeader(theme: viewModel.themeManager.current)
            
            let totals = viewModel.categoryTotals
            if totals.isEmpty {
                Text("No check-ins yet.")
                    .font(AppFont.body)
                    .foregroundColor(viewModel.themeManager.current.textSecondary)
            } else {
                Chart(totals) { total in
                    BarMark(
                        x: .value(String(localized: "Check-ins"), total.count),
                        y: .value(String(localized: "Category"), total.category.briefTitle)
                    )
                    .foregroundStyle(viewModel.themeManager.current.primaryColor)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(total.count)")
                            .font(AppFont.caption)
                            .foregroundColor(viewModel.themeManager.current.textSecondary)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                    }
                }
                // Grows with the number of categories rather than squashing them into a
                // fixed box: five rows in the space of two is unreadable.
                .frame(height: CGFloat(totals.count) * 34 + 16)
            }
        }
        .appCardStyle()
    }
    
    private var shareSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Share Your Progress"))
                .appSectionHeader(theme: viewModel.themeManager.current)
            
            Button(action: {
                showShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                    Text(String(localized: "Share My Stats"))
                        .font(AppFont.body)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundColor(.white)
                .padding()
                .background(viewModel.themeManager.current.primaryColor)
                .cornerRadius(AppCornerRadius.button)
            }
        }
        .appCardStyle()
    }
    
    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(AppFont.headline)
                .fontWeight(.bold)
                .foregroundColor(viewModel.themeManager.current.textPrimary)
            
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(viewModel.themeManager.current.textSecondary)
                .multilineTextAlignment(.center)
        }
        .appCardStyle()
    }
    
    private func insightRow(icon: String, title: String, subtitle: String, detail: String) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.caption)
                    .foregroundColor(viewModel.themeManager.current.textSecondary)
                
                Text(subtitle)
                    .font(AppFont.body)
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.themeManager.current.textPrimary)
                
                Text(detail)
                    .font(AppFont.caption)
                    .foregroundColor(viewModel.themeManager.current.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        UserStatsView()
    }
} 
