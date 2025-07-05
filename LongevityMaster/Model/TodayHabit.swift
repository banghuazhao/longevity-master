//
// Created by Banghua Zhao on 18/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

struct TodayHabit {
    let habit: Habit
    let isCompleted: Bool
    let streakDescription: String?
    let frequencyDescription: String?
    
    init(habit: Habit, isCompleted: Bool, streakDescription: String? = nil , frequencyDescription: String? = nil) {
        self.habit = habit
        self.isCompleted = isCompleted
        self.streakDescription = streakDescription
        self.frequencyDescription = frequencyDescription
    }
}

struct TodayDraftHabit {
    let habit: Habit.Draft
    let isCompleted: Bool
    let streakDescription: String?
    let frequencyDescription: String?
    
    init(habit: Habit.Draft, isCompleted: Bool, streakDescription: String? = nil , frequencyDescription: String? = nil) {
        self.habit = habit
        self.isCompleted = isCompleted
        self.streakDescription = streakDescription
        self.frequencyDescription = frequencyDescription
    }
}
