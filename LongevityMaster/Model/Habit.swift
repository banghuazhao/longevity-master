//
// Created by Banghua Zhao on 01/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import Foundation
import SwiftData

/// A model representing a habit tracked by the LongevityMaster app.
///
/// This class uses SwiftData to persist habit data, including name, category, frequency, and completion history.
@Model
class Habit {
    /// The name of the habit.
    var name: String
    
    /// The raw string representation of the habit's category.
    var categoryRaw: String
    
    /// The raw string representation of the habit's frequency.
    var frequencyRaw: String
    
    /// The anti-aging rating of the habit (1-5 stars).
    var antiAgingRating: Int
    
    /// The emoji or icon representing the habit.
    var icon: String
    
    /// The color of the habit's icon (stored as a hex string, e.g., "#FFFFFF").
    var color: String
    
    /// An optional note or description for the habit.
    var note: String?
    
    /// An array of dates when the habit was completed.
    var completionDates: [Date]
    
    /// A flag indicating whether the habit is completed for the current day.
    var isCompleted: Bool
    
    /// Initializes a new habit with the specified properties.
    ///
    /// - Parameters:
    ///   - name: The name of the habit.
    ///   - category: The category of the habit.
    ///   - frequency: The frequency settings for the habit.
    ///   - icon: The emoji or icon for the habit.
    ///   - color: The color of the icon as a hex string.
    ///   - note: An optional note or description (default is `nil`).
    ///   - antiAgingRating: The anti-aging rating (1-5).
    ///   - completionDates: The list of completion dates (default is empty).
    ///   - isCompleted: The completion status for today (default is `false`).
    init(
        name: String,
        category: HabitCategory,
        frequency: HabitFrequency,
        icon: String,
        color: String,
        note: String? = nil,
        antiAgingRating: Int,
        completionDates: [Date] = [],
        isCompleted: Bool = false
    ) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.frequencyRaw = frequency.rawValue
        self.icon = icon
        self.color = color
        self.note = note
        self.antiAgingRating = antiAgingRating
        self.completionDates = completionDates
        self.isCompleted = isCompleted
    }
    
    // MARK: - Computed Properties
    
    /// The category of the habit, mapped from the raw string value.
    var category: HabitCategory {
        get { HabitCategory(rawValue: categoryRaw) ?? .lifestyle }
        set { categoryRaw = newValue.rawValue }
    }
    
    /// The frequency settings of the habit, mapped from the raw string value.
    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .fixedDaysInWeek(Set(1...7)) }
        set { frequencyRaw = newValue.rawValue }
    }
    
    // MARK: - Factory Methods
    
    /// Creates a default habit with predefined values.
    ///
    /// - Returns: A `Habit` instance with default settings.
    static func makeDefaultHabit() -> Habit {
        .init(
            name: "",
            category: .lifestyle,
            frequency: .fixedDaysInWeek(Set(1...7)), // All days by default
            icon: "🍣",
            color: "#FFFFFF",
            antiAgingRating: 4
        )
    }
}
