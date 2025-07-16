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
    @Dependency(\.themeManager) private var themeManager
    @Dependency(\.purchaseManager) private var purchaseManager
    @StateObject private var openAd = OpenAd()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        MobileAds.shared.start(completionHandler: nil)
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            content
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
                        if !purchaseManager.isPremiumUserPurchased {
                            openAd.tryToPresentAd()
                        }
                        openAd.appHasEnterBackgroundBefore = false
                    } else if newPhase == .background {
                        openAd.appHasEnterBackgroundBefore = true
                    }
                }
        }
    }
    
    @ViewBuilder
    var content: some View {
        ZStack {
            Group {
                if #available(iOS 18.0, *) {
                    tabView18
                } else {
                    tabView
                }
            }
            .background(themeManager.current.background)
            .tint(themeManager.current.primaryColor)

            // Onboarding overlay
            Color.clear
                .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
                    OnboardingView()
                }
        }
    }
    
    @available(iOS 18.0, *)
    var tabView18: some View {
        TabView {
            Tab {
                TodayView()
                    .onAppear {
                        AdManager.requestATTPermission(with: 3)
                    }
            } label: {
                Label("Today", systemImage: "calendar")
            }
            
            Tab {
                HabitsListView()
            } label: {
                Label("Habits", systemImage: "list.bullet")
            }
            
            Tab {
                RatingView()
            } label: {
                Label("Rating", systemImage: "star.fill")
            }
            
            Tab {
                MeView()
                    .onAppear {
                        AdManager.requestATTPermission(with: 1)
                    }
            } label: {
                Label("Me", systemImage: "person.fill")
            }
        }
    }
    
    var tabView: some View {
        TabView {
            TodayView()
                .tabItem{
                    Label("Today", systemImage: "calendar")
                }
                .onAppear {
                    AdManager.requestATTPermission(with: 3)
                }
            
            HabitsListView()
                .tabItem{
                    Label("Habits", systemImage: "list.bullet")
                }
            
            
            RatingView()
                .tabItem{
                    Label("Rating", systemImage: "star.fill")
                }
            
            MeView()
                .tabItem{
                    Label("Me", systemImage: "person.fill")
                }
                .onAppear {
                    AdManager.requestATTPermission(with: 1)
                }
        }
    }
    
    private func requestNotificationPermissions() async {
        @Dependency(\.notificationService) var notificationService
        await notificationService.requestPermission()
        await notificationService.printAllNotifications()
    }
}
