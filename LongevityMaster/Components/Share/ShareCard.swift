//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

/// What a share card says. Each screen that offers sharing builds one of these; how a card
/// looks is decided once, in `ShareCardView`, so every card someone posts looks like it came
/// from the same app.
struct ShareCardContent: Hashable {
    enum Badge: Hashable {
        case emoji(String)
        /// Short text drawn as a monogram, such as a rating's "SS".
        case text(String)
    }

    struct Stat: Hashable {
        let value: String
        let label: String
    }

    var eyebrow: String
    var badge: Badge
    var headline: String
    var detail: String?
    var stats: [Stat] = []
    /// One entry per day, oldest first, drawn as a grid of done and not-done squares.
    var recentDays: [Bool]?
    var date: Date = Date()
    /// Sent alongside the image, for the apps that take text as well: what happened, and where
    /// to get the app.
    var message: String

    static var appStoreURL: String {
        "https://apps.apple.com/app/id\(Constants.AppID.longevityMasterID)"
    }
}

// MARK: - Cards

extension ShareCardContent {
    static func achievement(_ achievement: Achievement) -> ShareCardContent {
        ShareCardContent(
            eyebrow: String(localized: "Achievement unlocked"),
            badge: .emoji(achievement.icon),
            headline: achievement.title,
            detail: achievement.description,
            date: achievement.unlockedDate ?? Date(),
            message: String(localized: "I just unlocked “\(achievement.title)” in Longevity Master 🏆") + "\n" + appStoreURL
        )
    }

    static func rating(_ breakdown: LongevityScoreBreakdown) -> ShareCardContent {
        var stats = [
            Stat(value: "\(breakdown.totalScore)", label: String(localized: "of 1200 points"))
        ]
        if let next = breakdown.nextRating {
            stats.append(Stat(value: "\(breakdown.scoreToNextRating)", label: String(localized: "points to \(next.displayName)")))
        }
        return ShareCardContent(
            eyebrow: String(localized: "My longevity rating"),
            badge: .text(breakdown.rating.displayName),
            headline: breakdown.rating.description,
            detail: String(localized: "Scored on habits, anti-aging impact, consistency and streaks."),
            stats: stats,
            message: String(localized: "My longevity rating is \(breakdown.rating.displayName) (\(breakdown.rating.description)) in Longevity Master 💪") + "\n" + appStoreURL
        )
    }

    static func habit(
        _ habit: Habit,
        currentStreak: Int,
        bestStreak: Int,
        totalCheckIns: Int,
        recentDays: [Bool]
    ) -> ShareCardContent {
        let eyebrow = currentStreak > 0
            ? String(localized: "🔥 \(currentStreak)-day streak")
            : String(localized: "Building a habit")
        // A zero is nothing to post; between streaks the card leads with the best one instead.
        var stats: [Stat] = []
        if currentStreak > 0 {
            stats.append(Stat(value: "\(currentStreak)", label: String(localized: "day streak")))
        }
        stats.append(Stat(value: "\(bestStreak)", label: String(localized: "best streak")))
        stats.append(Stat(value: "\(totalCheckIns)", label: String(localized: "check-ins")))
        return ShareCardContent(
            eyebrow: eyebrow,
            badge: .emoji(habit.icon),
            headline: habit.name,
            detail: habit.frequencyDescription,
            stats: stats,
            recentDays: recentDays,
            message: String(localized: "\(currentStreak) days in a row of “\(habit.name)” with Longevity Master 🔥") + "\n" + appStoreURL
        )
    }

    static func program(_ program: Program, progress: ProgramProgress) -> ShareCardContent {
        var stats = [
            Stat(value: "\(progress.dayNumber)/\(progress.durationDays)", label: String(localized: "days")),
            Stat(value: "\(progress.checkInCount)", label: String(localized: "check-ins")),
        ]
        if let percent = progress.adherencePercent {
            stats.insert(Stat(value: "\(percent)%", label: String(localized: "on track")), at: 1)
        }
        let finished = progress.isFinished
        return ShareCardContent(
            eyebrow: finished ? String(localized: "Program completed") : String(localized: "Day \(progress.dayNumber) of \(progress.durationDays)"),
            badge: .emoji(program.icon),
            headline: program.title,
            detail: program.subtitle,
            stats: stats,
            message: (finished
                ? String(localized: "I just finished the \(program.durationDays)-day “\(program.title)” program in Longevity Master 🎉")
                : String(localized: "Day \(progress.dayNumber) of the “\(program.title)” program in Longevity Master 💪"))
                + "\n" + appStoreURL
        )
    }
}

// MARK: - Card

/// The shareable image: a portrait card sized for stories and chats, in the user's theme
/// colour, with the app's name on it so anyone who sees it knows where it came from.
///
/// Drawn in light mode whatever the device is set to — the image outlives the setting it was
/// made in, and is seen on other people's screens.
struct ShareCardView: View {
    let content: ShareCardContent
    let tint: Color

    static let size = CGSize(width: 360, height: 640)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [tint.blend(with: .black, amount: 0.1), tint.blend(with: .black, amount: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 340, height: 340)
                .offset(x: 160, y: -250)
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 260, height: 260)
                .offset(x: -170, y: 190)

            VStack(spacing: 0) {
                Text(content.eyebrow.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 40)

                Spacer(minLength: 12)

                badge

                Text(content.headline)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 20)

                if let detail = content.detail {
                    Text(detail)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .padding(.top, 8)
                }

                if !content.stats.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(content.stats, id: \.self) { stat in
                            VStack(spacing: 2) {
                                Text(stat.value)
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                Text(stat.label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .opacity(0.85)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.top, 22)
                }

                if let recentDays = content.recentDays {
                    recentDaysGrid(recentDays)
                        .padding(.top, 18)
                }

                Spacer(minLength: 12)

                Text(content.date.formatted(date: .long, time: .omitted))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 10)

                footer
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
        .environment(\.colorScheme, .light)
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.18))
            Circle()
                .strokeBorder(.white.opacity(0.4), lineWidth: 2)
            switch content.badge {
            case .emoji(let emoji):
                Text(emoji)
                    .font(.system(size: 66))
            case .text(let text):
                Text(text)
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .padding(16)
            }
        }
        .frame(width: 136, height: 136)
    }

    private func recentDaysGrid(_ days: [Bool]) -> some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(16), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, isDone in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(isDone ? 0.95 : 0.18))
                        .frame(width: 16, height: 16)
                }
            }
            .frame(width: 7 * 16 + 6 * 6)
            Text("Last \(days.count) days")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Image("appIcon360")
                .resizable()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "Longevity Master")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(red: 0.11, green: 0.11, blue: 0.12))
                Text("Build habits for a longer, healthier life")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.43))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Text("Free on the\nApp Store")
                .font(.system(size: 10, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(tint.blend(with: .black, amount: 0.3))
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("Habit") {
    ShareCardView(
        content: .habit(
            HabitsDataStore.squats.toMock,
            currentStreak: 21,
            bestStreak: 34,
            totalCheckIns: 86,
            recentDays: (0..<28).map { $0 % 5 != 0 }
        ),
        tint: ThemeColor.default.primaryColor
    )
}

#Preview("Program") {
    ShareCardView(
        content: .program(
            ProgramsDataStore.antioxidantPlate,
            progress: ProgramProgress(dayNumber: 21, durationDays: 21, isFinished: true, adherence: 0.86, checkInCount: 74)
        ),
        tint: ThemeColor.blue.primaryColor
    )
}
