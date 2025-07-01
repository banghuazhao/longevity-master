//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct ReminderDraftRow: View {
    let reminder: Reminder.Draft
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "alarm")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text(reminder.time, format: .dateTime.hour().minute())
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            
            Divider()
                .frame(maxHeight: 20)
           
            Text("Every Day")
                .font(.body)
            
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
        ReminderDraftRow(
            reminder: Reminder.Draft(
                Reminder(
                    id: 0,
                    title: "Drink Water",
                    time: Date()
                )
            ),
            onDelete: {}
        )
        
        ReminderDraftRow(
            reminder:  Reminder.Draft(
                Reminder(
                    id: 1,
                    title: "Exercise",
                    time: Date()
                )
            ),
            onDelete: {}
        )
    }
    .padding()
} 
