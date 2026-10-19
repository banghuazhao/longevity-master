//
// Created by Banghua Zhao on 19/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI
import UniformTypeIdentifiers

/// Brings back a full backup made with Export Data — onto a new phone, or after starting
/// over. The file is read and checked in full, and what it holds is shown, before the user
/// is asked to replace anything; nothing is written until they agree.
struct RestoreBackupView: View {
    @Dependency(\.defaultDatabase) private var database
    @Dependency(\.themeManager) private var themeManager
    @Dependency(\.notificationService) private var notificationService

    private enum Status {
        case idle
        case reading
        case ready(DataRestore.Plan)
        case restoring
        case restored
        case failed(LocalizedStringKey)
    }

    @State private var status: Status = .idle
    @State private var isChoosingFile = false
    @State private var isConfirming = false
    @State private var automaticBackups: [AutoBackup.Entry] = []

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                introCard

                switch status {
                case .idle:
                    chooseFileButton
                    automaticBackupsCard
                case .reading, .restoring:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.large)
                case .ready(let plan):
                    planCard(plan)
                case .restored:
                    restoredCard
                case .failed(let message):
                    messageCard(message)
                    chooseFileButton
                    automaticBackupsCard
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Restore from Backup")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            automaticBackups = AutoBackup.entries()
        }
        .fileImporter(isPresented: $isChoosingFile, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                Task { await read(url) }
            case .failure:
                status = .failed("The file couldn't be opened. Your data hasn't changed.")
            }
        }
        .confirmationDialog(
            "Replace all your data?",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("Replace My Data", role: .destructive) {
                if case .ready(let plan) = status {
                    Task { await restore(plan) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current habits, check-ins, rest days, reminders and programs will be replaced by this backup. This can't be undone.")
        }
    }

    private var introCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.smallMedium) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title2)
                .foregroundStyle(themeManager.current.primaryColor)
                .frame(width: 44, height: 44)
                .background(themeManager.current.primaryColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text("Bring back a backup")
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
                Text("Choose a Full Backup (JSON) made with Export Data. Restoring replaces everything in the app with what the backup holds.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                NavigationLink {
                    ExportDataView()
                } label: {
                    Text("Export your current data first")
                        .font(AppFont.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.current.primaryColor)
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .appCardStyle(theme: themeManager.current)
    }

    private var chooseFileButton: some View {
        Button {
            // Files can mean a trip through iCloud Drive or another app; no ad on the way back.
            AppOpenAdPolicy.skipNextReturn()
            isChoosingFile = true
        } label: {
            Label("Choose Backup File", systemImage: "doc.badge.arrow.up")
                .frame(maxWidth: .infinity)
        }
        .appRectButtonStyle()
    }

    /// The backups the app writes on its own each day, for someone who never exported one.
    @ViewBuilder
    private var automaticBackupsCard: some View {
        if !automaticBackups.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Automatic Backups")
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
                Text("Longevity Master keeps a backup of each of the last 7 days you opened it, on this device.")
                    .font(AppFont.footnote)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(automaticBackups) { entry in
                    Button {
                        Task { await read(entry.url) }
                    } label: {
                        HStack {
                            Text(entry.day.formatted(date: .complete, time: .omitted))
                                .font(AppFont.body)
                                .foregroundStyle(themeManager.current.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(themeManager.current.textSecondary)
                        }
                        .padding(.vertical, AppSpacing.small)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCardStyle(theme: themeManager.current)
        }
    }

    private func planCard(_ plan: DataRestore.Plan) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            if let exportedAt = plan.exportedAt {
                Text("Backup from \(exportedAt.formatted(date: .long, time: .shortened))")
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
            } else {
                Text("Backup")
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
            }
            // Labels rather than a sentence, as on the export screen: the catalog has no
            // plural rules.
            Text("Habits: \(plan.habits.count)  ·  Check-ins: \(plan.checkIns.count)  ·  Reminders: \(plan.reminders.count)")
                .font(AppFont.subheadline)
                .foregroundStyle(themeManager.current.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(role: .destructive) {
                isConfirming = true
            } label: {
                Text("Restore This Backup")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.top, AppSpacing.small)

            Button {
                AppOpenAdPolicy.skipNextReturn()
                isChoosingFile = true
            } label: {
                Text("Choose a Different File")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(themeManager.current.primaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    private var restoredCard: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(themeManager.current.primaryColor)
            Text("Backup restored")
                .font(AppFont.headline)
                .foregroundStyle(themeManager.current.textPrimary)
            Text("Your habits, check-ins and reminders are back.")
                .font(AppFont.subheadline)
                .foregroundStyle(themeManager.current.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(theme: themeManager.current)
    }

    private func messageCard(_ message: LocalizedStringKey) -> some View {
        Text(message)
            .font(AppFont.subheadline)
            .foregroundStyle(themeManager.current.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .appCardStyle(theme: themeManager.current)
    }

    /// Reads and checks the file off the main thread: years of check-ins make a file worth
    /// not stalling the screen for.
    private func read(_ url: URL) async {
        status = .reading
        let calendar = Calendar.current
        let result = await Task.detached(priority: .userInitiated) { () -> Result<DataRestore.Plan, Error> in
            // A file picked from Files is only lent to the app while it is being read.
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }
            return Result {
                let data = try Data(contentsOf: url)
                return try DataRestore.plan(from: data, calendar: calendar, now: Date())
            }
        }.value

        switch result {
        case .success(let plan):
            status = .ready(plan)
        case .failure(DataRestore.Failure.notABackup):
            status = .failed("This isn't a Longevity Master backup. Choose the Full Backup (JSON) file made with Export Data.")
        case .failure(DataRestore.Failure.newerVersion):
            status = .failed("This backup was made by a newer version of Longevity Master. Update the app, then try again.")
        case .failure(DataRestore.Failure.damaged):
            status = .failed("This backup is damaged and can't be restored. Your data hasn't changed.")
        case .failure(let error):
            debugLog("restore read failed: \(error)")
            status = .failed("The file couldn't be opened. Your data hasn't changed.")
        }
    }

    private func restore(_ plan: DataRestore.Plan) async {
        status = .restoring
        do {
            try await database.write { db in
                try DataRestore.replaceAll(with: plan, in: db)
            }
        } catch {
            debugLog("restore failed: \(error)")
            status = .failed("The backup couldn't be restored. Your data hasn't changed.")
            return
        }
        // Takes down whatever the replaced reminders had registered, and registers the
        // restored ones.
        await notificationService.syncAllReminders()
        WidgetRefresher.reload()
        Haptics.shared.vibrateIfEnabled()
        status = .restored
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    NavigationStack {
        RestoreBackupView()
    }
}
