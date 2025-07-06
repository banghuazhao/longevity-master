//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct RatingSystemExplanationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Rating Levels
                    ratingLevelsSection
                    
                    // Score Categories
                    scoreCategoriesSection
                    
                    // Tips Section
                    tipsSection
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(String(localized: "Rating System"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "Done"))
                            .appRectButtonStyle()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(String(localized: "Longevity Rating System"))
                .font(.title)
                .fontWeight(.bold)
            
            Text(String(localized: "Your rating is calculated based on your overall health and wellness habits across multiple dimensions. Focus on building consistent habits across all categories to improve your rating!"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .appCardStyle()
    }
    
    private var ratingLevelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Rating Levels"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(LongevityRating.allCases, id: \.self) { rating in
                    RatingLevelRow(rating: rating)
                }
            }
        }
    }
    
    private var scoreCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Score Categories"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(ScoreCategory.allCases, id: \.self) { category in
                    ScoreCategoryRow(category: category)
                }
            }
        }
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Tips for Improvement"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TipRow(
                    icon: "target",
                    title: String(localized: "Set Realistic Goals"),
                    description: String(localized: "Start with small, achievable habits and gradually increase complexity")
                )
                
                TipRow(
                    icon: "calendar",
                    title: String(localized: "Build Consistency"),
                    description: String(localized: "Focus on daily check-ins rather than perfect performance")
                )
                
                TipRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: String(localized: "Track Progress"),
                    description: String(localized: "Monitor your streaks and celebrate small victories")
                )
                
                TipRow(
                    icon: "star.fill",
                    title: String(localized: "Prioritize High-Impact Habits"),
                    description: String(localized: "Focus on habits with higher anti-aging ratings for better scores")
                )
                
                TipRow(
                    icon: "trophy.fill",
                    title: String(localized: "Unlock Achievements"),
                    description: String(localized: "Complete various challenges to earn achievement points")
                )
            }
        }
    }
}

struct RatingLevelRow: View {
    let rating: LongevityRating
    
    var body: some View {
        HStack(spacing: 16) {
            // Rating Badge
            VStack(spacing: 4) {
                Text(rating.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(rating.color)
                
                Text(rating.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            
            // Score Range
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Score Range"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(scoreRangeText)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Color Indicator
            Circle()
                .fill(rating.color)
                .frame(width: 12, height: 12)
        }
        .appInfoSection()
    }
    
    private var scoreRangeText: String {
        switch rating {
        case .f: return String(localized: "0-99 points")
        case .dMinus: return String(localized: "100-199 points")
        case .d: return String(localized: "200-299 points")
        case .cMinus: return String(localized: "300-399 points")
        case .c: return String(localized: "400-499 points")
        case .bMinus: return String(localized: "500-599 points")
        case .b: return String(localized: "600-699 points")
        case .aMinus: return String(localized: "700-799 points")
        case .a: return String(localized: "800-899 points")
        case .s: return String(localized: "900-999 points")
        case .ss: return String(localized: "1000-1099 points")
        case .sss: return String(localized: "1100+ points")
        }
    }
}

struct ScoreCategoryRow: View {
    let category: ScoreCategory
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: category.icon)
                .font(.system(size: 24))
                .foregroundColor(category.color)
                .frame(width: 40)
            
            // Category Info
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(category.calculationExplanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Max Score
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(localized: "Max"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(category.maxScore)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(category.color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .appInfoSection()
    }
}

#Preview {
    RatingSystemExplanationView()
} 
