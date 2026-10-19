//
// Created by Banghua Zhao on 19/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

/// What the app shows instead of its tabs when its database would not open at launch.
///
/// The point is that the user's data is still there: nothing has been deleted, so the screen
/// says so, lets them try again, and gives them a way to get the file to us if it keeps
/// happening — rather than the crash on every launch this used to be.
struct DatabaseUnavailableView: View {
    /// Thrown in DEBUG builds launched with `-simulateDatabaseFailure`.
    struct SimulatedFailure: Error {}

    /// Why the database would not open, as the error described itself. Only ever sent to
    /// support, never shown: it means nothing to the reader.
    let failure: String

    @Environment(\.openURL) private var openURL
    @State private var retry: RetryResult?
    @State private var latestBackup = AutoBackup.entries().first
    @State private var isConfirmingRestore = false
    @State private var restore: RestoreResult?

    private enum RetryResult {
        case opened
        case stillFailing
    }

    private enum RestoreResult {
        case restoring
        case restored
        case failed
    }

    private let theme = ThemeManager.shared.current

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 56))
                    .foregroundStyle(theme.primaryColor)
                    .padding(.top, AppSpacing.large)

                VStack(spacing: AppSpacing.small) {
                    Text("Your habits couldn't be opened")
                        .font(AppFont.title)
                        .foregroundStyle(theme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Nothing has been deleted. Longevity Master couldn't open the data it keeps on this device. Closing the app and opening it again often fixes this.")
                        .font(AppFont.body)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let retry {
                    Text(retry == .opened
                        ? "Your data opened this time. Close Longevity Master and open it again to carry on."
                        : "It still couldn't be opened. If this keeps happening, contact us and we'll help you get your data back.")
                        .font(AppFont.subheadline)
                        .foregroundStyle(theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .appCardStyle(theme: theme)
                }

                if let latestBackup {
                    automaticBackupCard(latestBackup)
                }

                VStack(spacing: AppSpacing.smallMedium) {
                    Button {
                        tryAgain()
                    } label: {
                        Text("Try Again")
                            .frame(maxWidth: .infinity)
                    }
                    .appRectButtonStyle(theme: theme)

                    Button {
                        contactSupport()
                    } label: {
                        Label("Contact Us", systemImage: "envelope")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(theme.primaryColor)

                    let files = liveDatabaseFiles()
                    if !files.isEmpty {
                        ShareLink(items: files) {
                            Label("Send Data File", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.primaryColor)
                    }
                }
            }
            .padding()
        }
        .background(theme.background.ignoresSafeArea())
        .confirmationDialog(
            "Restore the automatic backup?",
            isPresented: $isConfirmingRestore,
            titleVisibility: .visible
        ) {
            Button("Restore Backup") {
                if let latestBackup {
                    Task { await restore(from: latestBackup) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Anything recorded since the backup was made will be missing. The data that couldn't be opened is kept aside, not deleted.")
        }
    }

    /// The way back for someone who never exported anything: yesterday's automatic backup, or
    /// thereabouts, in place of the database that will not open.
    private func automaticBackupCard(_ backup: AutoBackup.Entry) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            switch restore {
            case .restored:
                Label("Backup restored", systemImage: "checkmark.circle.fill")
                    .font(AppFont.headline)
                    .foregroundStyle(theme.primaryColor)
                Text("Close Longevity Master and open it again to carry on.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .restoring:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case nil, .failed:
                Text("Automatic backup from \(backup.day.formatted(date: .long, time: .omitted))")
                    .font(AppFont.headline)
                    .foregroundStyle(theme.textPrimary)
                Text(restore == .failed
                    ? "The backup couldn't be restored. Nothing has been changed."
                    : "If trying again doesn't help, you can start again from this backup.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    isConfirmingRestore = true
                } label: {
                    Text("Restore Backup")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(theme.primaryColor)
                .padding(.top, AppSpacing.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: theme)
    }

    private func restore(from backup: AutoBackup.Entry) async {
        withAnimation { restore = .restoring }
        let succeeded = await Task.detached(priority: .userInitiated) {
            do {
                let plan = try DataRestore.plan(from: Data(contentsOf: backup.url), calendar: .current, now: Date())
                try DatabaseRecovery.rebuild(from: plan)
                return true
            } catch {
                debugLog("recovery from automatic backup failed: \(error)")
                return false
            }
        }.value
        withAnimation { restore = succeeded ? .restored : .failed }
    }

    /// Opening the file again is all a retry can do: everything else in the app is already
    /// running on the stand-in, so a database that opens now still needs the app restarted.
    private func tryAgain() {
        // Opened and then let go; nothing is read or written through it.
        let opened = (try? appDatabase()) != nil
        withAnimation {
            retry = opened ? .opened : .stillFailing
        }
    }

    private func contactSupport() {
        var email = SupportEmail()
        email.details = "Database error: \(failure)"
        email.send(openURL: openURL)
    }
}

#Preview {
    DatabaseUnavailableView(failure: "SQLite error 11: database disk image is malformed")
}
