//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI
import GoogleMobileAds
import UserNotifications

@main
struct LongevityMasterApp: App {
    @Dependency(\.achievementService) private var achievementService
    @Dependency(\.purchaseManager) private var purchaseManager
    @Dependency(\.consentManager) private var consentManager
    @Dependency(\.notificationService) private var notificationService
    @StateObject private var openAd = OpenAd()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // The ad SDK is deliberately not started here. `ConsentManager` starts it only once
        // consent has resolved, so no ad request can precede the user's answer.
        AppearanceMode.migrateFromLegacyDarkModeFlag()
        AppGroup.mirrorStartWeekOnMondayFromAppDefaults()
        ThemeManager.shared.mirrorAccentColorToWidget()
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
        // Siri and Shortcuts run their intents in this process; send their writes through the
        // connection the screens observe, and settle the reminders after them.
        @Dependency(\.defaultDatabase) var database
        WidgetDatabase.inAppDatabase = database
        WidgetDatabase.afterCheckInChange = {
            Task { await NotificationService.shared.syncAllReminders() }
        }
        // Set before launch finishes, so a reminder that launched the app is seen too.
        UNUserNotificationCenter.current().delegate = ReminderTapObserver.shared
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
                        // A new day, or a check-in made from the widget while the app was
                        // away, changes what the reminders still have to ask for.
                        Task { await notificationService.syncAllReminders() }
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
        await notificationService.requestPermission()
        await notificationService.syncAllReminders()
        await notificationService.printAllNotifications()
    }
}

/// The app's tabs, so a screen can send the user to another one.
enum AppTab: Hashable {
    case today
    case habits
    case programs
    case rating
    case me
}

extension EnvironmentValues {
    /// Switches to another tab. A no-op outside `RootView`, such as in previews.
    @Entry var selectTab: (AppTab) -> Void = { _ in }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var selectedTab: AppTab = .today
    @State private var router = AppRouter.shared
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
            .environment(\.selectTab) { selectedTab = $0 }
            // Every SwiftUI link and `openURL` call leaves the app on purpose — a study, an
            // email, the App Store — so the ad stays away when the user comes back.
            .environment(\.openURL, OpenURLAction { _ in
                AppOpenAdPolicy.skipNextReturn()
                return .systemAction
            })

            // Onboarding overlay
            Color.clear
                .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
                    OnboardingView()
                }
        }
        .sheet(item: $router.presented) { destination in
            switch destination {
            case let .weeklyReview(weekOf):
                NavigationStack {
                    WeeklyReviewView(initialWeek: weekOf, showsCloseButton: true)
                }
            case let .programCompletion(enrollmentID):
                ProgramCompletionSheet(enrollmentID: enrollmentID)
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
        TabView(selection: $selectedTab) {
            Tab(value: AppTab.today) {
                TodayView()
            } label: {
                Label("Today", systemImage: "calendar")
            }
            
            Tab(value: AppTab.habits) {
                HabitsListView()
            } label: {
                Label("Habits", systemImage: "list.bullet")
            }

            Tab(value: AppTab.programs) {
                ProgramsView()
            } label: {
                Label("Programs", systemImage: "map.fill")
            }
            
            Tab(value: AppTab.rating) {
                RatingView()
            } label: {
                Label("Rating", systemImage: "star.fill")
            }
            
            Tab(value: AppTab.me) {
                MeView()
            } label: {
                Label("Me", systemImage: "person.fill")
            }
        }
    }
    
    var tabView: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem{
                    Label("Today", systemImage: "calendar")
                }
                .tag(AppTab.today)
            
            HabitsListView()
                .tabItem{
                    Label("Habits", systemImage: "list.bullet")
                }
                .tag(AppTab.habits)

            ProgramsView()
                .tabItem{
                    Label("Programs", systemImage: "map.fill")
                }
                .tag(AppTab.programs)
            
            RatingView()
                .tabItem{
                    Label("Rating", systemImage: "star.fill")
                }
                .tag(AppTab.rating)
            
            MeView()
                .tabItem{
                    Label("Me", systemImage: "person.fill")
                }
                .tag(AppTab.me)
        }
    }
}
