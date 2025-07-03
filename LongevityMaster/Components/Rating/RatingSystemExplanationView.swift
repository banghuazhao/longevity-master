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
            .navigationTitle("Rating System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Longevity Rating System")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your rating is calculated based on your overall health and wellness habits across multiple dimensions. Focus on building consistent habits across all categories to improve your rating!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .appCardStyle()
    }
    
    private var ratingLevelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rating Levels")
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
            Text("Score Categories")
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
            Text("Tips for Improvement")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TipRow(
                    icon: "target",
                    title: "Set Realistic Goals",
                    description: "Start with small, achievable habits and gradually increase complexity"
                )
                
                TipRow(
                    icon: "calendar",
                    title: "Build Consistency",
                    description: "Focus on daily check-ins rather than perfect performance"
                )
                
                TipRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress",
                    description: "Monitor your streaks and celebrate small victories"
                )
                
                TipRow(
                    icon: "star.fill",
                    title: "Prioritize High-Impact Habits",
                    description: "Focus on habits with higher anti-aging ratings for better scores"
                )
                
                TipRow(
                    icon: "trophy.fill",
                    title: "Unlock Achievements",
                    description: "Complete various challenges to earn achievement points"
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
                Text("Score Range")
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
        case .f: return "0-99 points"
        case .dMinus: return "100-199 points"
        case .d: return "200-299 points"
        case .cMinus: return "300-399 points"
        case .c: return "400-499 points"
        case .bMinus: return "500-599 points"
        case .b: return "600-699 points"
        case .aMinus: return "700-799 points"
        case .a: return "800-899 points"
        case .s: return "900-999 points"
        case .ss: return "1000-1099 points"
        case .sss: return "1100+ points"
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
                Text("Max")
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
