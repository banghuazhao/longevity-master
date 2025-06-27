//
// Created by Banghua Zhao on 02/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

extension Color {
    init(hex: Int) {
      self.init(
        red: Double((hex >> 24) & 0xFF) / 255.0,
        green: Double((hex >> 16) & 0xFF) / 255.0,
        blue: Double((hex >> 8) & 0xFF) / 255.0,
        opacity: Double(hex & 0xFF) / 0xFF
      )
    }

    func blend(with color: Color, amount: CGFloat) -> Color {
        let uiSelf = UIColor(self)
        let uiOther = UIColor(color)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        uiSelf.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiOther.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return Color(
            red: Double(r1 * (1 - amount) + r2 * amount),
            green: Double(g1 * (1 - amount) + g2 * amount),
            blue: Double(b1 * (1 - amount) + b2 * amount)
        )
    }
    
    var hexIntWithAlpha: Int {
        // Convert SwiftUI Color to UIColor
        let uiColor = UIColor(self)
        
        // Ensure the color is in RGB color space with alpha
        guard let components = uiColor.cgColor.components, uiColor.cgColor.numberOfComponents >= 4 else {
            return 0xFFFFFFFF
        }
        
        // Extract RGBA components
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        let alpha = components[3]
        
        // Convert to 0-255 range
        let r = Int(red * 255.0)
        let g = Int(green * 255.0)
        let b = Int(blue * 255.0)
        let a = Int(alpha * 255.0)
        
        // Combine into a single hex integer (0xRRGGBBAA)
        return (r << 24) | (g << 16) | (b << 8) | a
    }
}
