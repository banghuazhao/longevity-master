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
}
