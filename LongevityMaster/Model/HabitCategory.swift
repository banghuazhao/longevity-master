//
// Created by Banghua Zhao on 01/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

/// An enumeration representing the categories of habits.
enum HabitCategory: String, Codable {
    /// General lifestyle habits.
    case lifestyle = "Lifestyle"
    
    /// Food-related habits.
    case food = "Food"
    
    /// Sports-related habits.
    case sports = "Sports"
    
    /// Mental health-related habits.
    case mentalHealth = "Mental Health"
    
    /// All possible habit categories.
    static var allCases: [HabitCategory] = [.lifestyle, .food, .sports, .mentalHealth]
}
