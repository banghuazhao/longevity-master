//
// Created by Banghua Zhao on 22/11/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData
import SwiftUI

/// A habit that checks itself in once Apple Health shows its goal was met — 8,000 steps, half
/// an hour of exercise, seven hours of sleep.
@Table
struct HealthLink: Identifiable {
    let id: Int
    var habitID: Habit.ID
    var metric: HealthMetric
    /// In the metric's own unit: steps, minutes or hours.
    var goal: Int
    /// The last day an automatic check-in was made or decided against. A day is never looked
    /// at twice, so a check-in the user takes back stays taken back.
    var lastCheckInDay: Date?
}

extension HealthLink.Draft: Identifiable {}

/// What Apple Health can check a habit in for. Stored as its raw value, so new cases only ever
/// go on the end.
enum HealthMetric: Int, CaseIterable, Codable, QueryBindable, Identifiable {
    case steps
    case exerciseMinutes
    case mindfulMinutes
    case sleepHours

    var id: Int { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .steps: "Steps"
        case .exerciseMinutes: "Exercise"
        case .mindfulMinutes: "Mindfulness"
        case .sleepHours: "Sleep"
        }
    }

    var systemImage: String {
        switch self {
        case .steps: "figure.walk"
        case .exerciseMinutes: "flame.fill"
        case .mindfulMinutes: "brain.head.profile"
        case .sleepHours: "bed.double.fill"
        }
    }

    var color: Color {
        switch self {
        case .steps: .orange
        case .exerciseMinutes: .green
        case .mindfulMinutes: .teal
        case .sleepHours: .indigo
        }
    }

    var defaultGoal: Int {
        switch self {
        case .steps: 8000
        case .exerciseMinutes: 30
        case .mindfulMinutes: 10
        case .sleepHours: 7
        }
    }

    /// The goals offered, from easy to hard.
    var goalRange: ClosedRange<Int> {
        switch self {
        case .steps: 1000 ... 30000
        case .exerciseMinutes: 5 ... 180
        case .mindfulMinutes: 1 ... 120
        case .sleepHours: 4 ... 10
        }
    }

    var goalStep: Int {
        switch self {
        case .steps: 500
        case .exerciseMinutes: 5
        case .mindfulMinutes: 1
        case .sleepHours: 1
        }
    }

    /// "8,000 steps", "30 min", "7 h", for a goal in this metric's unit.
    func goalText(_ goal: Int) -> String {
        switch self {
        case .steps:
            String(localized: "\(goal.formatted()) steps")
        case .exerciseMinutes, .mindfulMinutes:
            Measurement(value: Double(goal), unit: UnitDuration.minutes)
                .formatted(.measurement(width: .abbreviated, usage: .asProvided))
        case .sleepHours:
            Measurement(value: Double(goal), unit: UnitDuration.hours)
                .formatted(.measurement(width: .abbreviated, usage: .asProvided))
        }
    }

    /// A sensible metric for a new habit in `category`, offered first.
    static func suggested(for category: HabitCategory) -> HealthMetric {
        switch category {
        case .exercise: .exerciseMinutes
        case .sleep: .sleepHours
        case .mentalHealth: .mindfulMinutes
        case .diet, .preventiveHealth: .steps
        }
    }
}
