//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import Dependencies

struct CategoryFilterButton: View {
    @Dependency(\.themeManager) var themeManager
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        let theme = themeManager.current

        Button(action: action) {
            Text(title)
                .font(AppFont.subheadline.weight(isSelected ? .semibold : .medium))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    if isSelected {
                        Capsule().fill(theme.primaryColor)
                    } else {
                        Capsule()
                            .fill(theme.card)
                            .overlay(Capsule().strokeBorder(theme.separator, lineWidth: 1))
                    }
                }
                .foregroundStyle(isSelected ? Color.white : theme.textPrimary)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.snappy(duration: 0.2), value: isSelected)
    }
}

#Preview {
    VStack(spacing: 20) {
        CategoryFilterButton(
            title: "All",
            isSelected: true,
            action: {}
        )
        
        CategoryFilterButton(
            title: "Diet",
            isSelected: false,
            action: {}
        )
        
        CategoryFilterButton(
            title: "Exercise",
            isSelected: false,
            action: {}
        )
    }
    .padding()
} 
