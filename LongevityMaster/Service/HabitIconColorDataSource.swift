//
// Created by Banghua Zhao on 26/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct HabitIconColorDataSource {
    static let colors: [Int] = [
        0xFF6B6B99, // Vibrant Red
        0xFF9F4099, // Bright Coral
        0xFFA77299, // Warm Peach
        0xFFD18C99, // Soft Orange
        0xFFEFC8CC, // Warm Yellow
        0xB6E66B99, // Lime Green
        0x6BD67E99, // Fresh Green
        0x4DD0AE99, // Teal Mint
        0x1AB3C199, // Ocean Blue
        0x5DADE299, // Blue Gray
        0x5499C799, // Sky Blue
        0x7289DA99, // Indigo Blue
        0xA084E899, // Soft Violet
        0xC084F599, // Lavender Purple
        0xE084C699, // Orchid Pink
        0xF39CC399, // Blush Rose
        0xFBC5A999, // Light Apricot
        0xF9E79F99, // Pale Yellow
        0xA8DADC99, // Calm Cyan
        0xE6D2D599, // Pale Pink
        0xD3CCE399, // Cool Lavender
        0xBFD8B899, // Minty Gray
        0xCCDDEE99, // Light Slate Blue
        0xD9D9D999, // Neutral Soft Gray
        0xFFE4E199, // Misty Rose
        0xFFF5E199, // Light Cream
        0xE0FFFF99, // Ice Blue
    ]


    static func getColor(at index: Int) -> Int? {
        guard index >= 0 && index < colors.count else { return nil }
        return colors[index]
    }
}
