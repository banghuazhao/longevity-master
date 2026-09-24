//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI

/// The Programs tab: programs under way, the user's own, and the guided ones.
struct ProgramsView: View {
    @State var viewModel = ProgramsViewModel()
    @State private var form: CustomProgramFormModel?
    @State private var programToDelete: Program?

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        let enrolled = viewModel.enrolled
        let current = enrolled.filter { !$0.enrollment.isArchived && !$0.progress.isFinished }
        let custom = viewModel.customPrograms

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("A program bundles a few habits for a set number of weeks, with a goal for each week. Follow a guided one backed by research, or make your own.")
                        .font(AppFont.subheadline)
                        .foregroundStyle(themeManager.current.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !current.isEmpty {
                        sectionHeader("In progress")

                        ForEach(current) { enrolled in
                            NavigationLink {
                                ProgramDetailView(program: enrolled.program, viewModel: viewModel)
                            } label: {
                                ProgramProgressCard(enrolled: enrolled)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    sectionHeader("My programs")

                    if custom.isEmpty {
                        createCard
                    } else {
                        ForEach(custom) { program in
                            programLink(program, isActive: viewModel.active(program, in: enrolled) != nil)
                                .contextMenu {
                                    Button {
                                        edit(program)
                                    } label: {
                                        Label("Edit Program", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        programToDelete = program
                                    } label: {
                                        Label("Delete Program", systemImage: "trash")
                                    }
                                }
                        }
                    }

                    sectionHeader("Guided programs")

                    ForEach(ProgramsDataStore.all) { program in
                        programLink(program, isActive: viewModel.active(program, in: enrolled) != nil)
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Programs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        form = CustomProgramFormModel()
                    } label: {
                        Image(systemName: "plus")
                            .appToolbarCircularButtonStyle()
                    }
                    .accessibilityLabel(Text("New Program"))
                }
            }
            .sheet(item: $form) { model in
                CustomProgramFormView(model: model)
            }
            .confirmationDialog(
                programToDelete.map { "Delete “\($0.title)”?" } ?? "",
                isPresented: Binding(
                    get: { programToDelete != nil },
                    set: { if !$0 { programToDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: programToDelete
            ) { program in
                Button("Delete Program", role: .destructive) {
                    viewModel.delete(program)
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("Your habits and their check-ins stay. The program and its progress are removed.")
            }
        }
    }

    private func programLink(_ program: Program, isActive: Bool) -> some View {
        NavigationLink {
            ProgramDetailView(program: program, viewModel: viewModel)
        } label: {
            ProgramCard(program: program, isActive: isActive)
        }
        .buttonStyle(.plain)
    }

    private func edit(_ program: Program) {
        guard let row = viewModel.customRow(for: program) else { return }
        form = CustomProgramFormModel(program: row)
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(AppFont.headline)
            .padding(.top, AppSpacing.small)
    }

    private var createCard: some View {
        Button {
            form = CustomProgramFormModel()
        } label: {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(themeManager.current.primaryColor)
                    .frame(width: 56, height: 56)
                    .background(themeManager.current.primaryColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create your own")
                        .font(AppFont.headline)
                        .foregroundStyle(themeManager.current.textPrimary)
                    Text("Pick habits, set a length and weekly goals, and track it like any program.")
                        .font(AppFont.footnote)
                        .foregroundStyle(themeManager.current.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(AppSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .strokeBorder(themeManager.current.primaryColor.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
        }
        .buttonStyle(.plain)
    }
}

/// A program in the list: what it is and how long it takes.
struct ProgramCard: View {
    let program: Program
    var isActive: Bool = false

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            ProgramIcon(program: program, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(program.title)
                        .font(AppFont.headline)
                        .foregroundStyle(themeManager.current.textPrimary)
                    if isActive {
                        Text("Active")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(themeManager.current.primaryColor, in: Capsule())
                    }
                }
                Text(program.subtitle)
                    .font(AppFont.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .lineLimit(2)
                ProgramLengthLabel(program: program)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(themeManager.current.textSecondary)
        }
        .appCardStyle(theme: themeManager.current)
    }
}

/// "4 weeks · 5 habits"
struct ProgramLengthLabel: View {
    let program: Program

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
            Text("\(program.durationDays) days")
            Text(verbatim: "·")
            Image(systemName: "checklist")
            Text("\(program.habits.count) habits")
        }
        .font(AppFont.footnote)
        .foregroundStyle(themeManager.current.textSecondary)
    }
}

struct ProgramIcon: View {
    let program: Program
    let size: CGFloat

    var body: some View {
        Text(program.icon)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(Color(hex: program.color), in: RoundedRectangle(cornerRadius: size * 0.28))
    }
}

/// A program under way: which day it is, and whether the user is keeping up.
struct ProgramProgressCard: View {
    let enrolled: ProgramsViewModel.Enrolled
    /// Off on the program's own page, whose header already names it.
    var showsProgram: Bool = true

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        let progress = enrolled.progress

        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
            HStack(spacing: AppSpacing.smallMedium) {
                if showsProgram {
                    ProgramIcon(program: enrolled.program, size: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(enrolled.program.title)
                            .font(AppFont.headline)
                            .foregroundStyle(themeManager.current.textPrimary)
                        Text("Day \(progress.dayNumber) of \(progress.durationDays)")
                            .font(AppFont.subheadline)
                            .foregroundStyle(themeManager.current.textSecondary)
                    }
                } else {
                    Text("Day \(progress.dayNumber) of \(progress.durationDays)")
                        .font(AppFont.headline)
                        .foregroundStyle(themeManager.current.textPrimary)
                }

                Spacer(minLength: 0)

                if let percent = progress.adherencePercent {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(verbatim: "\(percent)%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(themeManager.current.primaryColor)
                        Text("on track")
                            .font(AppFont.footnote)
                            .foregroundStyle(themeManager.current.textSecondary)
                    }
                }
            }

            ProgressView(value: progress.fractionElapsed)
                .tint(themeManager.current.primaryColor)

            if let focus = enrolled.program.weeklyFocus[safe: enrolled.currentWeek - 1], !focus.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Text("Week \(enrolled.currentWeek)")
                        .font(AppFont.footnote.weight(.semibold))
                        .foregroundStyle(themeManager.current.primaryColor)
                    Text(focus)
                        .font(AppFont.footnote)
                        .foregroundStyle(themeManager.current.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .appCardStyle(theme: themeManager.current)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    ProgramsView()
}
