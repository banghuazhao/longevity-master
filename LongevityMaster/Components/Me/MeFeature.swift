//
// Created by Banghua Zhao on 21/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import Dependencies
import SQLiteData
import MoreApps

struct MeView: View {
    @Environment(\.openURL) private var openURL
    @Dependency(\.purchaseManager) var purchaseManager
    @Dependency(\.themeManager) var themeManager
    // This screen shows six numbers and nothing else, so it reads six numbers. Fetching the
    // four tables whole meant holding every habit, check-in, reminder and achievement in
    // memory — and re-reading all of them on any write anywhere in the app.
    @ObservationIgnored
    @FetchOne(Habit.where { !$0.isArchived }.count(), animation: .default) var activeHabitCount = 0
    @ObservationIgnored
    @FetchOne(Habit.all.count(), animation: .default) var habitCount = 0
    @ObservationIgnored
    @FetchOne(CheckIn.all.count(), animation: .default) var checkInCount = 0
    @ObservationIgnored
    @FetchOne(Reminder.all.count(), animation: .default) var reminderCount = 0
    @ObservationIgnored
    @FetchOne(Achievement.where { $0.isUnlocked }.count(), animation: .default) var unlockedAchievementCount = 0
    @ObservationIgnored
    @FetchOne(Achievement.all.count(), animation: .default) var achievementCount = 0
    @AppStorage("userName") private var userName: String = String(localized: "Your Name")
    @AppStorage("userAvatar") private var userAvatar: String = "😀"
    @State private var showPurchaseSheet = false
    @State private var showEmojiPicker = false

    private var theme: AppTheme { themeManager.current }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        profileCard

                        // Premium removes ads, and the Mac app has none, so there is nothing
                        // to sell there.
                        if !purchaseManager.isPremiumUserPurchased && AdManager.isAvailable {
                            premiumBanner
                        }

