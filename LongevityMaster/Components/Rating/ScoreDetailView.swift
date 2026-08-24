//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SQLiteData
import Sharing

struct ScoreDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: ScoreDetailViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    progressSection
                    statisticsSection
                    tipsSection
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(viewModel.category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button{
                        dismiss()
                    } label: {
                       Text(String(localized: "Done"))
                           .appToolbarRectButtonStyle()
                   }
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: viewModel.category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.category.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.category.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(String(localized: "Score: \(viewModel.currentScore)/\(viewModel.category.maxScore)"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text(String(localized: "Progress"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String("\(Int(viewModel.percentage * 100))%"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: viewModel.percentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: viewModel.category.color))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .appCardStyle()
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "How It's Calculated"))
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(viewModel.category.calculationExplanation)
                .font(.callout)
                .foregroundColor(.secondary)
                .appInfoSection()
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Your Statistics"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.statistics, id: \.title) { stat in
                    StatCard(title: stat.title, value: stat.value, subtitle: stat.subtitle, color: viewModel.category.color)
                }
            }
        }
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Tips to Improve"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(viewModel.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(viewModel.category.color)
                            .font(.system(size: 16))
                        
                        Text(tip)
                            .font(.callout)
                            .foregroundColor(ThemeManager.shared.current.textSecondary)
                        
                        Spacer()
                    }
                    .appInfoSection()
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

@Observable
class ScoreDetailViewModel: HashableObject {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    @ObservationIgnored
    @FetchAll(Habit.all, animation: .default) var allHabits
    
    @ObservationIgnored
    @FetchAll(Achievement.all, animation: .default) var allAchievements
    
    @ObservationIgnored
    @FetchAll(CheckIn.all, animation: .default) var allCheckIns
    
    @ObservationIgnored
    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true
    
    let category: ScoreCategory
    var currentScore: Int = 0
    var percentage: Double = 0.0
    var statistics: [Statistic] = []
    var tips: [String] = []
    
    var userCalendar: Calendar {
        .userPreferred(startWeekOnMonday: startWeekOnMonday)
    }
    
    init(category: ScoreCategory) {
        self.category = category
    }
    
    func loadData() async {
        switch category {
        case .activeHabits:
            await loadActiveHabitsData()
        case .antiAgingRating:
            await loadAntiAgingData()
        case .achievements:
            await loadAchievementsData()
        case .totalCheckIns:
            await loadCheckInsData()
        case .longestStreak:
            await loadStreakData()
        }
    }
    
    private func loadActiveHabitsData() async {
        let activeHabits = allHabits.filter { !$0.isArchived }
        currentScore = min(activeHabits.count * 10, ScoreCategory.activeHabits.maxScore)
        percentage = Double(currentScore) / Double(ScoreCategory.activeHabits.maxScore)
        
        statistics = [
            Statistic(title: String(localized: "Active Habits"), value: "\(activeHabits.count)", subtitle: String(localized: "out of 30")),
            Statistic(title: String(localized: "Archived Habits"), value: "\(allHabits.filter { $0.isArchived }.count)", subtitle: String(localized: "not counted")),
            Statistic(title: String(localized: "Categories"), value: "\(Set(activeHabits.map { $0.category }).count)", subtitle: String(localized: "variety")),
            Statistic(title: String(localized: "Favorites"), value: "\(activeHabits.filter { $0.isFavorite }.count)", subtitle: String(localized: "starred"))
        ]
        
        tips = [
            String(localized: "Create new habits to increase your score"),
            String(localized: "Archive unused habits to keep your list clean"),
            String(localized: "Try habits from different categories for variety"),
            String(localized: "Mark your most important habits as favorites")
        ]
    }
    
    private func loadAntiAgingData() async {
        let activeHabits = allHabits.filter { !$0.isArchived }
        let totalRating = activeHabits.reduce(0) { $0 + $1.antiAgingRating }
        currentScore = min(totalRating * 2, ScoreCategory.antiAgingRating.maxScore)
        percentage = Double(currentScore) / Double(ScoreCategory.antiAgingRating.maxScore)
        
        let averageRating = activeHabits.isEmpty ? 0 : Double(totalRating) / Double(activeHabits.count)
        
        statistics = [
            Statistic(title: String(localized: "Total Rating"), value: "\(totalRating)", subtitle: String(localized: "points")),
            Statistic(title: String(localized: "Average Rating"), value: String(format: "%.1f", averageRating), subtitle: String(localized: "per habit")),
            Statistic(title: String(localized: "5-Star Habits"), value: "\(activeHabits.filter { $0.antiAgingRating == 5 }.count)", subtitle: String(localized: "maximum impact")),
            Statistic(title: String(localized: "High Impact"), value: "\(activeHabits.filter { $0.antiAgingRating >= 4 }.count)", subtitle: String(localized: "4-5 stars"))
        ]
        
        tips = [
            String(localized: "Focus on habits with 4-5 star anti-aging ratings"),
            String(localized: "Replace low-impact habits with higher-rated ones"),
            String(localized: "Consider the cumulative effect of multiple habits"),
            String(localized: "Balance high-impact habits with sustainable ones")
        ]
    }
    
