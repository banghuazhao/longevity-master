//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct HabitsDataStore {
    static let eatSalmon = Habit.Draft(
        name: String(localized: "Eat salmon"),
        category: .diet,
        frequency: .nDaysEachWeek,
        frequencyDetail: "3",
        antiAgingRating: 4,
        icon: "🐟",
        color: 0xB6E66B99,
        note: String(localized: "Consume a 4-6 oz portion of salmon for omega-3 fatty acids.")
    )
    
    static let swimming = Habit.Draft(
        name: String(localized: "Swimming"),
        category: .exercise,
        frequency: .fixedDaysInWeek,
        frequencyDetail: "1,3,5",
        antiAgingRating: 5,
        icon: "🏊‍♂️",
        color: 0xFBC5A999,
        note: String(localized: "Swimming improves cardiovascular health, builds muscle strength, reduces stress, enhances flexibility, and is low-impact, suitable for all ages.")
    )
    
    static let sleep = Habit.Draft(
        name: String(localized: "Sleep 7-9 hours"),
        category: .sleep,
        frequency: .nDaysEachWeek,
        frequencyDetail: "7",
        antiAgingRating: 5,
        icon: "😴",
        color: 0xFF6B6B99,
        note: String(localized: "Maintain a consistent sleep schedule with 7-9 hours of rest.")
    )
    
    static let all = [

        // 🥗 DIET
        Habit.Draft(name: String(localized: "Eat salmon"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 5, icon: "🐟", color: 0xB6E66B99, note: String(localized: "Consume a 4–6 oz portion of salmon for omega-3 fatty acids.")),
        Habit.Draft(name: String(localized: "Eat kale"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "4", antiAgingRating: 4, icon: "🥬", color: 0xD9D9D999, note: String(localized: "Include kale in meals for antioxidants and vitamins.")),
        Habit.Draft(name: String(localized: "Eat berries"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 5, icon: "🍓", color: 0xA084E899, note: String(localized: "Eat a handful of blueberries or strawberries for antioxidants.")),
        Habit.Draft(name: String(localized: "Drink green tea"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🍵", color: 0xE0FFFF99, note: String(localized: "Drink 1–2 cups of green tea for polyphenols and hydration.")),
        Habit.Draft(name: String(localized: "Stay hydrated"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "💧", color: 0xAED6F1CC, note: String(localized: "Drink at least 8 cups of water per day to stay hydrated.")),
        Habit.Draft(name: String(localized: "Eat nuts"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "4", antiAgingRating: 4, icon: "🥜", color: 0xEDBB99CC, note: String(localized: "Eat a small handful of nuts for healthy fats and protein.")),

        // 🏃‍♂️ EXERCISE
        Habit.Draft(name: String(localized: "Swimming"), category: .exercise, frequency: .fixedDaysInWeek, frequencyDetail: "1,3,5", antiAgingRating: 5, icon: "🏊‍♂️", color: 0x1AB3C199, note: String(localized: "Improves cardiovascular health and reduces stress.")),
        Habit.Draft(name: String(localized: "Strength training"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 5, icon: "🏋️", color: 0xC084F599, note: String(localized: "Build muscle and improve bone density.")),
        Habit.Draft(name: String(localized: "Brisk walking"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 5, icon: "🚶", color: 0xBFD8B899, note: String(localized: "Walk 30 minutes at moderate pace.")),
        Habit.Draft(name: String(localized: "Yoga or stretching"), category: .exercise, frequency: .nDaysEachMonth, frequencyDetail: "10", antiAgingRating: 4, icon: "🧘", color: 0xFFF5E199, note: String(localized: "Improve flexibility and reduce stress.")),
        Habit.Draft(name: String(localized: "Take the stairs"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 3, icon: "🪜", color: 0xB6E66B99, note: String(localized: "Boost daily movement and heart health.")),
        Habit.Draft(name: String(localized: "Do a morning stretch routine"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🤸", color: 0xE0FFFF99, note: String(localized: "Start your day with light stretching to increase circulation and flexibility.")),

        // 💤 SLEEP
        Habit.Draft(name: String(localized: "Sleep 7–9 hours"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "😴", color: 0xFFD18C99, note: String(localized: "Maintain a consistent schedule with enough rest.")),
        Habit.Draft(name: String(localized: "Follow bedtime routine"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🌙", color: 0xBFD8B899, note: String(localized: "Relax before bed to improve sleep quality.")),
        Habit.Draft(name: String(localized: "Take a short nap"), category: .sleep, frequency: .fixedDaysInWeek, frequencyDetail: "1,2,3,4,5", antiAgingRating: 3, icon: "🛌", color: 0xD9D9D999, note: String(localized: "Nap 20–30 minutes to boost alertness.")),
        Habit.Draft(name: String(localized: "Avoid caffeine after 2 PM"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🍵", color: 0xFFF5E199, note: String(localized: "Prevent sleep disruption by avoiding stimulants late in the day.")),

        // 🧠 MENTAL HEALTH
        Habit.Draft(name: String(localized: "Meditate"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "🧘‍♀️", color: 0x4DD0AE99, note: String(localized: "Practice mindfulness for calm and clarity.")),
        Habit.Draft(name: String(localized: "Practice gratitude"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "📝", color: 0xA084E899, note: String(localized: "Write 3 things you're grateful for daily.")),
        Habit.Draft(name: String(localized: "Connect socially"), category: .mentalHealth, frequency: .nDaysEachMonth, frequencyDetail: "5", antiAgingRating: 4, icon: "🧑‍🤝‍🧑", color: 0xF9E79F99, note: String(localized: "Engage in meaningful conversation with loved ones.")),
        Habit.Draft(name: String(localized: "Digital detox"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 3, icon: "📵", color: 0xE6D2D599, note: String(localized: "Take screen breaks to reduce eye strain and stress.")),

        // 🛡️ PREVENTIVE HEALTH
        Habit.Draft(name: String(localized: "Get sun exposure"), category: .preventiveHealth, frequency: .fixedDaysInMonth, frequencyDetail: "1,7,14,21,28", antiAgingRating: 3, icon: "☀️", color: 0xCCDDEE99, note: String(localized: "10–15 minutes of sunlight for vitamin D.")),
        Habit.Draft(name: String(localized: "Brush & floss teeth"), category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "14", antiAgingRating: 2, icon: "🦷", color: 0xD9D9D999, note: String(localized: "Prevent gum disease and inflammation.")),
        Habit.Draft(name: String(localized: "Take a walk after meals"), category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🚶‍♂️", color: 0xFFE4E199, note: String(localized: "Walk for 10–15 minutes after meals to support digestion and blood sugar control.")),
        Habit.Draft(name: String(localized: "Posture check"), category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🧍", color: 0xFFF5E199, note: String(localized: "Maintain good posture to reduce back and neck strain."))
    ]


    
    static func habits(forCategory category: HabitCategory) -> [Habit.Draft] {
        all.filter { $0.category == category }
    }
}
