//
//  ThemeColorView.swift
//  LongevityMaster
//
//  Created by Banghua Zhao on 2025/1/1.
//

import SwiftUI
import Dependencies

struct ThemeColorView: View {
    @Dependency(\.themeManager) var themeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    // Header
                    VStack(spacing: AppSpacing.medium) {
                        Text(String(localized: "Choose Theme Color"))
                            .font(AppFont.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.current.textPrimary)
                        
                        Text(String(localized: "Select your preferred primary color for the app"))
                            .font(AppFont.body)
                            .foregroundColor(themeManager.current.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppSpacing.large)
                    
                    // Theme Color Options
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.large) {
                        ForEach(ThemeColor.allCases, id: \.rawValue) { themeColor in
                            ThemeColorCard(
                                themeColor: themeColor,
                                isSelected: themeManager.currentThemeColor == themeColor.rawValue,
                                onTap: {
                                    themeManager.updateThemeColor(themeColor.rawValue)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Preview Section
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text(String(localized: "Preview"))
                            .appSectionHeader(theme: themeManager.current)
                        
                        VStack(spacing: AppSpacing.medium) {
                            // Sample button
                            Button(action: {}) {
                                Text(String(localized: "Sample Button"))
                                    .appButtonStyle(theme: themeManager.current)
                            }
                            
                            // Sample card
                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(themeManager.current.primaryColor)
                                    Text(String(localized: "Sample Card"))
                                        .font(AppFont.headline)
                                        .foregroundColor(themeManager.current.textPrimary)
                                    Spacer()
                                }
                                Text(String(localized: "This is how your selected theme color will look throughout the app."))
                                    .font(AppFont.body)
                                    .foregroundColor(themeManager.current.textSecondary)
                            }
                            .appCardStyle(theme: themeManager.current)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(themeManager.current.background.ignoresSafeArea())
            .navigationTitle("Theme Color")
            .navigationBarTitleDisplayMode(.inline)
//            .navigationBarBackButtonHidden()
        }
    }
}

struct ThemeColorCard: View {
    @Dependency(\.themeManager) var themeManager
    let themeColor: ThemeColor
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.medium) {
                // Color circle with icon
                ZStack {
                    Circle()
                        .fill(themeColor.primaryColor)
                        .frame(width: 50, height: 50)
                        .shadow(color: themeColor.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: themeColor.icon)
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                // Theme name
                Text(themeColor.title)
                    .font(AppFont.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.current.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.large)
            .background(themeManager.current.card)
            .cornerRadius(AppCornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(isSelected ? themeColor.primaryColor : Color.clear, lineWidth: 3)
            )
            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ThemeColorView()
} 
