//
// Created by Banghua Zhao on 08/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

extension Habit {
    var borderColor: Color {
        Color(hex: color).blend(with: .black, amount: 0.2)
    }

    var frequencyDescription: String {
        switch frequency {
        case .fixedDaysInWeek:
            let daysSet = Set(frequencyDetail.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
            return daysSet.isEmpty ? "No days set" : "Every \(daysString(from: daysSet))"
        case .nDaysEachWeek:
            let days = Int(frequencyDetail)
            guard let days else { return "No days set" }
            if days == 1 {
                return "1 day each week"
            } else {
                return "\(days) days each week"
            }
        case .fixedDaysInMonth:
            let daysSet = Set(frequencyDetail.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
            return daysSet.isEmpty ? "No days set" : "Every \(daysString(from: daysSet)) of month"
        case .nDaysEachMonth:
            let days = Int(frequencyDetail)
            guard let days else { return "No days set" }
            if days == 1 {
                return "1 day each month"
            } else {
                return "\(days) days each month"
            }
        }
    }
    
    var daysOfWeek: [Int] {
        guard case .fixedDaysInWeek = frequency else {
            return []
        }
        return frequencyDetail.components(separatedBy: ",")
            .compactMap {
                Int($0.replacingOccurrences(of: " ", with: ""))
            }
    }
    
    var daysOfMonth: [Int] {
        guard case .fixedDaysInMonth = frequency else {
            return []
        }
        return frequencyDetail.components(separatedBy: ",")
            .compactMap {
                Int($0.replacingOccurrences(of: " ", with: ""))
            }
    }
    
    var nDaysPerWeek: Int {
        guard case .nDaysEachWeek = frequency else {
            return 0
        }
        return Int(frequencyDetail.replacingOccurrences(of: " ", with: "")) ?? 0
    }
    
    var nDaysPerMonth: Int {
        guard case .nDaysEachMonth = frequency else {
            return 0
        }
        return Int(frequencyDetail.replacingOccurrences(of: " ", with: "")) ?? 0
    }

    private func daysString(from daysSet: Set<Int>) -> String {
        return daysSet.sorted().map { String($0) }.joined(separator: ", ")
    }
}
