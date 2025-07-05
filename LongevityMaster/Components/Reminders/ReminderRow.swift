//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct ReminderRow: View {
    let time: Date
    let title: String
    let onDelete: (() -> Void)?
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "alarm")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Spacer()
                Text(time, format: .dateTime.hour().minute())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(width: 90)
            
            
            Divider()
                .frame(maxHeight: 20)
           
            Text(title)
                .font(.body)
            
            Spacer()
            
            if let onDelete {
                HStack(spacing: 4) {
                    Button(action: {
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 12) {
        ReminderRow(
            time: Date(),
            title: "Drink Water",
            onDelete: {}
        )
        
        ReminderRow(
            time: Date(),
            title: "Drink Water",
            onDelete: {}
        )
    }
    .padding()
} 