                        progressSection
                        habitsSection
                        personalizeSection
                        supportSection
                        footer
                    }
                    .padding(.horizontal)
                    .padding(.top, AppSpacing.small)
                    .padding(.bottom, AppSpacing.large)
                }
                if AdManager.isAvailable && !purchaseManager.isPremiumUserPurchased {
                    BannerView()
                        .frame(height: 50)
                }
            }
            .sheet(isPresented: $showPurchaseSheet) {
                PurchaseSheet()
            }
            .background(theme.background)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Me")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Profile

    private var profileCard: some View {
        VStack(spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.medium) {
                avatarButton

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppSpacing.small) {
                        TextField("Your Name", text: $userName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(theme.textPrimary)
                            .submitLabel(.done)
                            .lineLimit(1)
                        Image(systemName: "pencil")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(theme.textSecondary.opacity(0.7))
                            .accessibilityHidden(true)
                    }

                    if purchaseManager.isPremiumUserPurchased {
                        Label("Welcome, Premium user!", systemImage: "crown.fill")
                            .font(AppFont.footnote.weight(.semibold))
                            .foregroundStyle(Color(red: 0.85, green: 0.62, blue: 0.10))
                    }
                }
            }

            Rectangle()
                .fill(theme.separator)
                .frame(height: 1)
                .accessibilityHidden(true)

            HStack(spacing: 0) {
                AppStatView(value: "\(activeHabitCount)/\(habitCount)", title: "Habits")
                AppStatDivider()
                AppStatView(value: "\(checkInCount)", title: "Check-ins")
                AppStatDivider()
                AppStatView(value: "\(reminderCount)", title: "Reminders")
                AppStatDivider()
                AppStatView(value: "\(unlockedAchievementCount)/\(achievementCount)", title: "Achievements")
            }
        }
        .appCardStyle(theme: theme)
    }

    private var avatarButton: some View {
        Button {
            showEmojiPicker = true
        } label: {
            Text(userAvatar)
                .font(.system(size: 34))
                .frame(width: 64, height: 64)
                .background(Circle().fill(theme.primaryColor.opacity(0.12)))
                .overlay(Circle().strokeBorder(theme.primaryColor.opacity(0.3), lineWidth: 1.5))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "pencil")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(theme.primaryColor))
                        .overlay(Circle().strokeBorder(theme.card, lineWidth: 2))
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Choose your avatar"))
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(selectedEmoji: $userAvatar, title: "Choose your avatar")
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var premiumBanner: some View {
        Button {
            showPurchaseSheet = true
        } label: {
            HStack(spacing: AppSpacing.smallMedium) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.22), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Premium")
                        .font(AppFont.headline)
                    Text("Ad-free experience")
                        .font(AppFont.footnote)
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(AppSpacing.medium)
            .background(
                LinearGradient(
                    colors: [theme.primaryColor, theme.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous)
            )
            .shadow(color: theme.primaryColor.opacity(0.3), radius: 12, x: 0, y: 6)
            .contentShape(.rect)
        }
        .buttonStyle(PressableTileStyle())
    }

    // MARK: - Sections

    private var progressSection: some View {
        section("Progress") {
            NavigationLink(destination: InsightsView()) {
                AppRow("Insights", systemImage: "lightbulb.max.fill", color: .mint)
            }
            AppRowDivider()
            NavigationLink(destination: UserStatsView()) {
                AppRow("My Stats", systemImage: "chart.bar.fill", color: .blue)
            }
            AppRowDivider()
            NavigationLink(destination: AchievementsView()) {
                AppRow("Achievements", systemImage: "trophy.fill", color: .orange)
            }
            AppRowDivider()
            NavigationLink(destination: CheckInHistoryView()) {
                AppRow("Checkin History", systemImage: "clock.arrow.circlepath", color: .teal)
            }
        }
    }

    private var habitsSection: some View {
        section("Habits") {
            NavigationLink(destination: RemindersView()) {
                AppRow("Reminders", systemImage: "bell.fill", color: .red)
            }
            AppRowDivider()
            NavigationLink(destination: TimeOffView()) {
                AppRow("Time Off", systemImage: "moon.zzz.fill", color: .indigo)
            }
        }
    }

    private var personalizeSection: some View {
        section("Personalize") {
            NavigationLink(destination: ThemeColorView()) {
                AppRow("Theme Color", systemImage: "paintbrush.fill", color: .pink)
            }
            AppRowDivider()
            NavigationLink(destination: LanguageView()) {
                AppRow("Language", systemImage: "globe", color: .cyan)
            }
            AppRowDivider()
            NavigationLink(destination: SettingView()) {
                AppRow("Settings", systemImage: "gearshape.fill", color: .gray)
            }
        }
    }

    private var supportSection: some View {
        section("Support") {
            if let url = URL(string: "https://itunes.apple.com/app/id\(Constants.AppID.longevityMasterID)?action=write-review") {
                Button {
                    openURL(url)
                } label: {
                    AppRow("Rate Us", systemImage: "star.fill", color: .yellow) {
                        AppRowChevron(isExternal: true)
                    }
                }
                AppRowDivider()
            }
            Button {
                let email = SupportEmail()
                email.send(openURL: openURL)
            } label: {
                AppRow("Feedback", systemImage: "envelope.fill", color: .green) {
                    AppRowChevron(isExternal: true)
                }
            }
            if let appURL = URL(string: "https://itunes.apple.com/app/id\(Constants.AppID.longevityMasterID)") {
                AppRowDivider()
                ShareLink(item: appURL) {
                    AppRow("Share App", systemImage: "square.and.arrow.up", color: .blue) {
                        EmptyView()
                    }
                }
                .simultaneousGesture(TapGesture().onEnded { AppOpenAdPolicy.skipNextReturn() })
            }
            AppRowDivider()
            // The package opens the App Store itself, out of reach of the app's `openURL`.
            NavigationLink(destination: MoreAppsView().onAppear { AppOpenAdPolicy.skipNextReturn() }) {
                AppRow("More Apps", systemImage: "square.grid.2x2.fill", color: .purple)
            }
        }
    }

    private func section<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            AppSectionHeader(title)
            AppGroupedCard {
                content()
            }
            .buttonStyle(AppRowButtonStyle())
        }
    }

    private var footer: some View {
        VStack(spacing: AppSpacing.xSmall) {
            Text("Longevity Master  |  Healthy Habits for Long Life")
                .font(AppFont.footnote)
                .fontWeight(.semibold)
                .foregroundColor(theme.textSecondary)

            Button {
                if let url = URL(string: "https://apps.apple.com/app/id\(Constants.AppID.longevityMasterID)") {
                    openURL(url)
                }
            } label: {
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")  Check for Updates")
                    .font(AppFont.footnote)
                    .foregroundColor(theme.textSecondary)
                    .underline()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.small)
    }
}

#Preview {
    MeView()
}

struct SupportEmail {
    let toAddress = "appsbayarea@gmail.com"
    let subject: String = String(localized: "\("LongevityMaster") - \("Feedback")")
    /// Anything else support should see, such as the error behind a screen the user is
    /// writing in about. Left out of the email when empty.
    var details: String = ""
    var body: String { """
      Application Name: \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown")
      iOS Version: \(UIDevice.current.systemVersion)
      Device Model: \(UIDevice.current.model)
      App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "no app version")
      App Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "no app build version")\(details.isEmpty ? "" : "\n  \(details)")

      \(String(localized: "Please describe your issue below"))
      ------------------------------------

    """ }

    func send(openURL: OpenURLAction) {
        let replacedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let replacedBody = body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "mailto:\(toAddress)?subject=\(replacedSubject)&body=\(replacedBody)"
        guard let url = URL(string: urlString) else { return }
        openURL(url) { accepted in
            if !accepted { // e.g. Simulator
                debugLog("Device doesn't support email.\n \(body)")
            }
        }
    }
}
