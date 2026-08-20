//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI
import GoogleMobileAds

@main
struct LongevityMasterApp: App {
    @Dependency(\.achievementService) private var achievementService
    @Dependency(\.purchaseManager) private var purchaseManager
    @Dependency(\.consentManager) private var consentManager
    @StateObject private var openAd = OpenAd()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // The ad SDK is deliberately not started here. `ConsentManager` starts it only once
        // consent has resolved, so no ad request can precede the user's answer.
        AppearanceMode.migrateFromLegacyDarkModeFlag()
        AppGroup.mirrorStartWeekOnMondayFromAppDefaults()
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
        WidgetRefresher.reload()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
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
                .task {
                    // Deliberately sequential: the notification alert makes the app inactive,
                    // and ATT asked during that window never reaches the screen. Consent runs
                    // once the user has dealt with notifications.
                    await requestNotificationPermissions()
                    await consentManager.resolve()
                }
                .task {
                    await purchaseManager.checkPurchaseStatus()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { await purchaseManager.checkPurchaseStatus() }
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
    
    private func requestNotificationPermissions() async {
        @Dependency(\.notificationService) var notificationService
        await notificationService.requestPermission()
        await notificationService.printAllNotifications()
    }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Dependency(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
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
        // `nil` for .system, which lets the device's own setting through.
        .preferredColorScheme(themeManager.appearanceMode.colorScheme)
        // Once the preference above resolves, this is the scheme actually being rendered,
        // which is what .system needs in order to pick a theme.
        .onChange(of: colorScheme, initial: true) { _, newScheme in
            themeManager.systemColorScheme = newScheme
        }
    }

    @available(iOS 18.0, *)
    var tabView18: some View {
        TabView {
            Tab {
                TodayView()
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
        }
    }
}
