//
//  CheckinHistoryView.swift
//  LongevityMaster
//
//  Created by Lulin Yang on 2025/6/30.
//

import SwiftUI
import SQLiteData

@MainActor
@Observable
class CheckInHistoryViewModel {
    /// Read a page at a time rather than the whole table. The join was fetching every
    /// check-in the user has ever made — and re-running on every write anywhere in the app,
    /// since it is an observed query — which only gets worse the longer someone sticks with
    /// the habit of checking in.
    private static let pageSize = 100

    private static func page(limit: Int) -> some StructuredQueriesCore.Statement<CheckInHistory> {
        CheckIn
            // Newest first: this is a history, and the entry someone wants to look at or
            // undo is almost always the one they just made.
            .order { $0.date.desc() }
            .leftJoin(Habit.all) {
                $0.habitID.eq($1.id)
            }
            .select {
                CheckInHistory.Columns(
                    checkIn: $0,
                    habitName: $1.name ?? "",
                    habitIcon: $1.icon ?? ""
                )
            }
            .limit(limit)
    }

    @ObservationIgnored
    @FetchAll(CheckInHistoryViewModel.page(limit: CheckInHistoryViewModel.pageSize), animation: .default)
    var checkinHistories

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    private var limit = pageSize
    private var isLoadingPage = false

    /// Stops the list asking for more once a page comes back short, which is how the end of
    /// the table announces itself.
    private var hasMore = true

    /// Called as the last row appears. Every row appearing near the end asks, so this has to
    /// be cheap and idempotent when there is nothing left to load.
    func onAppearOfRow(_ history: CheckInHistory) async {
        guard hasMore,
              !isLoadingPage,
              history.checkIn.id == checkinHistories.last?.checkIn.id
        else { return }

        isLoadingPage = true
        defer { isLoadingPage = false }

        let previousCount = checkinHistories.count
        limit += Self.pageSize

        await withErrorReporting {
            try await $checkinHistories.load(Self.page(limit: limit))
        }

        hasMore = checkinHistories.count > previousCount
    }

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
                        .task {
                            await viewModel.onAppearOfRow(checkinHistory)
                        }
                    }
                }
            }
        }
        .navigationTitle("Check-in History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
