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
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? themeManager.current.primaryColor : themeManager.current.secondaryGray.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : themeManager.current.textPrimary)
        }
        .buttonStyle(PlainButtonStyle())
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
