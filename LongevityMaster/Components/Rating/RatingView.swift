//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SQLiteData

struct RatingView: View {
    @State private var viewModel = RatingViewModel()
    @Dependency(\.themeManager) private var themeManager

    private var theme: AppTheme { themeManager.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    if let breakdown = viewModel.scoreBreakdown {
                        ratingCard(breakdown)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }

                    scoreBreakdownSection
                }
                .padding(.horizontal)
                .padding(.top, AppSpacing.small)
                .padding(.bottom, AppSpacing.large)
            }
            .appBackground()
            .navigationTitle(String(localized: "Longevity Rating"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.onTapRatingCard()
                    } label: {
                        Image(systemName: "info")
                            .appToolbarCircularButtonStyle()
                    }
                    .accessibilityLabel(Text("Longevity Rating System"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let breakdown = viewModel.scoreBreakdown {
                        ShareCardLink(content: .rating(breakdown)) {
                            Image(systemName: "square.and.arrow.up")
                                .appToolbarCircularButtonStyle()
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadRatingData()
            }
            .task {
                await viewModel.loadRatingData()
            }
            .sheet(item: $viewModel.route.scoreBreakdownDetail, id: \.self) { scoreDetailViewModel in
                ScoreDetailView(viewModel: scoreDetailViewModel)
            }
            .sheet(
                isPresented: Binding($viewModel.route.ratingSystemExplanation)
            ) {
                RatingSystemExplanationView()
            }
        }
    }

    // MARK: - Rating

    private func ratingCard(_ breakdown: LongevityScoreBreakdown) -> some View {
        let rating = breakdown.rating

        return VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.large) {
                RatingGauge(
                    rating: rating,
                    fraction: Double(breakdown.totalScore) / 1200
                )

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(rating.description)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(String(localized: "\(breakdown.totalScore) points"))
                        .font(AppFont.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(rating.color)
                    Text(String(localized: "\(breakdown.totalScore)/1200"))
                        .font(AppFont.footnote)
                        .monospacedDigit()
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer(minLength: 0)
            }

            if let nextRating = breakdown.nextRating {
                nextRatingProgress(breakdown, nextRating: nextRating)
            }
        }
        .appCardStyle(theme: theme)
        .contentShape(.rect)
        .onTapGesture {
            viewModel.onTapRatingCard()
        }
    }

    private func nextRatingProgress(_ breakdown: LongevityScoreBreakdown, nextRating: LongevityRating) -> some View {
        // Every level below the top one is 100 points wide.
        let levelProgress = Double(100 - min(100, breakdown.scoreToNextRating)) / 100

        return VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Label {
                    Text(String(localized: "Progress to \(nextRating.displayName)"))
                } icon: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(nextRating.color)
                }
                .font(AppFont.subheadline.weight(.semibold))
                .foregroundStyle(theme.textPrimary)

                Spacer(minLength: AppSpacing.small)

                Text(String(localized: "\(breakdown.scoreToNextRating) points needed"))
                    .font(AppFont.footnote)
                    .monospacedDigit()
                    .foregroundStyle(theme.textSecondary)
            }

            AppProgressBar(value: levelProgress, color: nextRating.color, height: 8)
        }
        .padding(AppSpacing.smallMedium)
        .background(
            theme.secondaryGray.opacity(0.08),
            in: RoundedRectangle(cornerRadius: AppCornerRadius.info, style: .continuous)
        )
    }

    // MARK: - Breakdown

    private var scoreBreakdownSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            AppSectionHeader("Score Breakdown")

            if let breakdownItems = viewModel.scoreBreakdownItems {
                AppGroupedCard {
                    ForEach(Array(breakdownItems.enumerated()), id: \.offset) { index, item in
                        if index > 0 {
                            AppRowDivider()
                        }
                        ScoreBreakdownRow(item: item)
                            .onTapGesture {
                                viewModel.onTapScoreBreakdownItem(item)
                            }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    struct ScoreBreakdownRow: View {
        let item: ScoreBreakdownItem

        @State var isInfoPresented: Bool = false
        @Dependency(\.themeManager) private var themeManager

        var body: some View {
            let theme = themeManager.current

            HStack(spacing: AppSpacing.smallMedium) {
                IconBadge(systemName: item.icon, color: item.color)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: AppSpacing.xSmall) {
                        Text(item.title)
                            .font(AppFont.subheadline.weight(.semibold))
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(1)

                        Button {
                            isInfoPresented.toggle()
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.footnote)
                                .foregroundStyle(theme.textSecondary)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(Text(String(localized: "How \(item.title) Score is Calculated")))
                        .popover(isPresented: $isInfoPresented) {
                            ScrollView {
                                VStack(spacing: 16) {
                                    Text(String(localized: "How \(item.title) Score is Calculated"))
                                        .font(.headline)
                                        .multilineTextAlignment(.center)

                                    Text(item.explanation)
                                        .font(.body)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(minHeight: 150)
                            }
                            .padding()
                            .presentationCompactAdaptation(.popover)
                        }

                        Spacer(minLength: AppSpacing.small)

                        Text(String(localized: "\(item.score)/\(item.maxScore)"))
                            .font(AppFont.footnote.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(theme.textSecondary)
                    }

                    AppProgressBar(value: item.percentage, color: item.color)
                }

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(theme.textSecondary.opacity(0.7))
                    .accessibilityHidden(true)
            }
            .appRowPadding()
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
        }
    }
}

/// The rating's letter inside a ring filled by how far the score has come out of 1,200.
private struct RatingGauge: View {
    let rating: LongevityRating
    let fraction: Double

    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 108

    var body: some View {
        let clamped = min(max(fraction, 0), 1)

        ZStack {
            Circle()
                .stroke(rating.color.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(
                        colors: [rating.color.opacity(0.55), rating.color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * max(clamped, 0.01))
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(rating.displayName)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(rating.color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(18)
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: clamped)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: rating.displayName))
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    RatingView()
}

