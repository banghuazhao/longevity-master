//
// Created by Banghua Zhao on 21/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import Dependencies
import SharingGRDB

struct MeView: View {
    @Environment(\.openURL) private var openURL
    @Dependency(\.purchaseManager) var purchaseManager
    @Dependency(\.themeManager) var themeManager
    @ObservationIgnored
    @FetchAll(Habit.all, animation: .default) var allHabits
    @ObservationIgnored
    @FetchAll(CheckIn.all, animation: .default) var allCheckIns
    @ObservationIgnored
    @FetchAll(Reminder.all, animation: .default) var allReminders
    @ObservationIgnored
    @FetchAll(Achievement.all, animation: .default) var allAchievements
    @AppStorage("userName") private var userName: String = "Your Name"
    @AppStorage("userAvatar") private var userAvatar: String = "😀"
    @State private var showPurchaseSheet = false
    @State private var showEmojiPicker = false
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(spacing: AppSpacing.large) {
                        // Me Section
                        VStack(alignment: .leading, spacing: AppSpacing.medium) {
                            HStack(spacing: AppSpacing.medium) {
                                Button(action: { showEmojiPicker = true }) {
                                    Text(userAvatar)
                                        .font(.system(size: 40))
                                        .frame(width: 50, height: 50)
                                        .background(themeManager.current.card)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .sheet(isPresented: $showEmojiPicker) {
                                    EmojiPickerView(selectedEmoji: $userAvatar, title: "Choose your avatar")
                                    .presentationDetents([.medium])
                                    .presentationDragIndicator(.visible)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    TextField("Your Name", text: $userName)
                                        .font(AppFont.headline)
                                        .fontWeight(.bold)
                                        .padding(AppSpacing.small)
                                        .background(themeManager.current.background)
                                        .cornerRadius(AppCornerRadius.button)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            // Stats Section
                            HStack(spacing: AppSpacing.small) {
                                statView(title: "Habits", value: "\(allHabits.filter { !$0.isArchived }.count)/\(allHabits.count)")
                                Divider()
                                statView(title: "Check-ins", value: "\(allCheckIns.count)")
                                Divider()
                                statView(title: "Reminders", value: "\(allReminders.count)")
                                Divider()
                                statView(title: "Achievements", value: "\(allAchievements.filter { $0.isUnlocked }.count)/\(allAchievements.count)")
                            }
                            .padding(.top, AppSpacing.small)
                            if !purchaseManager.isRemoveAdsPurchased {
                                Button(action: {
                                    showPurchaseSheet = true
                                }) {
                                    Text("Upgrade to Premium")
                                        .appButtonStyle(theme: themeManager.current)
                                }
                                .sheet(isPresented: $showPurchaseSheet) {
                                    PurchaseSheet()
                                }
                            }
                        }
                        .appCardStyle(theme: themeManager.current)
                        .padding(.horizontal)
                        moreFeatureView
                        othersView
                        
                        Spacer().frame(height: 10)
                        
                        VStack(spacing: 4) {
                            Text("Longevity Master  |  Healthy Habits for Long Life")
                                .font(AppFont.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.current.textSecondary)
                            
                            Button {
                                if let url = URL(string: "https://apps.apple.com/app/id\(Constants.AppID.longevityMasterID)") {
                                    openURL(url)
                                }
                            } label: {
                                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")  Check for Updates")
                                    .font(AppFont.footnote)
                                    .foregroundColor(themeManager.current.textSecondary)
                                    .underline()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 50)
                        
                    }
                }
                BannerView()
                    .frame(height: 60)
            }
            .background(themeManager.current.background)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Me")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func statView(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(AppFont.subheadline)
                .fontWeight(.bold)
                .foregroundColor(themeManager.current.primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(themeManager.current.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private var othersView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Others")
                .appSectionHeader(theme: themeManager.current)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppSpacing.large) {
                NavigationLink(destination: MoreAppsView()) {
                    moreItem(icon: "storefront", title: "More Apps")
                }
                if let url = URL(string: "https://itunes.apple.com/app/id\(Constants.AppID.longevityMasterID)?action=write-review") {
                    Button {
                        openURL(url)
                    } label: {
                        moreItem(icon: "star.fill", title: "Rate Us")
                    }
                }
                Button {
                    let email = SupportEmail()
                    email.send(openURL: openURL)
                } label: {
                    moreItem(icon: "envelope.fill", title: "Feedback")
                }
                if let appURL = URL(string: "https://itunes.apple.com/app/id\(Constants.AppID.longevityMasterID)") {
                    ShareLink(item: appURL) {
                        moreItem(icon: "square.and.arrow.up", title: "Share App")
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var moreFeatureView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("More Features")
                .appSectionHeader(theme: themeManager.current)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppSpacing.large) {
                NavigationLink(destination: CheckInHistoryView()) {
                    featureItem(icon: "clock", title: "Checkin History")
                }
                NavigationLink(destination: RemindersView()) {
                    featureItem(icon: "bell", title: "Reminders")
                }
                NavigationLink(destination: AchievementsView()) {
                    featureItem(icon: "trophy", title: "Achievements")
                }
                NavigationLink(destination: SettingView()) {
                    featureItem(icon: "gear", title: "Settings")
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func moreItem(icon: String, title: String) -> some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeManager.current.primaryColor)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(themeManager.current.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.small)
        .background(themeManager.current.card)
        .cornerRadius(AppCornerRadius.card)
        .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
    }

    private func featureItem(icon: String, title: String) -> some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeManager.current.primaryColor)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(themeManager.current.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.small)
        .background(themeManager.current.card)
        .cornerRadius(AppCornerRadius.card)
        .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
    }
}

#Preview {
    MeView()
}

struct SupportEmail {
    let toAddress = "appsbayarea@gmail.com"
    let subject: String = String(localized: "\("LongevityMaster") - \("Feedback")")
    var body: String { """
      Application Name: \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown")
      iOS Version: \(UIDevice.current.systemVersion)
      Device Model: \(UIDevice.current.model)
      App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "no app version")
      App Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "no app build version")

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
                print("Device doesn't support email.\n \(body)")
            }
        }
    }
}
