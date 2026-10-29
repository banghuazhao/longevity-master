//
// Created by Banghua Zhao on 20/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

/// What a release added, shown once to people updating into it. Snooze and the quick actions
/// in particular live outside the app's own screens, where nobody finds them by looking.
enum WhatsNew {
    /// The release these notes are for. Changes with each release that has notes worth
    /// showing; a bug-fix update that keeps it shows nothing again.
    static let release = "1.9"
    static let lastSeenKey = "whatsNewLastSeenRelease"

    struct Item: Identifiable {
        let systemImage: String
        let title: LocalizedStringKey
        let detail: LocalizedStringKey
        var id: String { systemImage }
    }

    static let items: [Item] = [
        Item(
            systemImage: "checkmark.circle",
            title: "A New Today Screen",
            detail: "See your day's progress at a glance, tap through the week, and get a little celebration when everything is done."
        ),
        Item(
            systemImage: "clock.arrow.circlepath",
            title: "Restore from Backup",
            detail: "Bring back a backup made with Export Data — on a new phone, or after starting over. Settings → Your Data."
        ),
        Item(
            systemImage: "externaldrive.badge.checkmark",
            title: "Automatic Backups",
            detail: "A backup of each of the last 7 days you opened the app is kept on this device, ready to restore."
        ),
        Item(
            systemImage: "bell.badge",
            title: "Remind Me in 1 Hour",
            detail: "Not the right moment? Press and hold a reminder to be reminded again in an hour."
        ),
        Item(
            systemImage: "hand.tap",
            title: "Quick Actions",
            detail: "Press and hold the app icon to check in, add a habit, or look back on your week."
        ),
    ]

    /// Whether to show the notes now. Someone who has never finished onboarding is new to the
    /// app, not to this release, and has nothing to compare it with.
    static func shouldShow(lastSeen: String?, hasCompletedOnboarding: Bool) -> Bool {
        hasCompletedOnboarding && lastSeen != release
    }

    static func markSeen(_ defaults: UserDefaults = .standard) {
        defaults.set(release, forKey: lastSeenKey)
    }

    /// Called once per launch, after consent has been dealt with so the two never compete for
    /// the screen. Leaves the notes for another launch if something else is already showing,
    /// such as the screen a tapped notification opened.
    @MainActor
    static func presentIfDue(defaults: UserDefaults = .standard) {
        let hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        guard shouldShow(lastSeen: defaults.string(forKey: lastSeenKey), hasCompletedOnboarding: hasCompletedOnboarding) else {
            // A new install starts out having seen this release.
            if !hasCompletedOnboarding { markSeen(defaults) }
            return
        }
        let router = AppRouter.shared
        guard router.presented == nil else { return }
        markSeen(defaults)
        router.presented = .whatsNew
    }
}

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text("What's New")
                        .font(AppFont.largeTitle)
                        .foregroundStyle(themeManager.current.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppSpacing.large)

                    ForEach(WhatsNew.items) { item in
                        HStack(alignment: .top, spacing: AppSpacing.medium) {
                            Image(systemName: item.systemImage)
                                .font(.title2)
                                .foregroundStyle(themeManager.current.primaryColor)
                                .frame(width: 40)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(AppFont.headline)
                                    .foregroundStyle(themeManager.current.textPrimary)
                                Text(item.detail)
                                    .font(AppFont.subheadline)
                                    .foregroundStyle(themeManager.current.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal)
            }

            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .appRectButtonStyle()
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(themeManager.current.background.ignoresSafeArea())
    }
}

#Preview {
    WhatsNewView()
}
