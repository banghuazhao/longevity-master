//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SharingGRDB

struct RatingView: View {
    @State private var viewModel = RatingViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Rating Card
                    ratingCard
                    
                    // Score Breakdown
                    scoreBreakdownSection
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Longevity Rating")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadRatingData()
            }
            .task {
                await viewModel.loadRatingData()
            }
            .sheet(item: $viewModel.route.scoreBreakdownDetail, id: \.self) { scoreDetailViewModel in
                ScoreDetailView(viewModel: scoreDetailViewModel)
            }
            .sheet(
                isPresented: Binding($viewModel.route.ratingSystemExplanation)
            ) {
                RatingSystemExplanationView()
            }
        }
    }
    
    private var ratingCard: some View {
        VStack(spacing: 16) {
            if let breakdown = viewModel.scoreBreakdown {
                // Rating Display
                VStack(spacing: 8) {
                    Text(breakdown.rating.displayName)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(breakdown.rating.color)
                    
                    Text(breakdown.rating.description)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("\(breakdown.totalScore) points")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                // Score Progress Bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Total Score")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(breakdown.totalScore)/1200")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: Double(breakdown.totalScore), total: 1200)
                        .progressViewStyle(LinearProgressViewStyle(tint: breakdown.rating.color))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                
                if let nextRating = viewModel.scoreBreakdown?.nextRating {
                    progressToNextRatingCard(nextRating: nextRating)
                }
            } else {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            viewModel.onTapRatingCard()
        }
    }
    
    private func progressToNextRatingCard(nextRating: LongevityRating) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(nextRating.color)
                Text("Progress to \(nextRating.displayName)")
                    .font(.headline)
                Spacer()
            }
            
            if let breakdown = viewModel.scoreBreakdown {
                HStack {
                    Text("\(breakdown.scoreToNextRating) points needed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(nextRating.description)")
                        .font(.subheadline)
                        .foregroundColor(nextRating.color)
                }
            }
        }
    }
    
    private var scoreBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Breakdown")
                .font(.title2)
                .fontWeight(.bold)
            
            if let breakdownItems = viewModel.scoreBreakdownItems {
                LazyVStack(spacing: 12) {
                    ForEach(Array(breakdownItems.enumerated()), id: \.offset) { index, item in
                        ScoreBreakdownRow(item: item)
                            .onTapGesture {
                                viewModel.onTapScoreBreakdownItem(item)
                            }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
        }
    }
    
    struct ScoreBreakdownRow: View {
        let item: ScoreBreakdownItem
        @State private var showingExplanation = false
        
        var body: some View {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: item.icon)
                        .foregroundColor(item.color)
                        .frame(width: 24)
                    
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(item.score)/\(item.maxScore)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingExplanation = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.borderless)
                }
                
                ProgressView(value: item.percentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: item.color))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .alert("How \(item.title) Score is Calculated", isPresented: $showingExplanation) {
                Button("Got it!") {
                    showingExplanation = false
                }
            } message: {
                Text(item.explanation)
            }
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    RatingView()
}

