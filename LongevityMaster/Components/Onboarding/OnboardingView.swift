//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SQLiteData

@Observable
@MainActor
class OnboardingViewModel {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    var selectedHabits: Set<Habit.Draft> = []
    /// A program picked as the starting point. Picking one selects its habits; finishing
    /// onboarding enrolls the user in it.
    var selectedProgram: Program?
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

    /// One program at a time: picking another swaps its habits in for the previous one's.
    /// Habits the user ticked by hand stay ticked unless they came with the program.
    func toggleProgram(_ program: Program) {
        withAnimation {
            if let previous = selectedProgram {
                selectedHabits.subtract(previous.habits)
            }
            if selectedProgram?.id == program.id {
                selectedProgram = nil
            } else {
                selectedProgram = program
                selectedHabits.formUnion(program.habits)
            }
        }
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
            try await database.write { [selectedHabits, selectedProgram] db in
                for habitDraft in selectedHabits {
                    _ = try Habit
                        .upsert { habitDraft }
                        .returning { $0 }
                        .fetchOne(db)
                }
                // After the habits, so the program finds them by name instead of adding its
                // own copies.
                if let selectedProgram {
                    try ProgramEnrollments.start(selectedProgram, on: Date(), in: db)
                }
            }
        }
        
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        AppOpenAdPolicy.recordOnboardingCompleted()
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
                    Text(String(localized: "Welcome to Longevity Master"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(String(localized: "Build healthy habits that promote longevity and well-being. Let's start by selecting some habits that interest you."))
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
                Text(String(localized: "Get Started"))
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
                Text(String(localized: "Choose Your Habits"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(String(localized: "Select habits that interest you. You can always add more later!"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            
            // Programs
            VStack(alignment: .leading, spacing: 8) {
                Text("Start with a program")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ProgramsDataStore.all) { program in
                            OnboardingProgramChip(
                                program: program,
                                isSelected: viewModel.selectedProgram?.id == program.id,
                                onToggle: { viewModel.toggleProgram(program) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 12)

            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryFilterButton(
                        title: String(localized: "All"),
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
                    Text(String(localized: "Continue"))
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
                    Text(String(localized: "You're All Set!"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    if viewModel.selectedHabits.count == 1 {
                        Text("You've selected \(viewModel.selectedHabits.count) habit. You can always add more habits or modify existing ones later.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("You've selected \(viewModel.selectedHabits.count) habits. You can always add more habits or modify existing ones later.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if let program = viewModel.selectedProgram {
                        Text("\(program.icon) Your “\(program.title)” program starts today.")
                            .font(.body.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.completeOnboarding()
                    dismiss()
                }
            }) {
                Text(String(localized: "Start Your Journey"))
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

struct OnboardingProgramChip: View {
    let program: Program
    let isSelected: Bool
    let onToggle: () -> Void

    @Dependency(\.themeManager) var themeManager

    var body: some View {
        Button(action: {
            Haptics.shared.vibrateIfEnabled()
            onToggle()
        }) {
            HStack(spacing: 8) {
                Text(program.icon)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 0) {
                    Text(program.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("\(program.durationDays) days · \(program.habits.count) habits")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.current.primaryColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? themeManager.current.primaryColor.opacity(0.12) : Color(hex: program.color).opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? themeManager.current.primaryColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
