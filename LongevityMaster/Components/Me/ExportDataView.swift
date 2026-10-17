//
// Created by Banghua Zhao on 17/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI

/// Hands the user a copy of everything they have recorded: check-ins as a spreadsheet, and a
/// full backup. The files are prepared as the screen opens, so each share button has a finished
/// file behind it by the time it can be tapped.
struct ExportDataView: View {
    @Dependency(\.defaultDatabase) private var database
    @Dependency(\.themeManager) private var themeManager

    private enum Status {
        case preparing
        case ready(DataExport.Files)
        case failed
    }

    @State private var status: Status = .preparing

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                introCard

                switch status {
                case .preparing:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.large)
                case .ready(let files):
                    exportCard(
                        title: "Check-ins (CSV)",
                        detail: "One row per check-in, to open in Numbers, Excel or Google Sheets.",
                        systemImage: "tablecells",
                        file: files.checkInsCSV
                    )
                    exportCard(
                        title: "Full Backup (JSON)",
                        detail: "Every habit, check-in, rest day, reminder and program, in one file.",
                        systemImage: "externaldrive",
                        file: files.backupJSON
                    )
                    // Labels rather than "312 check-ins across 9 habits": the catalog has no plural
                    // rules, and "1 habits" is what the sentence form would print.
                    Text("Habits: \(files.habitCount)  ·  Check-ins: \(files.checkInCount)")
                        .font(AppFont.footnote)
                        .foregroundStyle(themeManager.current.textSecondary)
                        .frame(maxWidth: .infinity)
                case .failed:
                    failedCard
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await prepare()
        }
    }

    private var introCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.smallMedium) {
            Image(systemName: "lock.shield")
                .font(.title2)
                .foregroundStyle(themeManager.current.primaryColor)
                .frame(width: 44, height: 44)
                .background(themeManager.current.primaryColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text("Your data, your copy")
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
                Text("Longevity Master keeps your habits on this device. Export a copy to keep somewhere safe, or to look at in a spreadsheet.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .appCardStyle(theme: themeManager.current)
    }

    private func exportCard(
        title: LocalizedStringKey,
        detail: LocalizedStringKey,
        systemImage: String,
        file: URL
    ) -> some View {
        ShareLink(item: file) {
            HStack(spacing: AppSpacing.smallMedium) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(themeManager.current.primaryColor)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.headline)
                        .foregroundStyle(themeManager.current.textPrimary)
                    Text(detail)
                        .font(AppFont.footnote)
                        .foregroundStyle(themeManager.current.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(themeManager.current.primaryColor)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // Saving to Files or sending by Mail can mean a trip to another app; no ad on the way back.
        .simultaneousGesture(TapGesture().onEnded { AppOpenAdPolicy.skipNextReturn() })
        .appCardStyle(theme: themeManager.current)
    }

    private var failedCard: some View {
        VStack(spacing: AppSpacing.smallMedium) {
            Text("The export could not be prepared. Please try again.")
                .font(AppFont.subheadline)
                .foregroundStyle(themeManager.current.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await prepare() }
            } label: {
                Text("Try Again")
            }
            .appRectButtonStyle()
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(theme: themeManager.current)
    }

    /// Reads in one transaction, then builds the files off the main thread: years of check-ins
    /// make a file worth not stalling the screen for.
    private func prepare() async {
        status = .preparing
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let directory = URL.temporaryDirectory.appending(component: "Export", directoryHint: .isDirectory)
        do {
            let snapshot = try await database.read { db in
                try DataExport.Snapshot.fetch(db)
            }
            let files = try await Task.detached(priority: .userInitiated) {
                try DataExport.write(
                    snapshot,
                    now: Date(),
                    calendar: .current,
                    appVersion: appVersion,
                    to: directory
                )
            }.value
            status = .ready(files)
        } catch {
            debugLog("export failed: \(error)")
            status = .failed
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    NavigationStack {
        ExportDataView()
    }
}
