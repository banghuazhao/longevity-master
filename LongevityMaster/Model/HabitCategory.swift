//
// Created by Banghua Zhao on 01/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

/// An enumeration representing the categories of habits.
enum HabitCategory: String, Codable {
    case diet = "Diet"
    case exercise = "Food"
    case sleep = "Sleep"
    case preventiveHealth = "Preventive Health"
    case mentalHealth = "Mental Health"
    
    static var allCases: [HabitCategory] = [.diet, .exercise, .sleep, .preventiveHealth, .mentalHealth]
}
