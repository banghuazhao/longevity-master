//
//  SettingView.swift
//  LongevityMaster
//
//  Created by Lulin Yang on 2025/7/1.
//
import SwiftUI
import Dependencies

struct SettingView: View {
    @AppStorage("startWeekOnMonday") private var startWeekOnMonday: Bool = true
    @AppStorage("buttonSoundEnabled") private var buttonSoundEnabled: Bool = true
    @AppStorage("vibrateEnabled") private var vibrateEnabled: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
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
                settingsSection(title: "Appearance") {
                    Toggle(isOn: $darkModeEnabled) {
                        Text(String(localized: "Dark Mode"))
                            .font(AppFont.body)
                            .foregroundColor(themeManager.current.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.current.primaryColor))
                }
            }
            .padding()
        }
        .background(themeManager.current.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
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
