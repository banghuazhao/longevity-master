//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI

/// The Today tab's programs: each one under way, a finished one waiting to be celebrated, or —
/// for someone who has never started one — a way in.
struct ProgramsTodaySection: View {
    let viewModel: ProgramsViewModel

    /// Once dismissed, the invitation stays gone; programs have their own tab.
    @AppStorage("hideProgramsInvitation") private var hideInvitation = false
    @State private var results: ProgramsViewModel.Enrolled?
    @Environment(\.selectTab) private var selectTab

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        let current = viewModel.current

        if !current.isEmpty {
            VStack(spacing: AppSpacing.smallMedium) {
                ForEach(current) { enrolled in
                    if enrolled.progress.isFinished {
                        completedCard(enrolled)
                    } else {
                        NavigationLink {
                            ProgramDetailView(program: enrolled.program, viewModel: viewModel)
                        } label: {
                            ProgramProgressCard(enrolled: enrolled)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, AppSpacing.medium)
            .padding(.bottom, AppSpacing.small)
            .sheet(item: $results) { enrolled in
                ProgramCompletionView(enrolled: enrolled, viewModel: viewModel)
            }
        } else if viewModel.enrollments.isEmpty && !hideInvitation {
            invitation
                .padding(.top, AppSpacing.medium)
                .padding(.bottom, AppSpacing.small)
        }
    }

    private func completedCard(_ enrolled: ProgramsViewModel.Enrolled) -> some View {
        VStack(spacing: AppSpacing.smallMedium) {
            Button {
                results = enrolled
            } label: {
                completedSummary(enrolled)
            }
            .buttonStyle(.plain)

            HStack(spacing: AppSpacing.smallMedium) {
                Button {
                    withAnimation {
                        viewModel.archive(enrolled)
                    }
                } label: {
                    Text("Done")
                        .font(AppFont.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.current.primaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(themeManager.current.primaryColor.opacity(0.12), in: RoundedRectangle(cornerRadius: AppCornerRadius.button))
                }

                Button {
                    results = enrolled
                } label: {
                    Label("See Results", systemImage: "rosette")
                        .font(AppFont.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(themeManager.current.primaryColor, in: RoundedRectangle(cornerRadius: AppCornerRadius.button))
                }
            }
        }
        .appCardStyle(theme: themeManager.current)
    }

    private func completedSummary(_ enrolled: ProgramsViewModel.Enrolled) -> some View {
        HStack(spacing: AppSpacing.smallMedium) {
            ProgramIcon(program: enrolled.program, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("🎉 Program completed")
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
                if let percent = enrolled.progress.adherencePercent {
                    Text("\(enrolled.program.title) · \(percent)% on track")
                        .font(AppFont.subheadline)
                        .foregroundStyle(themeManager.current.textSecondary)
                } else {
                    Text(enrolled.program.title)
                        .font(AppFont.subheadline)
                        .foregroundStyle(themeManager.current.textSecondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(themeManager.current.textSecondary)
        }
        .contentShape(.rect)
    }

    private var invitation: some View {
        Button {
            selectTab(.programs)
        } label: {
            HStack(spacing: AppSpacing.smallMedium) {
                Text("🗺️")
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Try a guided program")
                        .font(AppFont.headline)
                        .foregroundStyle(themeManager.current.textPrimary)
                    Text("3–4 week plans for strength, sleep, diet and more.")
                        .font(AppFont.footnote)
                        .foregroundStyle(themeManager.current.textSecondary)
                }
                Spacer(minLength: 0)
                Button {
                    withAnimation { hideInvitation = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(themeManager.current.textSecondary)
                        .padding(6)
                }
                .accessibilityLabel(Text("Dismiss"))
            }
            .appCardStyle(theme: themeManager.current)
        }
        .buttonStyle(.plain)
    }
}
