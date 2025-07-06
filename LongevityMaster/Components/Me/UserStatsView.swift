//
//  UserStatsView.swift
//  LongevityMaster
//
//  Created by Banghua Zhao on 2025/1/1
//  Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SharingGRDB
import Dependencies

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
    var bestHabit: Habit? { findBestHabit() }
    var earliestCheckIn: CheckIn? { findEarliestCheckIn() }
    var earliestCheckInString: String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        if let date = earliestCheckIn?.date {
            return dateFormatter.string(from: date)
        } else {
            return nil
        }
    }
    var mostFrequentHabit: Habit? { findMostFrequentHabit() }
    var categoryStats: [HabitCategory: Int] { calculateCategoryStats() }
    
    // Longevity Rating
    var longevityScore: LongevityScoreBreakdown { ratingService.calculateLongevityScore() }
    var longevityRating: LongevityRating { longevityScore.rating }
    var totalScore: Int { longevityScore.totalScore }
    var scoreToNextRating: Int { longevityScore.scoreToNextRating }
    var nextRating: LongevityRating? { longevityScore.nextRating }
    
    private func calculateTotalDaysActive() -> Int {
        let uniqueDates = Set(allCheckIns.map { Calendar.current.startOfDay(for: $0.date) })
        return uniqueDates.count
    }
    
    private func calculateLongestStreak() -> Int {
        let sortedDates = allCheckIns.map { $0.date }.sorted()
        var longestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for date in sortedDates {
            let startOfDay = Calendar.current.startOfDay(for: date)
            
            if let last = lastDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: last), to: startOfDay).day ?? 0
                
                if daysBetween == 1 {
                    currentStreak += 1
                } else if daysBetween > 1 {
                    longestStreak = max(longestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            lastDate = startOfDay
        }
        
        return max(longestStreak, currentStreak)
    }
    
    private func calculateCurrentStreak() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let sortedDates = allCheckIns.map { $0.date }.sorted()
        var currentStreak = 0
        var checkDate = today
        
        while true {
            let hasCheckIn = sortedDates.contains { Calendar.current.isDate($0, inSameDayAs: checkDate) }
            if hasCheckIn {
                currentStreak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        return currentStreak
    }
    
    private func findBestHabit() -> Habit? {
        let habitCheckInCounts = Dictionary(grouping: allCheckIns, by: { $0.habitID })
            .mapValues { $0.count }
        
        return habitCheckInCounts.max(by: { $0.value < $1.value })
            .flatMap { habitID in
                allHabits.first { $0.id == habitID.key }
            }
    }
    
    private func findEarliestCheckIn() -> CheckIn? {
        return allCheckIns.min(by: { $0.date < $1.date })
    }
    
    private func findMostFrequentHabit() -> Habit? {
        let habitCheckInCounts = Dictionary(grouping: allCheckIns, by: { $0.habitID })
            .mapValues { $0.count }
        
        return habitCheckInCounts.max(by: { $0.value < $1.value })
            .flatMap { habitID in
                allHabits.first { $0.id == habitID.key }
            }
    }
    
    private func calculateCategoryStats() -> [HabitCategory: Int] {
        var stats: [HabitCategory: Int] = [:]
        
        for habit in allHabits where !habit.isArchived {
            let checkInCount = allCheckIns.filter { $0.habitID == habit.id }.count
            stats[habit.category, default: 0] += checkInCount
        }
        
        return stats
    }
    
    func generateShareText() -> String {
        let bestHabitName = bestHabit?.name ?? "No habits yet"
        let earliestDate = earliestCheckIn?.date ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        return """
        📊 My Longevity Master Stats
        
        🏆 Longevity Rating: \(longevityRating.displayName) (\(longevityRating.description))
        📈 Total Score: \(totalScore) points
        🎯 Total Habits: \(totalHabits)
        ✅ Total Check-ins: \(totalCheckIns)
        🏆 Achievements Unlocked: \(totalAchievements)
        📅 Days Active: \(totalDaysActive)
        🔥 Longest Streak: \(longestStreak) days
        ⚡ Current Streak: \(currentStreak) days
        🌟 Best Habit: \(bestHabitName)
        🕐 Started: \(dateFormatter.string(from: earliestDate))
        
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
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Longevity Rating"))
                .appSectionHeader(theme: viewModel.themeManager.current)
            
            VStack(spacing: AppSpacing.medium) {
                // Rating Display
                HStack(spacing: AppSpacing.large) {
                    VStack(spacing: AppSpacing.small) {
                        Text(viewModel.longevityRating.displayName)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(viewModel.longevityRating.color)
                        
                        Text(viewModel.longevityRating.description)
                            .font(AppFont.subheadline)
                            .foregroundColor(viewModel.themeManager.current.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: AppSpacing.small) {
                        Text("\(viewModel.totalScore)")
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
            }
        }
        .appCardStyle()
    }
    
    @ViewBuilder
    private var habitInsightsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Habit Insights"))
                .appSectionHeader(theme: viewModel.themeManager.current)
            
            VStack(spacing: AppSpacing.medium) {
                if let bestHabit = viewModel.bestHabit {
                    insightRow(
                        icon: "🌟",
                        title: String(localized: "Best Habit"),
                        subtitle: bestHabit.name,
                        detail: "\(allCheckInsForHabit(bestHabit.id).count) check-ins"
                    )
                }
                
                if let earliestCheckInString = viewModel.earliestCheckInString {
                    insightRow(
                        icon: "🕐",
                        title: String(localized: "Started Journey"),
                        subtitle: earliestCheckInString,
                        detail: "First check-in"
                    )
                }
                
                if let mostFrequent = viewModel.mostFrequentHabit {
                    insightRow(
                        icon: "📈",
                        title: String(localized: "Most Consistent"),
                        subtitle: mostFrequent.name,
                        detail: "\(allCheckInsForHabit(mostFrequent.id).count) times"
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
            
            VStack(spacing: AppSpacing.small) {
                ForEach(HabitCategory.allCases, id: \.self) { category in
                    let count = viewModel.categoryStats[category] ?? 0
                    if count > 0 {
                        HStack {
                            Text(category.icon)
                                .font(.title3)
                            
                            Text(category.briefTitle)
                                .font(AppFont.body)
                                .foregroundColor(viewModel.themeManager.current.textPrimary)
                            
                            Spacer()
                            
                            Text("\(count)")
                                .font(AppFont.body)
                                .fontWeight(.semibold)
                                .foregroundColor(viewModel.themeManager.current.primaryColor)
                        }
                        .padding(.vertical, 4)
                    }
                }
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
    
    private func allCheckInsForHabit(_ habitId: Int) -> [CheckIn] {
        return viewModel.allCheckIns.filter { $0.habitID == habitId }
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
