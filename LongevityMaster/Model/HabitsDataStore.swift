//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct HabitsDataStore {
    static let eatSalmon = Habit(
        name: "Eat salmon",
        category: .diet,
        frequency: .nDaysEachWeek(3),
        antiAgingRating: 4,
        icon: "🐟",
        color: "#2ECC71",
        note: "Consume a 4-6 oz portion of salmon for omega-3 fatty acids."
    )
    
    static let swimming = Habit(
        name: "Swimming",
        category: .exercise,
        frequency: .fixedDaysInWeek([1, 3, 5]),
        antiAgingRating: 5,
        icon: "🏊‍♂️",
        color: "#4ECDC4",
        note: "Swimming improves cardiovascular health, builds muscle strength, reduces stress, enhances flexibility, and is low-impact, suitable for all ages."
    )
    
    static let sleep = Habit(
        name: "Sleep 7-9 hours",
        category: .sleep,
        frequency: .nDaysEachWeek(7),
        antiAgingRating: 5,
        icon: "😴",
        color: "#34495E",
        note: "Maintain a consistent sleep schedule with 7-9 hours of rest."
    )
    
    static let all = [
        eatSalmon,
        swimming,
        Habit(
            name: "Eat kale",
            category: .diet,
            frequency: .nDaysEachWeek(4),
            antiAgingRating: 4,
            icon: "🥬",
            color: "#27AE60",
            note: "Include kale in meals for antioxidants and vitamins."
        ),
        Habit(
            name: "Eat berries",
            category: .diet,
            frequency: .nDaysEachWeek(5),
            antiAgingRating: 4,
            icon: "🍓",
            color: "#E74C3C",
            note: "Eat a handful of blueberries or strawberries for antioxidants."
        ),
        Habit(
            name: "Drink green tea",
            category: .diet,
            frequency: .nDaysEachWeek(7),
            antiAgingRating: 2,
            icon: "☕",
            color: "#219653",
            note: "Drink 1-2 cups of green tea for polyphenols and hydration."
        ),
        Habit(
            name: "Strength training",
            category: .exercise,
            frequency: .nDaysEachWeek(3),
            antiAgingRating: 5,
            icon: "🏋️",
            color: "#3498DB",
            note: "Perform 30-45 minutes of resistance exercises (e.g., weights or bodyweight)."
        ),
        Habit(
            name: "Brisk walking",
            category: .exercise,
            frequency: .nDaysEachWeek(5),
            antiAgingRating: 5,
            icon: "🚶",
            color: "#2980B9",
            note: "Walk for 30 minutes at a moderate pace."
        ),
        Habit(
            name: "Yoga or stretching",
            category: .exercise,
            frequency: .nDaysEachWeek(3),
            antiAgingRating: 4,
            icon: "🧘",
            color: "#5DADE2",
            note: "Practice 20-30 minutes of yoga or stretching for flexibility."
        ),
        Habit(
            name: "Meditate",
            category: .mentalHealth,
            frequency: .nDaysEachWeek(7),
            antiAgingRating: 4,
            icon: "🧘‍♀️",
            color: "#8E44AD",
            note: "Practice 10-15 minutes of mindfulness meditation."
        ),
        Habit(
            name: "Connect socially",
            category: .mentalHealth,
            frequency: .nDaysEachWeek(3),
            antiAgingRating: 3,
            icon: "👥",
            color: "#9B59B6",
            note: "Have a meaningful conversation with friends or family."
        ),
        Habit(
            name: "Practice gratitude",
            category: .mentalHealth,
            frequency: .nDaysEachWeek(7),
            antiAgingRating: 3,
            icon: "📝",
            color: "#A569BD",
            note: "Write down 3 things you’re grateful for each day."
        ),
        Habit(
            name: "Follow a bedtime routine",
            category: .sleep,
            frequency: .nDaysEachWeek(7),
            antiAgingRating: 4,
            icon: "🌙",
            color: "#2C3E50",
            note: "Avoid screens and read or relax 30 minutes before bed."
        ),
        Habit(
            name: "Take a short nap",
            category: .sleep,
            frequency: .nDaysEachWeek(3),
            antiAgingRating: 3,
            icon: "🛌",
            color: "#566573",
            note: "Nap for 20-30 minutes to boost energy."
        ),
        Habit(
            name: "Get sun exposure",
            category: .preventiveHealth,
            frequency: .nDaysEachWeek(7),
            antiAgingRating: 2,
            icon: "☀️",
            color: "#F1C40F",
            note: "Spend 10-15 minutes in sunlight for vitamin D, with sunscreen if needed."
        ),
        Habit(
            name: "Brush and floss teeth",
            category: .preventiveHealth,
            frequency: .nDaysEachWeek(14),
            antiAgingRating: 1,
            icon: "🦷",
            color: "#F4D03F",
            note: "Maintain oral hygiene to reduce inflammation-related diseases."
        ),
        Habit(
            name: "Limit alcohol",
            category: .preventiveHealth,
            frequency: .nDaysEachWeek(7),
            antiAgingRating: 1,
            icon: "🍷",
            color: "#D4AC0D",
            note: "Keep alcohol to 1 drink or less for women, 2 or less for men."
        )
    ]
    
    static func habits(forCategory category: HabitCategory) -> [Habit] {
        all.filter { $0.category == category }
    }
}
