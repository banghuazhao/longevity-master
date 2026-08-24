//
//  UserStatsView.swift
//  LongevityMaster
//
//  Created by Banghua Zhao on 2025/1/1
//  Copyright Apps Bay Limited. All rights reserved.
//

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
        earliestCheckIn.map { DateFormatter.mediumDate.string(from: $0.date) }
    }
    var mostFrequentHabit: Habit? { findMostFrequentHabit() }
    var categoryStats: [HabitCategory: Int] { calculateCategoryStats() }
    
    /// Reading this recomputes the score from every habit, achievement and check-in — so take
    /// one breakdown and read the parts you need off it, rather than asking once per value.
    var longevityScore: LongevityScoreBreakdown { ratingService.calculateLongevityScore() }
    
    /// The start of every day carrying a check-in. Days active and both streak figures are all
    /// questions about this one set, and asking it directly beats sorting the whole table and
    /// then comparing calendar days one check-in at a time.
    private func activeDays(_ calendar: Calendar) -> Set<Date> {
        Set(allCheckIns.map { calendar.startOfDay(for: $0.date) })
    }

    private func calculateTotalDaysActive() -> Int {
        activeDays(Calendar.current).count
    }

    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        var longestStreak = 0
        var currentStreak = 0
        var lastDay: Date?

        for day in activeDays(calendar).sorted() {
            if let lastDay, calendar.dateComponents([.day], from: lastDay, to: day).day == 1 {
                currentStreak += 1
            } else {
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 1
            }
            lastDay = day
        }

        return max(longestStreak, currentStreak)
    }

    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let days = activeDays(calendar)
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while days.contains(checkDate) {
            currentStreak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
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
        let bestHabitName = bestHabit?.name ?? "No habits yet"
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
                        detail: String(localized: "\(allCheckInsForHabit(bestHabit.id).count) check-ins")
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
                
                if let mostFrequent = viewModel.mostFrequentHabit {
                    insightRow(
                        icon: "📈",
                        title: String(localized: "Most Consistent"),
                        subtitle: mostFrequent.name,
                        detail: String(localized: "\(allCheckInsForHabit(mostFrequent.id).count) times")
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
                            Text(category.briefTitle)
                                .font(AppFont.body)
                                .foregroundColor(viewModel.themeManager.current.textPrimary)
                            
                            Spacer()
                            
                            HStack {
                                Text("\(count)")
                                    .font(AppFont.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(viewModel.themeManager.current.primaryColor)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
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
