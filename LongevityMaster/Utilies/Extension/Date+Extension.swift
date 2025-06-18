//
// Created by Banghua Zhao on 18/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

extension Date {
    func startOfDay(for calendar: Calendar) -> Date {
        calendar.startOfDay(for: self)
    }

    func endOfDay(for calendar: Calendar) -> Date {
        let startOfDay = startOfDay(for: calendar)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            .addingTimeInterval(-0.001)
        return endOfDay
    }
}
