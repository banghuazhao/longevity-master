//
// Created by Banghua Zhao on 26/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct HabitIconColorDataSource {
    static let colors: [Int] = [
        0x2ECC71CC, // Green - Eat Salmon with 80% opacity
        0x4ECDC4CC, // Teal - Swimming with 80% opacity
        0x34495ECC, // Blue-Gray - Sleep with 80% opacity
        0xE74C3CCC, // Red - Eat Berries with 80% opacity
        0x219653CC, // Green - Drink Green Tea with 80% opacity
        0x3498DBCC, // Blue - Strength Training with 80% opacity
        0x2980B9CC, // Blue - Brisk Walking with 80% opacity
        0x5DADE2CC, // Blue - Yoga or Stretching with 80% opacity
        0x8E44ADCC, // Purple - Meditate with 80% opacity
        0x9B59B6CC, // Purple - Connect Socially with 80% opacity
        0x2C3E50CC, // Dark Blue - Bedtime Routine with 80% opacity
        0x566573CC, // Gray - Short Nap with 80% opacity
        0xF1C40FCC, // Yellow - Sun Exposure with 80% opacity
        0xD4AC0DCC, // Yellow - Limit Alcohol with 80% opacity
        0xF5E8C7CC, // Light Peach with 80% opacity
        0xE6E6FACC, // Lavender with 80% opacity
        0xD1E0FFCC, // Light Slate Blue with 80% opacity
        0xFFE4B5CC, // Peach Puff with 80% opacity
        0xE0FFFFCC, // Light Cyan with 80% opacity
        0xF0E68CCC, // Light Khaki with 80% opacity
        0xFFB6C1CC, // Light Pink with 80% opacity
        0xADD8E6CC, // Light Blue with 80% opacity
        0xF0FFF0CC, // Honeydew with 80% opacity
        0xFAEBD7CC, // Antique White with 80% opacity
        0xD8BFD8CC, // Thistle with 80% opacity
        0xF0F8FFCC, // Alice Blue with 80% opacity
        0xFFE4E1CC, // Misty Rose with 80% opacity
    ]

    static func getColor(at index: Int) -> Int? {
        guard index >= 0 && index < colors.count else { return nil }
        return colors[index]
    }
}
