//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI

/// Every program, with the ones the user is following at the top.
struct ProgramsView: View {
    @State var viewModel = ProgramsViewModel()

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        let enrolled = viewModel.enrolled
        let current = enrolled.filter { !$0.enrollment.isArchived && !$0.progress.isFinished }

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Guided plans that bundle a few proven habits for three or four weeks, with a focus for each week and the research behind them.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !current.isEmpty {
                    Text("In progress")
                        .font(AppFont.headline)
                        .padding(.top, AppSpacing.small)

                    ForEach(current) { enrolled in
                        NavigationLink {
                            ProgramDetailView(program: enrolled.program, viewModel: viewModel)
                        } label: {
                            ProgramProgressCard(enrolled: enrolled)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("All programs")
                    .font(AppFont.headline)
                    .padding(.top, AppSpacing.small)

                ForEach(ProgramsDataStore.all) { program in
                    NavigationLink {
                        ProgramDetailView(program: program, viewModel: viewModel)
                    } label: {
                        ProgramCard(
                            program: program,
                            isActive: viewModel.active(program, in: enrolled) != nil
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Programs")
        .navigationBarTitleDisplayMode(.inline)
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

            if let focus = enrolled.program.weeklyFocus[safe: enrolled.currentWeek - 1] {
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
    NavigationStack {
        ProgramsView()
    }
}
