//
// Created by Banghua Zhao on 21/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

// The building blocks the list-like screens share — Me, Settings, Programs, Rating — so that a
// section, a row and a card look and behave the same wherever they appear.

// MARK: - Section header

/// The small label above a group of cards or rows, with room for an action at the far end.
struct AppSectionHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    let trailing: Trailing

    @Dependency(\.themeManager) private var themeManager

    init(_ title: LocalizedStringKey, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppFont.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(themeManager.current.textSecondary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: AppSpacing.small)
            trailing
                .font(AppFont.caption.weight(.semibold))
                .foregroundStyle(themeManager.current.primaryColor)
        }
        .padding(.horizontal, AppSpacing.xSmall)
    }
}

extension AppSectionHeader where Trailing == EmptyView {
    init(_ title: LocalizedStringKey) {
        self.init(title) { EmptyView() }
    }
}

// MARK: - Icon badge

/// A symbol on a small rounded square of colour, the way Settings marks its rows.
struct IconBadge: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 30

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.82), color],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Grouped card

/// Rows stacked in a single card, split by inset hairlines: more to a screen than a card for
/// every item, and easier to scan.
struct AppGroupedCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        // So a pressed row's highlight follows the card's corners.
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous))
        .appCardBackground()
    }
}

/// The rule between two rows of a grouped card. It starts where the row's text does, past
/// the badge, the way Settings draws it.
struct AppRowDivider: View {
    var leadingInset: CGFloat = AppSpacing.medium + 30 + AppSpacing.smallMedium

    @Dependency(\.themeManager) private var themeManager
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(themeManager.current.separator)
            .frame(height: 1 / displayScale)
            .padding(.leading, leadingInset)
            .accessibilityHidden(true)
    }
}

// MARK: - Rows

/// A row's badge and words, without padding or a trailing accessory — on its own it is the
/// label of a `Toggle`, inside `AppRow` the start of every other row.
struct AppRowLabel: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    let systemImage: String
    let color: Color

    @Dependency(\.themeManager) private var themeManager

    init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        systemImage: String,
        color: Color
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        HStack(spacing: AppSpacing.smallMedium) {
            IconBadge(systemName: systemImage, color: color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(themeManager.current.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.footnote)
                        .foregroundStyle(themeManager.current.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// One line of a grouped card: badge, title and an optional subtitle, and whatever belongs at
/// the trailing edge — a chevron, a value, a picker.
struct AppRow<Accessory: View>: View {
    let label: AppRowLabel
    let accessory: Accessory

    init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        systemImage: String,
        color: Color,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.label = AppRowLabel(title, subtitle: subtitle, systemImage: systemImage, color: color)
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            label
            Spacer(minLength: AppSpacing.small)
            accessory
        }
        .appRowPadding()
    }
}

extension AppRow where Accessory == AppRowChevron {
    /// A row that leads somewhere, with an optional value ahead of the chevron.
    init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        systemImage: String,
        color: Color,
        value: String? = nil
    ) {
        self.init(title, subtitle: subtitle, systemImage: systemImage, color: color) {
            AppRowChevron(value: value)
        }
    }
}

/// The end of a row that opens something: an optional value, then a chevron.
struct AppRowChevron: View {
    var value: String?
    /// An arrow out of the app, for a row that opens a website or the App Store.
    var isExternal = false

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: 6) {
            if let value {
                Text(verbatim: value)
                    .font(AppFont.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(themeManager.current.textSecondary)
            }
            Image(systemName: isExternal ? "arrow.up.right" : "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(themeManager.current.textSecondary.opacity(0.7))
                .accessibilityHidden(true)
        }
    }
}

extension View {
    /// The padding every grouped-card row shares, so rows of different kinds line up.
    func appRowPadding() -> some View {
        self
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, 10)
            .frame(minHeight: 52)
            .contentShape(.rect)
    }
}

/// Lights a row up under the finger, as a list row would, instead of fading its text.
struct AppRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.primary.opacity(configuration.isPressed ? 0.07 : 0))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Progress bar

/// A rounded bar, thinner and softer than `ProgressView` stretched with `scaleEffect`.
struct AppProgressBar: View {
    let value: Double
    let color: Color
    var height: CGFloat = 6

    var body: some View {
        let fraction = min(max(value, 0), 1)
        Capsule()
            .fill(color.opacity(0.15))
            .frame(height: height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(color)
                        .frame(width: max(fraction > 0 ? height : 0, proxy.size.width * fraction))
                }
            }
            .clipShape(Capsule())
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: fraction)
            .accessibilityElement()
            .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

// MARK: - Stat

/// A number with a caption under it, for rows of figures.
struct AppStatView: View {
    let value: String
    let title: LocalizedStringKey
    var valueColor: Color?

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        VStack(spacing: 2) {
            Text(verbatim: value)
                .font(.title3.weight(.bold))
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(valueColor ?? themeManager.current.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
            Text(title)
                .font(AppFont.footnote)
                .foregroundStyle(themeManager.current.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// A thin upright rule between two figures in a row.
struct AppStatDivider: View {
    @Dependency(\.themeManager) private var themeManager
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(themeManager.current.separator)
            .frame(width: 1 / displayScale, height: 28)
            .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            AppSectionHeader("Progress")
            AppGroupedCard {
                AppRow("My Stats", systemImage: "chart.bar.fill", color: .blue)
                AppRowDivider()
                AppRow("Achievements", systemImage: "trophy.fill", color: .orange, value: "3/40")
                AppRowDivider()
                AppRow("Weekly Review", subtitle: "A look back at your week, at 7pm on its last day", systemImage: "calendar", color: .green) {
                    Toggle("", isOn: .constant(true)).labelsHidden()
                }
            }
        }
        .padding()
    }
    .background(ThemeManager.shared.current.background)
}