    private func loadAchievementsData() async {
        let unlockedAchievements = allAchievements.filter { $0.isUnlocked }
        currentScore = min(unlockedAchievements.count * 10, ScoreCategory.achievements.maxScore)
        percentage = Double(currentScore) / Double(ScoreCategory.achievements.maxScore)
        
        let recentUnlocks = unlockedAchievements.filter { 
            guard let unlockDate = $0.unlockedDate else { return false }
            return userCalendar.isDate(unlockDate, inSameDayAs: Date()) || 
                   userCalendar.isDate(unlockDate, inSameDayAs: userCalendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        }
        
        statistics = [
            Statistic(title: String(localized: "Unlocked"), value: "\(unlockedAchievements.count)", subtitle: String(localized: "achievements")),
            Statistic(title: String(localized: "Available"), value: "\(allAchievements.count)", subtitle: String(localized: "total")),
            Statistic(title: String(localized: "Recent"), value: "\(recentUnlocks.count)", subtitle: String(localized: "last 2 days")),
            Statistic(title: String(localized: "Progress"), value: "\(Int(percentage * 100))%", subtitle: String(localized: "complete"))
        ]
        
        tips = [
            String(localized: "Complete daily habits to unlock streak achievements"),
            String(localized: "Try different habit categories for variety achievements"),
            String(localized: "Check in consistently to reach milestone achievements"),
            String(localized: "Complete habits early or late for time-based achievements")
        ]
    }
    
    private func loadCheckInsData() async {
        currentScore = min(allCheckIns.count * 2, ScoreCategory.totalCheckIns.maxScore)
        percentage = Double(currentScore) / Double(ScoreCategory.totalCheckIns.maxScore)
        
        // Taken once: `userCalendar` builds a Calendar and reads UserDefaults on every access.
        let calendar = userCalendar
        let today = Date()
        let startOfWeek = today.startOfWeek(for: calendar)
        let startOfMonth = today.startOfMonth(for: calendar)

        var thisWeek = 0
        var thisMonth = 0
        var earliest: Date?
        for checkIn in allCheckIns {
            if checkIn.date >= startOfWeek { thisWeek += 1 }
            if checkIn.date >= startOfMonth { thisMonth += 1 }
            // `allCheckIns` is unordered, so the earliest has to be looked for. Reading
            // `first` took whatever row the database happened to return, which is the order
            // check-ins were entered — and people back-date them.
            earliest = min(earliest ?? checkIn.date, checkIn.date)
        }

        statistics = [
            Statistic(title: String(localized: "Total Check-ins"), value: "\(allCheckIns.count)", subtitle: String(localized: "all time")),
            Statistic(title: String(localized: "This Week"), value: "\(thisWeek)", subtitle: String(localized: "recent activity")),
            Statistic(title: String(localized: "This Month"), value: "\(thisMonth)", subtitle: String(localized: "monthly progress")),
            Statistic(
                title: String(localized: "Average/Day"),
                value: String(format: "%.1f", Double(allCheckIns.count) / Double(daysTracked(since: earliest, until: today, calendar: calendar))),
                subtitle: String(localized: "consistency")
            )
        ]
        
        tips = [
            String(localized: "Check in daily to build consistency"),
            String(localized: "Don't break your streak - even one check-in counts"),
            String(localized: "Use reminders to never miss a day"),
            String(localized: "Celebrate milestones to stay motivated")
        ]
    }
    
    private func loadStreakData() async {
        let longestStreak = calculateLongestStreak()
        currentScore = min(longestStreak * 2, ScoreCategory.longestStreak.maxScore)
        percentage = Double(currentScore) / Double(ScoreCategory.longestStreak.maxScore)
        
        let currentStreak = calculateCurrentStreak()
        let averageStreak = calculateAverageStreak()
        
        statistics = [
            Statistic(title: String(localized: "Longest Streak"), value: "\(longestStreak)", subtitle: String(localized: "days")),
            Statistic(title: String(localized: "Current Streak"), value: "\(currentStreak)", subtitle: String(localized: "days")),
            Statistic(title: String(localized: "Average Streak"), value: String(format: "%.1f", averageStreak), subtitle: String(localized: "days")),
            Statistic(title: String(localized: "Streak Goal"), value: "125", subtitle: String(localized: "days max"))
        ]
        
        tips = [
            String(localized: "Never miss two days in a row"),
            String(localized: "Start with small, achievable habits"),
            String(localized: "Track your progress to stay motivated"),
            String(localized: "Build momentum with consistent daily check-ins")
        ]
    }
    
    /// How many days the user has been tracking, counting both the first day and today, so a
    /// day-one user averages over one day rather than dividing by zero. Whole calendar days
    /// apart, not 24-hour spans: a check-in at 9pm yesterday is one day ago at 10am, not zero.
    private func daysTracked(since earliest: Date?, until today: Date, calendar: Calendar) -> Int {
        guard let earliest else { return 1 }
        let span = calendar.dateComponents(
            [.day],
            from: earliest.startOfDay(for: calendar),
            to: today.startOfDay(for: calendar)
        ).day ?? 0
        return max(1, span + 1)
    }

    /// The start of every day carrying a check-in. All three streak figures below are
    /// questions about this one set, and `userCalendar` derives a fresh Calendar — and re-reads
    /// UserDefaults — on every access, so it is taken once as well.
    private func activeDays(_ calendar: Calendar) -> Set<Date> {
        Set(allCheckIns.map { $0.date.startOfDay(for: calendar) })
    }

    private func calculateLongestStreak() -> Int {
        let calendar = userCalendar
        return calendar.longestDayStreak(in: activeDays(calendar))
    }

    private func calculateCurrentStreak() -> Int {
        let calendar = userCalendar
        return calendar.currentDayStreak(in: activeDays(calendar))
    }
    
    private func calculateAverageStreak() -> Double {
        let calendar = userCalendar
        let lengths = calendar.dayStreakLengths(in: activeDays(calendar))
        guard !lengths.isEmpty else { return 0 }
        return Double(lengths.reduce(0, +)) / Double(lengths.count)
    }
}

struct Statistic {
    let title: String
    let value: String
    let subtitle: String
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    ScoreDetailView(
        viewModel: ScoreDetailViewModel(
            category: .activeHabits
        )
    )
}
