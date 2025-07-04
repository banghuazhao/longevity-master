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
    @Dependency(\.achievementService) private var achievementService
    @Dependency(\.purchaseManager) private var purchaseManager
    @StateObject private var openAd = OpenAd()
    @Environment(\.scenePhase) private var scenePhase
    @State private var didShowOpenAd = false
    
    init() {
//        let tabBarAppearance = UITabBarAppearance()
//        tabBarAppearance.configureWithOpaqueBackground()
//        tabBarAppearance.backgroundColor = UIColor.systemBackground
//        UITabBar.appearance().standardAppearance = tabBarAppearance
//        if #available(iOS 15.0, *) {
//            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
//        }
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
                        if !purchaseManager.isPremiumUserPurchased {
                            openAd.tryToPresentAd()
                        }
                        openAd.appHasEnterBackgroundBefore = false
                    } else if newPhase == .background {
                        openAd.appHasEnterBackgroundBefore = true
                    }
                }
                .task {
                    await purchaseManager.checkPurchased()
                }
        }
    }
    
    var tabView: some View {
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
    }
    
    private func requestNotificationPermissions() async {
        @Dependency(\.notificationService) var notificationService
        await notificationService.requestPermission()
        await notificationService.printAllNotifications()
    }
}
