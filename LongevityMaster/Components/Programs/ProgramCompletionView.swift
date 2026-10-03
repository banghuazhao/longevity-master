//
// Created by Banghua Zhao on 03/10/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI

/// The end of a program: how it went, habit by habit, and what to do next. Finishing is where
/// people tend to drift off, so this screen celebrates first and then offers a next step.
struct ProgramCompletionView: View {
    let enrolled: ProgramsViewModel.Enrolled
    let viewModel: ProgramsViewModel

    @Environment(\.dismiss) private var dismiss
    @Dependency(\.themeManager) private var themeManager
    @State private var badgeScale = 0.6

    var body: some View {
        let results = viewModel.habitResults(for: enrolled)
        let nextPrograms = viewModel.recommendations(after: enrolled)

        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.medium) {
                    header
                    statsRow
                    if !results.isEmpty {
                        habitsCard(results)
                    }
                    upNextCard(nextPrograms)
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .appBackground()
            .navigationTitle("Program Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .appToolbarCircularButtonStyle()
                    }
                    .accessibilityLabel(Text("Close"))
                }
            }
            .onAppear {
                Haptics.shared.vibrateIfEnabled()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                    badgeScale = 1
                }
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        let progress = enrolled.progress
        let start = enrolled.enrollment.startDate
        let end = Calendar.current.date(byAdding: .day, value: progress.durationDays - 1, to: start) ?? start

        return VStack(spacing: AppSpacing.small) {
            ZStack(alignment: .topTrailing) {
                ProgramIcon(program: enrolled.program, size: 96)
                Text(verbatim: "🎉")
                    .font(.system(size: 34))
                    .offset(x: 18, y: -18)
            }
            .scaleEffect(badgeScale)
            .padding(.top, AppSpacing.small)

            Text("You finished \(enrolled.program.title)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.current.textPrimary)
                .multilineTextAlignment(.center)

            Text(verbatim: "\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))")
                .font(AppFont.footnote)
                .foregroundStyle(themeManager.current.textSecondary)

            Text(verdict)
                .font(AppFont.subheadline)
                .foregroundStyle(themeManager.current.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    private var verdict: LocalizedStringKey {
        guard let adherence = enrolled.progress.adherence else {
            return "You saw it through to the end."
        }
        switch adherence {
        case 0.85...:
            return "You kept to the plan almost every day. These habits are part of your routine now."
        case 0.6..<0.85:
            return "You stuck with it to the very end — most people stop in the first week."
        default:
            return "You saw it through to the end. Run it again and see how much further you get."
        }
    }

    private var statsRow: some View {
        let progress = enrolled.progress
        return HStack(spacing: AppSpacing.small) {
            if let percent = progress.adherencePercent {
                statTile(value: "\(percent)%", label: "on track")
            }
            statTile(value: "\(progress.checkInCount)", label: "check-ins")
            statTile(value: "\(progress.durationDays)", label: "days")
        }
    }

    private func statTile(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.current.primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(AppFont.footnote)
                .foregroundStyle(themeManager.current.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.smallMedium)
        .background(themeManager.current.card, in: RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
    }

    private func habitsCard(_ results: [(habit: Habit, progress: ProgramProgress)]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle("How each habit went", systemImage: "checklist")

            ForEach(results, id: \.habit.id) { result in
                HStack(spacing: AppSpacing.smallMedium) {
                    Text(result.habit.icon)
                        .font(.system(size: 20))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: result.habit.color), in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(result.habit.name)
                                .font(AppFont.subheadline.weight(.medium))
                                .foregroundStyle(themeManager.current.textPrimary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            if let percent = result.progress.adherencePercent {
                                Text(verbatim: "\(percent)%")
                                    .font(AppFont.subheadline.weight(.semibold))
                                    .foregroundStyle(themeManager.current.primaryColor)
                            }
                        }
                        ProgressView(value: min(result.progress.adherence ?? 0, 1))
                            .tint(themeManager.current.primaryColor)
                    }
                }
            }

            Text("They stay on your habit list — they're yours now.")
                .font(AppFont.footnote)
                .foregroundStyle(themeManager.current.textSecondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    private func upNextCard(_ nextPrograms: [Program]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle("Up next", systemImage: "arrow.forward.circle")

            ForEach(nextPrograms) { program in
                HStack(spacing: AppSpacing.smallMedium) {
                    ProgramIcon(program: program, size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(program.title)
                            .font(AppFont.subheadline.weight(.semibold))
                            .foregroundStyle(themeManager.current.textPrimary)
                        Text(program.subtitle)
                            .font(AppFont.footnote)
                            .foregroundStyle(themeManager.current.textSecondary)
                            .lineLimit(2)
                        ProgramLengthLabel(program: program)
                    }
                    Spacer(minLength: 0)
                    Button {
                        startNext(program)
                    } label: {
                        Text("Start")
                            .font(AppFont.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(themeManager.current.primaryColor, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                startNext(enrolled.program)
            } label: {
                Label("Run \(enrolled.program.title) again", systemImage: "arrow.counterclockwise")
                    .font(AppFont.subheadline.weight(.semibold))
                    .foregroundStyle(themeManager.current.primaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(themeManager.current.primaryColor.opacity(0.12), in: RoundedRectangle(cornerRadius: AppCornerRadius.button))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    private var bottomBar: some View {
        HStack(spacing: AppSpacing.smallMedium) {
            Button {
                finish()
            } label: {
                Text("Done")
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.primaryColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.current.primaryColor.opacity(0.12), in: RoundedRectangle(cornerRadius: AppCornerRadius.button))
            }

            ShareCardLink(content: enrolled.shareCard) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(AppFont.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.current.primaryColor, in: RoundedRectangle(cornerRadius: AppCornerRadius.button))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, AppSpacing.small)
        .background(.ultraThinMaterial)
    }

    private func sectionTitle(_ title: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(themeManager.current.primaryColor)
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(themeManager.current.textPrimary)
        }
    }

    // MARK: - Actions

    /// Takes the finished run off Today. It stays on the program's page as a past result.
    private func finish() {
        if !enrolled.enrollment.isArchived {
            withAnimation {
                viewModel.archive(enrolled)
            }
        }
        dismiss()
    }

    private func startNext(_ program: Program) {
        withAnimation {
            viewModel.startNext(program, after: enrolled)
        }
        dismiss()
    }
}

/// The completion screen for a run named only by its id — what a "program complete"
/// notification carries.
struct ProgramCompletionSheet: View {
    let enrollmentID: ProgramEnrollment.ID

    @State private var viewModel = ProgramsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let enrolled = viewModel.enrolled.first(where: { $0.id == enrollmentID && $0.progress.isFinished }) {
            ProgramCompletionView(enrolled: enrolled, viewModel: viewModel)
        } else {
            // Left, or deleted along with a custom program, since the notification was sent.
            NavigationStack {
                ContentUnavailableView(
                    "Program not found",
                    systemImage: "map",
                    description: Text("It may have been left or removed.")
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .appToolbarCircularButtonStyle()
                        }
                    }
                }
            }
        }
    }
}
