//
// Created by Banghua Zhao on 06/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Observation
import SharingGRDB
import Foundation

@Observable
@MainActor
class TodayViewModel {
    @ObservationIgnored
    @FetchAll var habits: [Habit]
    
    var selectedDate: Date = Date()
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }
}
