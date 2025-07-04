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
    
    private let themeColors: [ThemeColorOption] = [
        ThemeColorOption(name: "Default", color: Color(red: 1.0, green: 0.47, blue: 0.18), icon: "flame.fill"),
        ThemeColorOption(name: "Blue", color: Color(red: 0.0, green: 0.48, blue: 1.0), icon: "drop.fill"),
        ThemeColorOption(name: "Green", color: Color(red: 0.20, green: 0.78, blue: 0.35), icon: "leaf.fill"),
        ThemeColorOption(name: "Purple", color: Color(red: 0.58, green: 0.35, blue: 0.95), icon: "sparkles")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    // Header
                    VStack(spacing: AppSpacing.medium) {
                        Text("Choose Theme Color")
                            .font(AppFont.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.current.textPrimary)
                        
                        Text("Select your preferred primary color for the app")
                            .font(AppFont.body)
                            .foregroundColor(themeManager.current.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppSpacing.large)
                    
                    // Theme Color Options
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.large) {
                        ForEach(themeColors, id: \.name) { themeOption in
                            ThemeColorCard(
                                themeOption: themeOption,
                                isSelected: themeManager.currentThemeColor == themeOption.name,
                                onTap: {
                                    themeManager.updateThemeColor(themeOption.name)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Preview Section
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text("Preview")
                            .appSectionHeader(theme: themeManager.current)
                        
                        VStack(spacing: AppSpacing.medium) {
                            // Sample button
                            Button(action: {}) {
                                Text("Sample Button")
                                    .appButtonStyle(theme: themeManager.current)
                            }
                            
                            // Sample card
                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(themeManager.current.primaryColor)
                                    Text("Sample Card")
                                        .font(AppFont.headline)
                                        .foregroundColor(themeManager.current.textPrimary)
                                    Spacer()
                                }
                                Text("This is how your selected theme color will look throughout the app.")
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
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .appRectButtonStyle()
                    }
                }
            }
        }
    }
}

struct ThemeColorOption {
    let name: String
    let color: Color
    let icon: String
}

struct ThemeColorCard: View {
    @Dependency(\.themeManager) var themeManager
    let themeOption: ThemeColorOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.medium) {
                // Color circle with icon
                ZStack {
                    Circle()
                        .fill(themeOption.color)
                        .frame(width: 80, height: 80)
                        .shadow(color: themeOption.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: themeOption.icon)
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                // Theme name
                Text(themeOption.name)
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
                    .stroke(isSelected ? themeOption.color : Color.clear, lineWidth: 3)
            )
            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ThemeColorView()
} 
