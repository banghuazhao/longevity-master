//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SharingGRDB

@Observable
@MainActor
class OnboardingViewModel {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    var selectedHabits: Set<Habit.Draft> = []
    var currentStep: OnboardingStep = .welcome
    var selectedCategory: HabitCategory? = nil
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case selectHabits = 1
        case complete = 2
    }
    
    var predefinedHabits: [Habit.Draft] {
        if let selectedCategory = selectedCategory {
            return HabitsDataStore.habits(forCategory: selectedCategory)
        }
        return HabitsDataStore.all
    }
    
    var filteredHabits: [Habit.Draft] {
        predefinedHabits
    }
    
    func toggleHabitSelection(_ habit: Habit.Draft) {
        if selectedHabits.contains(habit) {
            selectedHabits.remove(habit)
        } else {
            selectedHabits.insert(habit)
        }
    }
    
    func isHabitSelected(_ habit: Habit.Draft) -> Bool {
        selectedHabits.contains(habit)
    }
    
    func selectCategory(_ category: HabitCategory?) {
        withAnimation {
            selectedCategory = category
        }
    }
    
    func nextStep() {
        withAnimation {
            if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
               currentIndex + 1 < OnboardingStep.allCases.count {
                currentStep = OnboardingStep.allCases[currentIndex + 1]
            }
        }
    }
    
    func previousStep() {
        withAnimation {
            if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
               currentIndex > 0 {
                currentStep = OnboardingStep.allCases[currentIndex - 1]
            }
        }
    }
    
    func completeOnboarding() async {
        await withErrorReporting {
            try await database.write { [selectedHabits] db in
                for habitDraft in selectedHabits {
                    _ = try Habit
                        .upsert { habitDraft }
                        .returning { $0 }
                        .fetchOne(db)
                }
            }
        }
        
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {                
                switch viewModel.currentStep {
                case .welcome:
                    welcomeView
                case .selectHabits:
                    selectHabitsView
                case .complete:
                    completeView
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                VStack(spacing: 16) {
                    Text("Welcome to Longevity Master")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Build healthy habits that promote longevity and well-being. Let's start by selecting some habits that interest you.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            Button(action: {
                viewModel.nextStep()
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.current.primaryColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private var selectHabitsView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("Choose Your Habits")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select habits that interest you. You can always add more later!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryFilterButton(
                        title: "All",
                        isSelected: viewModel.selectedCategory == nil,
                        action: { viewModel.selectCategory(nil) }
                    )
                    
                    ForEach(HabitCategory.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            title: category.briefTitle,
                            isSelected: viewModel.selectedCategory == category,
                            action: { viewModel.selectCategory(category) }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Habits list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredHabits, id: \.self) { habit in
                        OnboardingHabitCard(
                            habit: habit,
                            isSelected: viewModel.isHabitSelected(habit),
                            onToggle: { viewModel.toggleHabitSelection(habit) }
                        )
                    }
                }
                .padding()
            }
            
            // Bottom buttons
            HStack(spacing: 16) {
//                Button {
//                    viewModel.previousStep()
//                } label: {
//                    Text("Back")
//                        .appRectButtonStyle()
//                }
                
                Button {
                    viewModel.nextStep()
                }
                label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.current.primaryColor)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    private var completeView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 16) {
                    Text("You're All Set!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("You've selected \(viewModel.selectedHabits.count) habit\(viewModel.selectedHabits.count == 1 ? "" : "s"). You can always add more habits or modify existing ones later.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.completeOnboarding()
                    dismiss()
                }
            }) {
                Text("Start Your Journey")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.current.primaryColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

struct OnboardingHabitCard: View {
    let habit: Habit.Draft
    let isSelected: Bool
    let onToggle: () -> Void
    
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? themeManager.current.primaryColor : .gray)
                
                // Habit icon
                Text(habit.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(habit.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Anti-aging rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(habit.antiAgingRating)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? themeManager.current.primaryColor : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OnboardingView()
} 
