//
//  SettingView.swift
//  LongevityMaster
//
//  Created by Lulin Yang on 2025/7/1.
//
import SwiftUI
import Dependencies
import Sharing

struct SettingView: View {
    @AppStorage("startWeekOnMonday") private var startWeekOnMonday: Bool = true
    @AppStorage("buttonSoundEnabled") private var buttonSoundEnabled: Bool = true
    @AppStorage("vibrateEnabled") private var vibrateEnabled: Bool = true
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode: String = AppearanceMode.system.rawValue
    @AppStorage("motivationalQuotesEnabled") private var motivationalQuotesEnabled: Bool = true
    @Shared(.appStorage("lastQuoteDismissedDate")) private var lastQuoteDismissedDate: Date? = nil
    @Dependency(\.themeManager) var themeManager

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                settingsSection(title: "Week Starts On") {
                    HStack {
                        Spacer()
                        Picker("Week Start", selection: $startWeekOnMonday) {
                            Text(String(localized: "Monday")).tag(true)
                            Text(String(localized: "Sunday")).tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        Spacer()
                    }
                    .onChange(of: startWeekOnMonday) { _, newValue in
                        // The widget works out week boundaries too, and reads this from the
                        // shared container because it cannot see the app's own defaults.
                        AppGroup.mirrorStartWeekOnMonday(newValue)
                        WidgetRefresher.reload()
                    }
                }
                settingsSection(title: "Feedback") {
                    Toggle(isOn: $buttonSoundEnabled) {
                        Text(String(localized: "Checkin Sound"))
                            .font(AppFont.body)
                            .foregroundColor(themeManager.current.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.current.primaryColor))
                    Toggle(isOn: $vibrateEnabled) {
                        Text(String(localized: "Vibrate"))
                            .font(AppFont.body)
                            .foregroundColor(themeManager.current.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.current.primaryColor))
                }
                settingsSection(title: "Motivation") {
                    Toggle(isOn: $motivationalQuotesEnabled) {
                        Text(String(localized: "Daily Motivational Quotes"))
                            .font(AppFont.body)
                            .foregroundColor(themeManager.current.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.current.primaryColor))
                    
                    HStack {
                        Text("Reset Today's Motivation")
                        Spacer()
                        
                        Button {
                            $lastQuoteDismissedDate.withLock { $0 = nil }
                        } label: {
                            Text("Reset")
                        }
                        .appRectButtonStyle()
                    }
                }
                settingsSection(title: "Appearance") {
                    HStack {
                        Spacer()
                        Picker("Appearance", selection: $appearanceMode) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .background(themeManager.current.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .appSectionHeader(theme: themeManager.current)
            VStack(spacing: AppSpacing.small) {
                content()
            }
            .padding()
            .background(themeManager.current.card)
            .cornerRadius(AppCornerRadius.card)
            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
        }
    }
}
