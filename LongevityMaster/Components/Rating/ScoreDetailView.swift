//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SharingGRDB

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
                    Button("Done") { dismiss() }
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
                    
                    Text("Score: \(viewModel.currentScore)/\(viewModel.category.maxScore)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(viewModel.percentage * 100))%")
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
            Text("How It's Calculated")
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
            Text("Your Statistics")
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
            Text("Tips to Improve")
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
        var cal = Calendar.current
        cal.firstWeekday = startWeekOnMonday ? 2 : 1
        return cal
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
            Statistic(title: "Active Habits", value: "\(activeHabits.count)", subtitle: "out of 30"),
            Statistic(title: "Archived Habits", value: "\(allHabits.filter { $0.isArchived }.count)", subtitle: "not counted"),
            Statistic(title: "Categories", value: "\(Set(activeHabits.map { $0.category }).count)", subtitle: "variety"),
            Statistic(title: "Favorites", value: "\(activeHabits.filter { $0.isFavorite }.count)", subtitle: "starred")
        ]
        
        tips = [
            "Create new habits to increase your score",
            "Archive unused habits to keep your list clean",
            "Try habits from different categories for variety",
            "Mark your most important habits as favorites"
        ]
    }
    
    private func loadAntiAgingData() async {
        let activeHabits = allHabits.filter { !$0.isArchived }
        let totalRating = activeHabits.reduce(0) { $0 + $1.antiAgingRating }
        currentScore = min(totalRating * 2, ScoreCategory.antiAgingRating.maxScore)
        percentage = Double(currentScore) / Double(ScoreCategory.antiAgingRating.maxScore)
        
        let averageRating = activeHabits.isEmpty ? 0 : Double(totalRating) / Double(activeHabits.count)
        
        statistics = [
            Statistic(title: "Total Rating", value: "\(totalRating)", subtitle: "points"),
            Statistic(title: "Average Rating", value: String(format: "%.1f", averageRating), subtitle: "per habit"),
            Statistic(title: "5-Star Habits", value: "\(activeHabits.filter { $0.antiAgingRating == 5 }.count)", subtitle: "maximum impact"),
            Statistic(title: "High Impact", value: "\(activeHabits.filter { $0.antiAgingRating >= 4 }.count)", subtitle: "4-5 stars")
        ]
        
        tips = [
            "Focus on habits with 4-5 star anti-aging ratings",
            "Replace low-impact habits with higher-rated ones",
            "Consider the cumulative effect of multiple habits",
            "Balance high-impact habits with sustainable ones"
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
            Statistic(title: "Unlocked", value: "\(unlockedAchievements.count)", subtitle: "achievements"),
            Statistic(title: "Available", value: "\(allAchievements.count)", subtitle: "total"),
            Statistic(title: "Recent", value: "\(recentUnlocks.count)", subtitle: "last 2 days"),
            Statistic(title: "Progress", value: "\(Int(percentage * 100))%", subtitle: "complete")
        ]
        
        tips = [
            "Complete daily habits to unlock streak achievements",
            "Try different habit categories for variety achievements",
            "Check in consistently to reach milestone achievements",
            "Complete habits early or late for time-based achievements"
        ]
    }
    
    private func loadCheckInsData() async {
        currentScore = min(allCheckIns.count * 2, ScoreCategory.totalCheckIns.maxScore)
        percentage = Double(currentScore) / Double(ScoreCategory.totalCheckIns.maxScore)
        
        let today = Date()
        let startOfWeek = today.startOfWeek(for: userCalendar)
        let startOfMonth = today.startOfMonth(for: userCalendar)
        
        let checkInsThisWeek = allCheckIns.filter { $0.date >= startOfWeek }
        let checkInsThisMonth = allCheckIns.filter { $0.date >= startOfMonth }
        
        statistics = [
            Statistic(title: "Total Check-ins", value: "\(allCheckIns.count)", subtitle: "all time"),
            Statistic(title: "This Week", value: "\(checkInsThisWeek.count)", subtitle: "recent activity"),
            Statistic(title: "This Month", value: "\(checkInsThisMonth.count)", subtitle: "monthly progress"),
            Statistic(title: "Average/Day", value: String(format: "%.1f", Double(allCheckIns.count) / max(1, Double(userCalendar.dateComponents([.day], from: allCheckIns.first?.date ?? today, to: today).day ?? 1))), subtitle: "consistency")
        ]
        
        tips = [
            "Check in daily to build consistency",
            "Don't break your streak - even one check-in counts",
            "Use reminders to never miss a day",
            "Celebrate milestones to stay motivated"
        ]
    }
    
    private func loadStreakData() async {
        let longestStreak = calculateLongestStreak()
        currentScore = min(longestStreak * 2, ScoreCategory.longestStreak.maxScore)
        percentage = Double(currentScore) / Double(ScoreCategory.longestStreak.maxScore)
        
        let currentStreak = calculateCurrentStreak()
        let averageStreak = calculateAverageStreak()
        
        statistics = [
            Statistic(title: "Longest Streak", value: "\(longestStreak)", subtitle: "days"),
            Statistic(title: "Current Streak", value: "\(currentStreak)", subtitle: "days"),
            Statistic(title: "Average Streak", value: String(format: "%.1f", averageStreak), subtitle: "days"),
            Statistic(title: "Streak Goal", value: "125", subtitle: "days max")
        ]
        
        tips = [
            "Never miss two days in a row",
            "Start with small, achievable habits",
            "Track your progress to stay motivated",
            "Build momentum with consistent daily check-ins"
        ]
    }
    
    private func calculateLongestStreak() -> Int {
        guard !allCheckIns.isEmpty else { return 0 }
        
        let uniqueDates = Set(allCheckIns.map { $0.date.startOfDay(for: userCalendar) }).sorted()
        
        var longestStreak = 0
        var currentStreak = 0
        var previousDate: Date?
        
        for date in uniqueDates {
            if let previous = previousDate {
                let daysDifference = userCalendar.dateComponents([.day], from: previous, to: date).day ?? 0
                
                if daysDifference == 1 {
                    currentStreak += 1
                } else {
                    longestStreak = max(longestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            previousDate = date
        }
        
        longestStreak = max(longestStreak, currentStreak)
        return longestStreak
    }
    
    private func calculateCurrentStreak() -> Int {
        guard !allCheckIns.isEmpty else { return 0 }
        
        let mostRecentCheckIn = allCheckIns.max { $0.date < $1.date }
        guard let mostRecentDate = mostRecentCheckIn?.date else { return 0 }
        
        var currentStreak = 0
        var currentDate = mostRecentDate
        
        while true {
            let startOfDay = currentDate.startOfDay(for: userCalendar)
            let endOfDay = currentDate.endOfDay(for: userCalendar)
            
            let hasAnyCheckIn = allCheckIns.contains { checkIn in
                checkIn.date >= startOfDay && checkIn.date <= endOfDay
            }
            
            if hasAnyCheckIn {
                currentStreak += 1
                currentDate = userCalendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return currentStreak
    }
    
    private func calculateAverageStreak() -> Double {
        guard !allCheckIns.isEmpty else { return 0 }
        
        let uniqueDates = Set(allCheckIns.map { $0.date.startOfDay(for: userCalendar) }).sorted()
        
        var streaks: [Int] = []
        var currentStreak = 0
        var previousDate: Date?
        
        for date in uniqueDates {
            if let previous = previousDate {
                let daysDifference = userCalendar.dateComponents([.day], from: previous, to: date).day ?? 0
                
                if daysDifference == 1 {
                    currentStreak += 1
                } else {
                    if currentStreak > 0 {
                        streaks.append(currentStreak)
                    }
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            previousDate = date
        }
        
        if currentStreak > 0 {
            streaks.append(currentStreak)
        }
        
        return streaks.isEmpty ? 0 : Double(streaks.reduce(0, +)) / Double(streaks.count)
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
