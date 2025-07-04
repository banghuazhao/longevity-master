//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI
import GoogleMobileAds

@main
struct LongevityMasterApp: App {
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Dependency(\.achievementService) private var achievementService
    @StateObject private var openAd = OpenAd()
    @Environment(\.scenePhase) private var scenePhase
    @State private var didShowOpenAd = false
    
    init() {
        MobileAds.shared.start(completionHandler: nil)
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            tabView
                .overlay {
                    if let achievementToShow = achievementService.achievementToShow {
                        AchievementPopupView(
                            achievement: achievementToShow,
                            isPresented: Binding(
                                get: { achievementService.achievementToShow != nil },
                                set: { if !$0 { achievementService.achievementToShow = nil } }
                            )
                        )
                    }
                }
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
                .task {
                    await requestNotificationPermissions()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    print("scenePhase: \(newPhase)")
                    if newPhase == .active {
                        openAd.tryToPresentAd()
                        openAd.appHasEnterBackgroundBefore = false
                    } else if newPhase == .background {
                        openAd.appHasEnterBackgroundBefore = true
                    }
                }
        }
    }
    
    var tabView: some View {
        ZStack {
            TabView {
                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "calendar")
                    }
                    .onAppear {
                        AdManager.requestATTPermission(with: 1)
                    }
                
                HabitsListView()
                    .tabItem {
                        Label("Habits", systemImage: "list.bullet")
                    }
                
                RatingView()
                    .tabItem {
                        Label("Rating", systemImage: "star.fill")
                    }
                
                MeView()
                    .tabItem {
                        Label("Me", systemImage: "person.fill")
                    }
                    .onAppear {
                        AdManager.requestATTPermission(with: 1)
                    }
            }

            // Onboarding overlay
            Color.clear
                .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
                    OnboardingView()
                }
        }
    }
    
    private func requestNotificationPermissions() async {
        @Dependency(\.notificationService) var notificationService
        await notificationService.requestPermission()
        await notificationService.printAllNotifications()
    }
}
