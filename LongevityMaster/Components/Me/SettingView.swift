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
    @Dependency(\.consentManager) var consentManager
    @Environment(\.openURL) private var openURL

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
                settingsSection(title: "Privacy") {
                    // Whole-row buttons: the consent row comes and goes depending on region, and
                    // an identified collection keeps each row pinned to its own action as the
                    // list changes.
                    ForEach(privacyRows) { row in
                        Button(action: row.action) {
                            HStack {
                                Text(row.title)
                                    .font(AppFont.body)
                                    .foregroundColor(themeManager.current.textPrimary)
                                Spacer()
                                Image(systemName: row.icon)
                                    .foregroundColor(themeManager.current.primaryColor)
                            }
                            .padding(.vertical, AppSpacing.small)
                            // Keeps the tappable area to this row alone.
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(themeManager.current.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct PrivacyRow: Identifiable {
        let id: String
        let title: String
        let icon: String
        let action: () -> Void
    }

    private var privacyRows: [PrivacyRow] {
        var rows: [PrivacyRow] = []
        // Only offered where a choice actually exists to change: UMP reports privacy options as
        // required in the EEA/UK and other regulated regions, and as not required elsewhere.
        if consentManager.isPrivacyOptionsRequired {
            rows.append(
                PrivacyRow(
                    id: "manage-consent",
                    title: String(localized: "Manage Consent"),
                    icon: "slider.horizontal.3"
                ) {
                    Task { await consentManager.presentPrivacyOptionsForm() }
                }
            )
        }
        rows.append(
            PrivacyRow(
                id: "privacy-policy",
                title: String(localized: "Privacy Policy"),
                icon: "arrow.up.right.square"
            ) {
                if let url = URL(string: "https://apps-bay.github.io/Apps-Bay-Website/privacy/") {
                    openURL(url)
                }
            }
        )
        return rows
    }

    private func settingsSection<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
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
