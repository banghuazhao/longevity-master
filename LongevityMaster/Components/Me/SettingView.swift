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
    @AppStorage(NotificationService.weeklyReviewEnabledKey) private var weeklyReviewEnabled: Bool = true
    @Shared(.appStorage("lastQuoteDismissedDate")) private var lastQuoteDismissedDate: Date? = nil
    @Dependency(\.themeManager) var themeManager
    @Dependency(\.consentManager) var consentManager
    @Environment(\.openURL) private var openURL

    private var theme: AppTheme { themeManager.current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                section("General") {
                    AppRow("Appearance", systemImage: "circle.lefthalf.filled", color: .indigo) {
                        Picker("Appearance", selection: $appearanceMode) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .tint(theme.primaryColor)
                    }
                    AppRowDivider()
                    AppRow("Week Starts On", systemImage: "calendar", color: .red) {
                        Picker("Week Starts On", selection: $startWeekOnMonday) {
                            Text(String(localized: "Monday")).tag(true)
                            Text(String(localized: "Sunday")).tag(false)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .tint(theme.primaryColor)
                    }
                    .onChange(of: startWeekOnMonday) { _, newValue in
                        // The widget works out week boundaries too, and reads this from the
                        // shared container because it cannot see the app's own defaults.
                        AppGroup.mirrorStartWeekOnMonday(newValue)
                        WidgetRefresher.reload()
                        // The weekly review lands on the week's last day, which just moved.
                        Task { await NotificationService.shared.syncWeeklyReview() }
                    }
                }

                section("Feedback") {
                    toggleRow($buttonSoundEnabled, "Checkin Sound", systemImage: "speaker.wave.2.fill", color: .pink)
                    AppRowDivider()
                    toggleRow($vibrateEnabled, "Vibrate", systemImage: "iphone.radiowaves.left.and.right", color: .purple)
                }

                section("Motivation") {
                    toggleRow($motivationalQuotesEnabled, "Daily Motivational Quotes", systemImage: "quote.bubble.fill", color: .orange)
                    AppRowDivider()
                    toggleRow(
                        $weeklyReviewEnabled,
                        "Weekly Review",
                        subtitle: "A look back at your week, at 7pm on its last day",
                        systemImage: "calendar.badge.checkmark",
                        color: .green
                    )
                    .onChange(of: weeklyReviewEnabled) { _, _ in
                        Task { await NotificationService.shared.syncWeeklyReview() }
                    }
                    AppRowDivider()
                    AppRow("Reset Today's Motivation", systemImage: "arrow.counterclockwise", color: .teal) {
                        Button {
                            $lastQuoteDismissedDate.withLock { $0 = nil }
                        } label: {
                            Text("Reset")
                                .font(AppFont.subheadline.weight(.semibold))
                                .padding(.horizontal, AppSpacing.smallMedium)
                                .padding(.vertical, 6)
                                .background(theme.primaryColor.opacity(0.12), in: Capsule())
                                .foregroundStyle(theme.primaryColor)
                        }
                        .buttonStyle(.plain)
                    }
                }

                section("Your Data") {
                    NavigationLink {
                        ExportDataView()
                    } label: {
                        AppRow("Export Data", systemImage: "square.and.arrow.up", color: .blue)
                    }
                    AppRowDivider()
                    NavigationLink {
                        RestoreBackupView()
                    } label: {
                        AppRow("Restore from Backup", systemImage: "clock.arrow.circlepath", color: .green)
                    }
                }
                .buttonStyle(AppRowButtonStyle())

                section("Privacy") {
                    // Whole-row buttons: the consent row comes and goes depending on region, and
                    // an identified collection keeps each row pinned to its own action as the
                    // list changes.
                    let rows = privacyRows
                    ForEach(rows) { row in
                        if row.id != rows.first?.id {
                            AppRowDivider()
                        }
                        Button(action: row.action) {
                            AppRow(row.title, systemImage: row.icon, color: row.color) {
                                AppRowChevron(isExternal: row.isExternal)
                            }
                        }
                    }
                }
                .buttonStyle(AppRowButtonStyle())
            }
            .padding(.horizontal)
            .padding(.top, AppSpacing.small)
            .padding(.bottom, AppSpacing.large)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleRow(
        _ isOn: Binding<Bool>,
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        systemImage: String,
        color: Color
    ) -> some View {
        Toggle(isOn: isOn) {
            AppRowLabel(title, subtitle: subtitle, systemImage: systemImage, color: color)
        }
        .tint(theme.primaryColor)
        .appRowPadding()
    }

    private struct PrivacyRow: Identifiable {
        let id: String
        let title: LocalizedStringKey
        let icon: String
        let color: Color
        var isExternal = false
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
                    title: "Manage Consent",
                    icon: "slider.horizontal.3",
                    color: .gray
                ) {
                    Task { await consentManager.presentPrivacyOptionsForm() }
                }
            )
        }
        rows.append(
            PrivacyRow(
                id: "privacy-policy",
                title: "Privacy Policy",
                icon: "hand.raised.fill",
                color: .blue,
                isExternal: true
            ) {
                if let url = URL(string: "https://apps-bay.github.io/Apps-Bay-Website/privacy/") {
                    openURL(url)
                }
            }
        )
        return rows
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
        }
    }
}
