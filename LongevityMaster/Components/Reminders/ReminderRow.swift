//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct ReminderRow: View {
    let reminder: Reminder
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Image(systemName: "alarm")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    Text(reminder.time, format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Text("Every day")
                    .font(.subheadline)
            }

            Divider()
                .frame(maxHeight: 20)

            Text(reminder.title)
                .font(.body)
                .lineLimit(2)

            Spacer()
            HStack(spacing: 4) {
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 12) {
        ReminderRow(
            reminder: Reminder(
                id: 0,
                title: "Drink Water",
                time: Date()

            ),
            onDelete: {}
        )

        ReminderRow(
            reminder: Reminder(
                id: 1,
                title: "Exercise",
                time: Date()

            ),
            onDelete: {}
        )
    }
    .padding()
}
