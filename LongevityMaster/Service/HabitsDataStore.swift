//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct HabitsDataStore {
    static let eatSalmon = Habit(
        id: 1,
        name: "Eat salmon",
        category: .diet,
        frequency: .nDaysEachWeek,
        frequencyDetail: "3",
        antiAgingRating: 4,
        icon: "🐟",
        color: 0xB6E66B99,
        note: "Consume a 4-6 oz portion of salmon for omega-3 fatty acids."
    )
    
    static let swimming = Habit(
        id: 2,
        name: "Swimming",
        category: .exercise,
        frequency: .fixedDaysInWeek,
        frequencyDetail: "1,3,5",
        antiAgingRating: 5,
        icon: "🏊‍♂️",
        color: 0xFBC5A999,
        note: "Swimming improves cardiovascular health, builds muscle strength, reduces stress, enhances flexibility, and is low-impact, suitable for all ages."
    )
    
    static let sleep = Habit(
        id: 3,
        name: "Sleep 7-9 hours",
        category: .sleep,
        frequency: .nDaysEachWeek,
        frequencyDetail: "7",
        antiAgingRating: 5,
        icon: "😴",
        color: 0xFF6B6B99,
        note: "Maintain a consistent sleep schedule with 7-9 hours of rest."
    )
    
    static let all = [

        // 🥗 DIET
        Habit(id: 1, name: "Eat salmon", category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 5, icon: "🐟", color: 0xB6E66B99, note: "Consume a 4–6 oz portion of salmon for omega-3 fatty acids."),
        Habit(id: 2, name: "Eat kale", category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "4", antiAgingRating: 4, icon: "🥬", color: 0xD9D9D999, note: "Include kale in meals for antioxidants and vitamins."),
        Habit(id: 3, name: "Eat berries", category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 5, icon: "🍓", color: 0xA084E899, note: "Eat a handful of blueberries or strawberries for antioxidants."),
        Habit(id: 4, name: "Drink green tea", category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🍵", color: 0xE0FFFF99, note: "Drink 1–2 cups of green tea for polyphenols and hydration."),
        Habit(id: 5, name: "Stay hydrated", category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "💧", color: 0xAED6F1CC, note: "Drink at least 8 cups of water per day to stay hydrated."),
        Habit(id: 6, name: "Eat nuts", category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "4", antiAgingRating: 4, icon: "🥜", color: 0xEDBB99CC, note: "Eat a small handful of nuts for healthy fats and protein."),

        // 🏃‍♂️ EXERCISE
        Habit(id: 7, name: "Swimming", category: .exercise, frequency: .fixedDaysInWeek, frequencyDetail: "1,3,5", antiAgingRating: 5, icon: "🏊‍♂️", color: 0x1AB3C199, note: "Improves cardiovascular health and reduces stress."),
        Habit(id: 8, name: "Strength training", category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 5, icon: "🏋️", color: 0xC084F599, note: "Build muscle and improve bone density."),
        Habit(id: 9, name: "Brisk walking", category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 5, icon: "🚶", color: 0xBFD8B899, note: "Walk 30 minutes at moderate pace."),
        Habit(id: 10, name: "Yoga or stretching", category: .exercise, frequency: .nDaysEachMonth, frequencyDetail: "10", antiAgingRating: 4, icon: "🧘", color: 0xFFF5E199, note: "Improve flexibility and reduce stress."),
        Habit(id: 11, name: "Take the stairs", category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 3, icon: "🪜", color: 0xB6E66B99, note: "Boost daily movement and heart health."),
        Habit(id: 12, name: "Do a morning stretch routine", category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🤸", color: 0xE0FFFF99, note: "Start your day with light stretching to increase circulation and flexibility."),

        // 💤 SLEEP
        Habit(id: 13, name: "Sleep 7–9 hours", category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "😴", color: 0xFFD18C99, note: "Maintain a consistent schedule with enough rest."),
        Habit(id: 14, name: "Follow bedtime routine", category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🌙", color: 0xBFD8B899, note: "Relax before bed to improve sleep quality."),
        Habit(id: 15, name: "Take a short nap", category: .sleep, frequency: .fixedDaysInWeek, frequencyDetail: "1,2,3,4,5", antiAgingRating: 3, icon: "🛌", color: 0xD9D9D999, note: "Nap 20–30 minutes to boost alertness."),
        Habit(id: 16, name: "Avoid caffeine after 2 PM", category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🍵", color: 0xFFF5E199, note: "Prevent sleep disruption by avoiding stimulants late in the day."),

        // 🧠 MENTAL HEALTH
        Habit(id: 17, name: "Meditate", category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "🧘‍♀️", color: 0x4DD0AE99, note: "Practice mindfulness for calm and clarity."),
        Habit(id: 18, name: "Practice gratitude", category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "📝", color: 0xA084E899, note: "Write 3 things you're grateful for daily."),
        Habit(id: 19, name: "Connect socially", category: .mentalHealth, frequency: .nDaysEachMonth, frequencyDetail: "5", antiAgingRating: 4, icon: "🧑‍🤝‍🧑", color: 0xF9E79F99, note: "Engage in meaningful conversation with loved ones."),
        Habit(id: 20, name: "Digital detox", category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 3, icon: "📵", color: 0xE6D2D599, note: "Take screen breaks to reduce eye strain and stress."),

        // 🛡️ PREVENTIVE HEALTH
        Habit(id: 21, name: "Get sun exposure", category: .preventiveHealth, frequency: .fixedDaysInMonth, frequencyDetail: "1,7,14,21,28", antiAgingRating: 3, icon: "☀️", color: 0xCCDDEE99, note: "10–15 minutes of sunlight for vitamin D."),
        Habit(id: 22, name: "Brush & floss teeth", category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "14", antiAgingRating: 2, icon: "🦷", color: 0xD9D9D999, note: "Prevent gum disease and inflammation."),
        Habit(id: 23, name: "Take a walk after meals", category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🚶‍♂️", color: 0xFFE4E199, note: "Walk for 10–15 minutes after meals to support digestion and blood sugar control."),
        Habit(id: 24, name: "Posture check", category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🧍", color: 0xFFF5E199, note: "Maintain good posture to reduce back and neck strain.")
    ]


    
    static func habits(forCategory category: HabitCategory) -> [Habit] {
        all.filter { $0.category == category }
    }
}
