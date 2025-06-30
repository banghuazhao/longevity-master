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
class CheckinHistoryViewModel {
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
}

struct CheckinHistoryView: View {
    var body: some View {
        List {
            ForEach(0 ..< 5) { _ in
                HStack(spacing: 16) {
                    // Habit Icon
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)

                    // Habit Info
                    VStack(alignment: .leading) {
                        Text("Habit Name Placeholder")
                            .font(.headline)
                        Text("Checked in at 9:00 AM")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer() // Push buttons to the right

                    // Edit Button
                    Button(action: {
                        // Edit action here
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                    }

                    // Delete Button
                    Button(action: {
                        // Delete action here
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Checkin History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
