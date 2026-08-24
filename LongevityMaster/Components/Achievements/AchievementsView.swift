//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SQLiteData
import Sharing

@Observable
@MainActor
class AchievementsViewModel {
    @ObservationIgnored
    @FetchAll(Achievement.all, animation: .default) var allAchievements
    
    @ObservationIgnored
    @FetchAll(CheckIn.all, animation: .default) var allCheckIns
    
    @ObservationIgnored
    @FetchAll(Habit.all, animation: .default) var allHabits
    
    var unlockedAchievements: [Achievement] {
        allAchievements.filter { $0.isUnlocked }.sorted { $0.unlockedDate ?? Date() > $1.unlockedDate ?? Date() }
    }
    
    var lockedAchievements: [Achievement] {
        allAchievements.filter { !$0.isUnlocked }
    }
    
    var totalAchievements: Int {
        allAchievements.count
    }
    
    var unlockedCount: Int {
        unlockedAchievements.count
    }
    
    var progressPercentage: Double {
        guard totalAchievements > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalAchievements) * 100
    }
    
    @ObservationIgnored
    @Shared(.appStorage("startWeekOnMonday")) private var startWeekOnMonday: Bool = true
    
    var userCalendar: Calendar {
        .userPreferred(startWeekOnMonday: startWeekOnMonday)
    }
    
    /// Everything the progress bars need, derived in one pass over the check-ins.
    ///
    /// Each row used to answer its own question from scratch: sorting the whole check-in table
    /// for a streak, rescanning it once per day walked, and — for the category and variety bars
    /// — pairing every check-in against every habit. With two dozen achievements on screen that
    /// is the same work over and over.
    private struct ProgressIndex {
        var daysByHabit: [Habit.ID: Set<Date>] = [:]
        var countsByHabit: [Habit.ID: Int] = [:]
        var latestDateByHabit: [Habit.ID: Date] = [:]
        var countsByCategory: [HabitCategory: Int] = [:]
        var categoriesTouched: Set<HabitCategory> = []
        var activeDays: Set<Date> = []
        var latestDate: Date?
        var totalCheckIns = 0

        init(checkIns: [CheckIn], habits: [Habit], calendar: Calendar) {
            let categoryByHabit = Dictionary(
                habits.map { ($0.id, $0.category) },
                uniquingKeysWith: { first, _ in first }
            )

            for checkIn in checkIns {
                let day = checkIn.date.startOfDay(for: calendar)
                activeDays.insert(day)
                daysByHabit[checkIn.habitID, default: []].insert(day)
                countsByHabit[checkIn.habitID, default: 0] += 1

                if checkIn.date > latestDateByHabit[checkIn.habitID] ?? .distantPast {
                    latestDateByHabit[checkIn.habitID] = checkIn.date
                }
                if checkIn.date > latestDate ?? .distantPast {
                    latestDate = checkIn.date
                }
                if let category = categoryByHabit[checkIn.habitID] {
                    countsByCategory[category, default: 0] += 1
                    categoriesTouched.insert(category)
                }
            }

            totalCheckIns = checkIns.count
        }
    }

    /// Progress for every achievement, keyed by id. The list reads this once rather than asking
    /// per row.
    var progressByAchievement: [Achievement.ID: Double] {
        let calendar = userCalendar
        let index = ProgressIndex(checkIns: allCheckIns, habits: allHabits, calendar: calendar)
        return Dictionary(
            uniqueKeysWithValues: allAchievements.map {
                ($0.id, progress(for: $0, using: index, calendar: calendar))
            }
        )
    }

    private func progress(for achievement: Achievement, using index: ProgressIndex, calendar: Calendar) -> Double {
        let target = achievement.criteria.targetValue
        // Nothing to make progress towards, and dividing by it would give back a NaN width.
        guard target > 0 else { return 0 }

        let habitID = achievement.habitID

        switch achievement.type {
        case .streak:
            let days = habitID.map { index.daysByHabit[$0] ?? [] } ?? index.activeDays
            let latest = habitID.map { index.latestDateByHabit[$0] } ?? index.latestDate
            guard let latest else { return 0 }
            let streak = calendar.consecutiveDays(endingAt: latest, within: days, upTo: target)
            return min(Double(streak) / Double(target), 1.0)

        case .totalCheckIns:
            let count = habitID.map { index.countsByHabit[$0] ?? 0 } ?? index.totalCheckIns
            return min(Double(count) / Double(target), 1.0)

        case .perfectWeek, .perfectMonth:
            return 0 // These are binary achievements

        case .categoryMaster:
            guard let category = achievement.criteria.category else { return 0 }
            return min(Double(index.countsByCategory[category] ?? 0) / Double(target), 1.0)

        case .earlyBird, .nightOwl:
            return 0 // These are binary achievements

        case .consistency:
            let days = calendar.consecutiveDays(endingAt: Date(), within: index.activeDays, upTo: target)
            return min(Double(days) / Double(target), 1.0)

        case .variety:
            return min(Double(index.categoriesTouched.count) / Double(target), 1.0)

        case .milestone:
            return min(Double(index.totalCheckIns) / Double(target), 1.0)
        }
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

struct AchievementsView: View {
    @State private var viewModel = AchievementsViewModel()
    @State private var selectedTab = 0
    
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Achievements")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(viewModel.unlockedCount) of \(viewModel.totalAchievements) unlocked")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: viewModel.progressPercentage / 100)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(viewModel.progressPercentage))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // Progress bar
                    ProgressView(value: viewModel.progressPercentage, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Tab selector
                Picker("Achievements", selection: $selectedTab) {
                    Text("All").tag(0)
                    Text("Unlocked").tag(1)
                    Text("Locked").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom)
                
                // Achievements list
                let progressByAchievement = viewModel.progressByAchievement
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(achievementsToShow) { achievement in
                            AchievementRowView(
                                achievement: achievement,
                                progress: progressByAchievement[achievement.id] ?? 0,
                                shareText: viewModel.createAchievementShareText(achievement)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .appBackground()
            .tint(themeManager.current.primaryColor)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var achievementsToShow: [Achievement] {
        switch selectedTab {
        case 0:
            return viewModel.allAchievements
        case 1:
            return viewModel.unlockedAchievements
        case 2:
            return viewModel.lockedAchievements
        default:
            return viewModel.allAchievements
        }
    }
}

struct AchievementRowView: View {
    let achievement: Achievement
    let progress: Double
    let shareText: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? 
                          LinearGradient(
                              gradient: Gradient(colors: [Color.yellow, Color.orange]),
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing
                          ) : 
                          LinearGradient(
                              gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)]),
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing
                          )
                    )
                    .frame(width: 50, height: 50)
                
                Text(achievement.icon)
                    .font(.title2)
                    .opacity(achievement.isUnlocked ? 1.0 : 0.5)
            }
            
            // Achievement details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                    
                    Spacer()
                    
                    if achievement.isUnlocked {
                        HStack(spacing: 8) {
                            ShareLink(
                                item: shareText,
                                subject: Text("Achievement Unlocked!"),
                                message: Text("Check out this achievement I unlocked in LongevityMaster!")
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                }
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Progress bar for locked achievements
                if !achievement.isUnlocked && progress > 0 {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                        .frame(height: 4)
                }
                
                // Unlock date for unlocked achievements
                if achievement.isUnlocked, let unlockDate = achievement.unlockedDate {
                    Text("Unlocked \(unlockDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    AchievementsView()
} 
