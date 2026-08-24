//
// Created by Banghua Zhao on 24/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

struct LanguageView: View {
    @Dependency(\.themeManager) var themeManager
    @AppStorage(AppLanguage.storageKey) private var storedLanguage: String = AppLanguage.system.rawValue
    @State private var showRestartNotice = false

    private var selected: AppLanguage {
        AppLanguage(rawValue: storedLanguage) ?? .system
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                VStack(spacing: AppSpacing.medium) {
                    Text(String(localized: "Choose Language"))
                        .font(AppFont.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.current.textPrimary)

                    Text(String(localized: "Pick the language the app is shown in, or follow the language your device is set to."))
                        .font(AppFont.body)
                        .foregroundColor(themeManager.current.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.large)

                VStack(spacing: .zero) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            onTap(language)
                        } label: {
                            row(for: language)
                        }
                        .buttonStyle(.plain)

                        if language != AppLanguage.allCases.last {
                            Divider()
                        }
                    }
                }
                .appCardStyle(theme: themeManager.current)
                .padding(.horizontal)

                Text(String(localized: "The app stays in its current language until you close and reopen it."))
                    .font(AppFont.footnote)
                    .foregroundColor(themeManager.current.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.large)

                Spacer(minLength: AppSpacing.large)
            }
        }
        .appBackground(theme: themeManager.current)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .alert(String(localized: "Reopen to Finish"), isPresented: $showRestartNotice) {
            Button(String(localized: "Done"), role: .cancel) {}
        } message: {
            Text(String(localized: "Close the app and open it again to finish changing the language."))
        }
    }

    private func row(for language: AppLanguage) -> some View {
        HStack {
            Text(language.title)
                .font(AppFont.body)
                .foregroundColor(themeManager.current.textPrimary)

            Spacer()

            if language == selected {
                Image(systemName: "checkmark")
                    .font(AppFont.headline)
                    .foregroundColor(themeManager.current.primaryColor)
            }
        }
        .padding(.vertical, AppSpacing.smallMedium)
        // Without this the row only responds to taps on the text itself.
        .contentShape(Rectangle())
    }

    private func onTap(_ language: AppLanguage) {
        Haptics.shared.vibrateIfEnabled()
        guard language != selected else { return }
        AppLanguage.select(language)
        showRestartNotice = true
    }
}

#Preview {
    NavigationStack {
        LanguageView()
    }
}
