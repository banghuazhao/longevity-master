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
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(themeManager.current.primaryColor)
                    .font(.title2)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.current.textSecondary)
                        .font(.title3)
                }
            }
            
            Text(quote.text)
                .font(AppFont.body)
                .foregroundColor(themeManager.current.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Spacer()
                Text("— \(quote.author)")
                    .font(AppFont.caption)
                    .foregroundColor(themeManager.current.textSecondary)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(themeManager.current.primaryColor.opacity(0.1))
        )
        .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
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
