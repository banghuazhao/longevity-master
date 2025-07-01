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
        eatSalmon,
        swimming,
        sleep,
        Habit(
            id: 4,
            name: "Eat kale",
            category: .diet,
            frequency: .nDaysEachWeek,
            frequencyDetail: "4",
            antiAgingRating: 4,
            icon: "🥬",
            color: 0xD9D9D999,
            note: "Include kale in meals for antioxidants and vitamins."
        ),
        Habit(
            id: 5,
            name: "Eat berries",
            category: .diet,
            frequency: .nDaysEachWeek,
            frequencyDetail: "5",
            antiAgingRating: 4,
            icon: "🍓",
            color:  0xA084E899,
            note: "Eat a handful of blueberries or strawberries for antioxidants."
        ),
        Habit(
            id: 6,
            name: "Drink green tea",
            category: .diet,
            frequency: .nDaysEachWeek,
            frequencyDetail: "7",
            antiAgingRating: 2,
            icon: "☕",
            color: 0xE0FFFF99,
            note: "Drink 1-2 cups of green tea for polyphenols and hydration."
        ),
        Habit(
            id: 7,
            name: "Strength training",
            category: .exercise,
            frequency: .nDaysEachWeek,
            frequencyDetail: "3",
            antiAgingRating: 5,
            icon: "🏋️",
            color: 0x3498DBCC,
            note: "Perform 30-45 minutes of resistance exercises (e.g., weights or bodyweight)."
        ),
        Habit(
            id: 8,
            name: "Brisk walking",
            category: .exercise,
            frequency: .nDaysEachWeek,
            frequencyDetail: "5",
            antiAgingRating: 5,
            icon: "🚶",
            color: 0x2980B9CC,
            note: "Walk for 30 minutes at a moderate pace."
        ),
        Habit(
            id: 9,
            name: "Yoga or stretching",
            category: .exercise,
            frequency: .nDaysEachMonth,
            frequencyDetail: "10",
            antiAgingRating: 4,
            icon: "🧘",
            color: 0x5DADE2CC,
            note: "Practice 20-30 minutes of yoga or stretching for flexibility."
        ),
        Habit(
            id: 10,
            name: "Meditate",
            category: .mentalHealth,
            frequency: .nDaysEachWeek,
            frequencyDetail: "7",
            antiAgingRating: 4,
            icon: "🧘‍♀️",
            color: 0x8E44ADCC,
            note: "Practice 10-15 minutes of mindfulness meditation."
        ),
        Habit(
            id: 11,
            name: "Connect socially",
            category: .mentalHealth,
            frequency: .nDaysEachMonth,
            frequencyDetail: "5",
            antiAgingRating: 3,
            icon: "👥",
            color: 0x9B59B6CC,
            note: "Have a meaningful conversation with friends or family."
        ),
        Habit(
            id: 12,
            name: "Practice gratitude",
            category: .mentalHealth,
            frequency: .nDaysEachWeek,
            frequencyDetail: "7",
            antiAgingRating: 3,
            icon: "📝",
            color: 0xA569BDCC,
            note: "Write down 3 things you’re grateful for each day."
        ),
        Habit(
            id: 13,
            name: "Follow a bedtime routine",
            category: .sleep,
            frequency: .nDaysEachWeek,
            frequencyDetail: "7",
            antiAgingRating: 4,
            icon: "🌙",
            color: 0x2C3E50CC,
            note: "Avoid screens and read or relax 30 minutes before bed."
        ),
        Habit(
            id: 14,
            name: "Take a short nap",
            category: .sleep,
            frequency: .fixedDaysInWeek,
            frequencyDetail: "1,2, 3,4,5",
            antiAgingRating: 3,
            icon: "🛌",
            color: 0x566573CC,
            note: "Nap for 20-30 minutes to boost energy."
        ),
        Habit(
            id: 15,
            name: "Get sun exposure",
            category: .preventiveHealth,
            frequency: .fixedDaysInMonth,
            frequencyDetail: "1,7,14,21,28",
            antiAgingRating: 2,
            icon: "☀️",
            color: 0xF1C40FCC,
            note: "Spend 10-15 minutes in sunlight for vitamin D, with sunscreen if needed."
        ),
        Habit(
            id: 16,
            name: "Brush and floss teeth",
            category: .preventiveHealth,
            frequency: .nDaysEachWeek,
            frequencyDetail: "14",
            antiAgingRating: 1,
            icon: "🦷",
            color: 0xF4D03FCC,
            note: "Maintain oral hygiene to reduce inflammation-related diseases."
        ),
        Habit(
            id: 17,
            name: "Limit alcohol",
            category: .preventiveHealth,
            frequency: .nDaysEachWeek,
            frequencyDetail: "7",
            antiAgingRating: 1,
            icon: "🍷",
            color: 0xD4AC0DCC,
            note: "Keep alcohol to 1 drink or less for women, 2 or less for men."
        )
    ]
    
    static func habits(forCategory category: HabitCategory) -> [Habit] {
        all.filter { $0.category == category }
    }
}
