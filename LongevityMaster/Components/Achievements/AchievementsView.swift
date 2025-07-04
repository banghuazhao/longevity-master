//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SharingGRDB

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
        var cal = Calendar.current
        cal.firstWeekday = startWeekOnMonday ? 2 : 1 // 2 = Monday, 1 = Sunday
        return cal
    }
    
    func getProgress(for achievement: Achievement) -> Double {
        switch achievement.type {
        case .streak:
            return getStreakProgress(for: achievement)
        case .totalCheckIns:
            return getTotalCheckInsProgress(for: achievement)
        case .perfectWeek, .perfectMonth:
            return 0 // These are binary achievements
        case .categoryMaster:
            return getCategoryMasterProgress(for: achievement)
        case .earlyBird, .nightOwl:
            return 0 // These are binary achievements
        case .consistency:
            return getConsistencyProgress(for: achievement)
        case .variety:
            return getVarietyProgress(for: achievement)
        case .milestone:
            return getMilestoneProgress(for: achievement)
        }
    }
    
    private func getStreakProgress(for achievement: Achievement) -> Double {
        let targetStreak = achievement.criteria.targetValue
        let habitID = achievement.habitID
        
        let checkIns = allCheckIns.filter { habitID == nil || $0.habitID == habitID }
        let sortedCheckIns = checkIns.sorted { $0.date > $1.date }
        
        guard let latestCheckIn = sortedCheckIns.first else { return 0 }
        
        var currentStreak = 0
        var currentDate = latestCheckIn.date
        
        for _ in 0..<targetStreak {
            let startOfDay = currentDate.startOfDay(for: userCalendar)
            let endOfDay = currentDate.endOfDay(for: userCalendar)
            
            let hasCheckIn = checkIns.contains { checkIn in
                checkIn.date >= startOfDay && checkIn.date <= endOfDay
            }
            
            if hasCheckIn {
                currentStreak += 1
                currentDate = userCalendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return min(Double(currentStreak) / Double(targetStreak), 1.0)
    }
    
    private func getTotalCheckInsProgress(for achievement: Achievement) -> Double {
        let targetCount = achievement.criteria.targetValue
        let habitID = achievement.habitID
        
        let totalCheckIns = allCheckIns.filter { habitID == nil || $0.habitID == habitID }.count
        
        return min(Double(totalCheckIns) / Double(targetCount), 1.0)
    }
    
    private func getCategoryMasterProgress(for achievement: Achievement) -> Double {
        guard let targetCategory = achievement.criteria.category else { return 0 }
        let targetCount = achievement.criteria.targetValue
        
        let categoryCheckIns = allCheckIns.filter { checkIn in
            if let habit = allHabits.first(where: { $0.id == checkIn.habitID }) {
                return habit.category == targetCategory
            }
            return false
        }.count
        
        return min(Double(categoryCheckIns) / Double(targetCount), 1.0)
    }
    
    private func getConsistencyProgress(for achievement: Achievement) -> Double {
        let targetDays = achievement.criteria.targetValue
        var currentDate = Date()
        var consecutiveDays = 0
        
        for _ in 0..<targetDays {
            let startOfDay = currentDate.startOfDay(for: userCalendar)
            let endOfDay = currentDate.endOfDay(for: userCalendar)
            
            let hasAnyCheckIn = allCheckIns.contains { checkIn in
                checkIn.date >= startOfDay && checkIn.date <= endOfDay
            }
            
            if hasAnyCheckIn {
                consecutiveDays += 1
                currentDate = userCalendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return min(Double(consecutiveDays) / Double(targetDays), 1.0)
    }
    
    private func getVarietyProgress(for achievement: Achievement) -> Double {
        let targetCategories = achievement.criteria.targetValue
        
        let uniqueCategories = Set(allCheckIns.compactMap { checkIn in
            allHabits.first(where: { $0.id == checkIn.habitID })?.category
        })
        
        return min(Double(uniqueCategories.count) / Double(targetCategories), 1.0)
    }
    
    private func getMilestoneProgress(for achievement: Achievement) -> Double {
        let targetCount = achievement.criteria.targetValue
        let totalCheckIns = allCheckIns.count
        
        return min(Double(totalCheckIns) / Double(targetCount), 1.0)
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(achievementsToShow) { achievement in
                            AchievementRowView(
                                achievement: achievement,
                                progress: viewModel.getProgress(for: achievement)
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
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
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
