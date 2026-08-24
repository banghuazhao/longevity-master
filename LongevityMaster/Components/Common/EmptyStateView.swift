//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import Dependencies

struct EmptyStateView: View {
    let icon: String
    // `LocalizedStringKey`, not `String`: `Text` only looks a string up in the catalog when it
    // arrives as a key, so plain-`String` titles shipped as English whatever language was picked.
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let buttonTitle: LocalizedStringKey
    let action: () -> Void
    
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()
            
            VStack(spacing: AppSpacing.medium) {
                Text(icon)
                    .font(.system(size: 64))
                
                VStack(spacing: AppSpacing.small) {
                    Text(title)
                        .font(AppFont.headline)
                        .foregroundColor(themeManager.current.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(AppFont.subheadline)
                        .foregroundColor(themeManager.current.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.large)
                }
            }
            
            Button(action: action) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "plus")
                        .font(AppFont.subheadline)
                    Text(buttonTitle)
                        .font(AppFont.headline)
                }
            }
            .appButtonStyle()
            .padding(.horizontal, AppSpacing.large)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    EmptyStateView(
        icon: "📝",
        title: "No Habits Yet",
        subtitle: "Start building healthy habits by creating your first one. Small steps lead to big changes!",
        buttonTitle: "Add Habit"
    ) {
        print("Add habit tapped")
    }
} 
