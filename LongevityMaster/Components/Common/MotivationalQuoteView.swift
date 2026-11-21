//
//  MotivationalQuoteView.swift
//  LongevityMaster
//
//  Created by Banghua Zhao on 2025/1/27.
//  Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import Dependencies

struct MotivationalQuoteView: View {
    let quote: MotivationalQuote
    let onDismiss: () -> Void
    
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        let theme = themeManager.current
        let shape = RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous)

        HStack(alignment: .top, spacing: AppSpacing.smallMedium) {
            Image(systemName: "quote.opening")
                .font(.title3.weight(.heavy))
                .foregroundStyle(theme.primaryColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(quote.text)
                    .font(AppFont.subheadline.weight(.medium))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("— \(quote.author)")
                    .font(AppFont.footnote)
                    .italic()
                    .foregroundStyle(theme.textSecondary)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(theme.textSecondary.opacity(0.12)))
                    .frame(width: 32, height: 32)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.top, -4)
            .padding(.trailing, -6)
            .accessibilityLabel(Text("Dismiss"))
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [theme.primaryColor.opacity(0.13), theme.accent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: shape
        )
        .overlay(shape.strokeBorder(theme.primaryColor.opacity(0.12), lineWidth: 1))
    }
}

#Preview {
    MotivationalQuoteView(
        quote: MotivationalQuote(
            text: "The greatest wealth is health.",
            author: "Ralph Waldo Emerson"
        )
    ) {
        print("Dismissed")
    }
} 
