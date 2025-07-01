//
//  CheckinHistoryView.swift
//  LongevityMaster
//
//  Created by Lulin Yang on 2025/6/30.
//

import SwiftUI
import SharingGRDB

@MainActor
@Observable
class CheckInHistoryViewModel {
    @ObservationIgnored
    @FetchAll(
        CheckIn
            .order(by: \.date)
            .leftJoin(Habit.all) {
                $0.habitID.eq($1.id)
            }
            .select {
                CheckInHistory.Columns(
                    checkIn: $0,
                    habitName: $1.name ?? "",
                    habitIcon: $1.icon ?? ""
                )
            },
        animation: .default
    )
    var checkinHistories
    
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    func onTapDeleteCheckin(_ checkin: CheckInHistory) {
        withErrorReporting {
            try database.write { db in
                try CheckIn.delete(checkin.checkIn).execute(db)
            }
        }
    }
}

struct CheckInHistoryView: View {
    @State private var viewModel = CheckInHistoryViewModel()
    
    var body: some View {
        Group {
            if viewModel.checkinHistories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Start checking in to track your habits!")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(.top, 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.checkinHistories, id: \.checkIn.id) { checkinHistory in
                        HStack(spacing: 16) {
                            // Habit Icon
                            Text(checkinHistory.habitIcon)
                                .font(.system(size: 32))

                            // Habit Info
                            VStack(alignment: .leading) {
                                Text(checkinHistory.habitName)
                                    .font(.headline)
                                Text(checkinHistory.checkIn.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            // Delete Button
                            Button(action: {
                                viewModel.onTapDeleteCheckin(checkinHistory)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Check-in History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
