//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI

/// One program: what it asks of you, week by week, and the studies behind it — and, once
/// started, how it is going.
struct ProgramDetailView: View {
    let viewModel: ProgramsViewModel
    private let programID: String
    /// What was tapped, for the moment a program being deleted is already gone from the
    /// database but the page has not yet been dismissed.
    private let openedProgram: Program

    @State private var isConfirmingLeave = false
    @State private var isConfirmingDelete = false
    @State private var form: CustomProgramFormModel?

    @Environment(\.dismiss) private var dismiss
    @Dependency(\.themeManager) private var themeManager

    init(program: Program, viewModel: ProgramsViewModel) {
        self.viewModel = viewModel
        self.programID = program.id
        self.openedProgram = program
    }

    /// Read afresh each time, so an edit to the user's own program shows straight away.
    private var program: Program {
        viewModel.program(id: programID) ?? openedProgram
    }

    var body: some View {
        let enrolled = viewModel.enrolled
        let active = viewModel.active(program, in: enrolled)
        let finished = viewModel.finished(program, in: enrolled)

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                header

                if let active {
                    progressSection(active)
                } else if let latest = finished.first, !latest.enrollment.isArchived {
                    completedSection(latest)
                }

                if !program.summary.isEmpty {
                    Text(program.summary)
                        .font(AppFont.body)
                        .foregroundStyle(themeManager.current.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                habitsSection
                if program.weeklyFocus.contains(where: { !$0.isEmpty }) {
                    weeksSection(currentWeek: active?.currentWeek)
                }
                if !program.sources.isEmpty {
                    evidenceSection
                }

                if !finished.isEmpty {
                    pastResultsSection(finished)
                }

                Text("General wellness information, not medical advice. Check with your doctor before starting a new exercise or diet program, especially if you have a health condition.")
                    .font(AppFont.footnote)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppSpacing.small)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            if active == nil {
                startButton(isRestart: !finished.isEmpty)
            }
        }
        .appBackground()
        .navigationTitle(program.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if active != nil || program.isCustom {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if program.isCustom {
                            Button {
                                if let row = viewModel.customRow(for: program) {
                                    form = CustomProgramFormModel(program: row)
                                }
                            } label: {
                                Label("Edit Program", systemImage: "pencil")
                            }
                        }
                        if active != nil {
                            Button(role: .destructive) {
                                isConfirmingLeave = true
                            } label: {
                                Label("Leave Program", systemImage: "xmark.circle")
                            }
                        }
                        if program.isCustom {
                            Button(role: .destructive) {
                                isConfirmingDelete = true
                            } label: {
                                Label("Delete Program", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .appToolbarCircularButtonStyle()
                    }
                }
            }
        }
        .confirmationDialog(
            "Leave “\(program.title)”?",
            isPresented: $isConfirmingLeave,
            titleVisibility: .visible
        ) {
            Button("Leave Program", role: .destructive) {
                if let active {
                    viewModel.leave(active)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your habits and their check-ins stay. Only the program's progress is removed.")
        }
        .confirmationDialog(
            "Delete “\(program.title)”?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Program", role: .destructive) {
                viewModel.delete(program)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your habits and their check-ins stay. The program and its progress are removed.")
        }
        .sheet(item: $form) { model in
            CustomProgramFormView(model: model)
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: AppSpacing.medium) {
            ProgramIcon(program: program, size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(program.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(themeManager.current.textPrimary)
                Text(program.subtitle)
                    .font(AppFont.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
                ProgramLengthLabel(program: program)
            }
            Spacer(minLength: 0)
        }
    }

    private func progressSection(_ active: ProgramsViewModel.Enrolled) -> some View {
        VStack(spacing: AppSpacing.smallMedium) {
            ProgramProgressCard(enrolled: active, showsProgram: false)

            ShareCardLink(content: active.shareCard) {
                Label("Share Progress", systemImage: "square.and.arrow.up")
                    .font(AppFont.subheadline.weight(.semibold))
                    .foregroundStyle(themeManager.current.primaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.smallMedium)
                    .background(themeManager.current.primaryColor.opacity(0.12), in: RoundedRectangle(cornerRadius: AppCornerRadius.button))
            }
        }
    }

    private func completedSection(_ latest: ProgramsViewModel.Enrolled) -> some View {
        VStack(spacing: AppSpacing.smallMedium) {
            Text("🎉 Program completed")
                .font(AppFont.headline)
            if let percent = latest.progress.adherencePercent {
                Text("You kept \(percent)% of the plan over \(latest.progress.durationDays) days.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .multilineTextAlignment(.center)
            }
            ShareCardLink(content: latest.shareCard) {
                Label("Share Result", systemImage: "square.and.arrow.up")
                    .appButtonStyle()
            }
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(theme: themeManager.current)
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle("What you'll do", systemImage: "checklist")

            ForEach(program.habits, id: \.name) { habit in
                HStack(alignment: .top, spacing: AppSpacing.smallMedium) {
                    Text(habit.icon)
                        .font(.system(size: 26))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: habit.color), in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(habit.name)
                                .font(AppFont.subheadline.weight(.semibold))
                                .foregroundStyle(themeManager.current.textPrimary)
                            Spacer(minLength: 0)
                            Text(String(repeating: "★", count: habit.antiAgingRating) + String(repeating: "☆", count: max(5 - habit.antiAgingRating, 0)))
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .accessibilityLabel(Text("Anti-aging rating \(habit.antiAgingRating) of 5"))
                        }
                        Text(habit.frequencyDescription)
                            .font(AppFont.footnote.weight(.medium))
                            .foregroundStyle(themeManager.current.primaryColor)
                        Text(habit.note)
                            .font(AppFont.footnote)
                            .foregroundStyle(themeManager.current.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    private func weeksSection(currentWeek: Int?) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle("Week by week", systemImage: "calendar")

            ForEach(Array(program.weeklyFocus.enumerated()).filter { !$0.element.isEmpty }, id: \.offset) { index, focus in
                let week = index + 1
                let isCurrent = week == currentWeek
                HStack(alignment: .top, spacing: AppSpacing.smallMedium) {
                    Text(verbatim: "\(week)")
                        .font(AppFont.subheadline.weight(.bold))
                        .foregroundStyle(isCurrent ? .white : themeManager.current.primaryColor)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle().fill(isCurrent ? themeManager.current.primaryColor : themeManager.current.primaryColor.opacity(0.12))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Week \(week)")
                            .font(AppFont.footnote.weight(.semibold))
                            .foregroundStyle(themeManager.current.textSecondary)
                        Text(focus)
                            .font(AppFont.subheadline)
                            .foregroundStyle(themeManager.current.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle("The evidence", systemImage: "book.closed")

            ForEach(program.sources, id: \.self) { source in
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.finding)
                        .font(AppFont.subheadline)
                        .foregroundStyle(themeManager.current.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let url = source.url {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Text(verbatim: source.citation)
                                Image(systemName: "arrow.up.right.square")
                            }
                            .font(AppFont.footnote)
                            .foregroundStyle(themeManager.current.primaryColor)
                        }
                    } else {
                        Text(verbatim: source.citation)
                            .font(AppFont.footnote)
                            .foregroundStyle(themeManager.current.textSecondary)
                    }
                }
                if source != program.sources.last {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    private func pastResultsSection(_ finished: [ProgramsViewModel.Enrolled]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            sectionTitle("Past results", systemImage: "trophy")

            ForEach(finished) { run in
                HStack {
                    Text(run.enrollment.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(AppFont.subheadline)
                        .foregroundStyle(themeManager.current.textPrimary)
                    Spacer()
                    if let percent = run.progress.adherencePercent {
                        Text("\(percent)% on track")
                            .font(AppFont.subheadline.weight(.semibold))
                            .foregroundStyle(themeManager.current.primaryColor)
                    }
                    ShareCardLink(content: run.shareCard) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundStyle(themeManager.current.primaryColor)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme: themeManager.current)
    }

    private func startButton(isRestart: Bool) -> some View {
        Button {
            viewModel.start(program)
        } label: {
            Text(isRestart ? "Start Again" : "Start Program")
                .font(AppFont.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.current.primaryColor, in: RoundedRectangle(cornerRadius: AppCornerRadius.button))
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
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    NavigationStack {
        ProgramDetailView(program: ProgramsDataStore.strengthFoundations, viewModel: ProgramsViewModel())
    }
}
