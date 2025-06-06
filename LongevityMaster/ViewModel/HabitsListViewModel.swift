//
// Created by Banghua Zhao on 06/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Observation
import SharingGRDB

@Observable
@MainActor
class HabitsListViewModel {
    @ObservationIgnored
    @FetchAll var habits: [Habit]
}
