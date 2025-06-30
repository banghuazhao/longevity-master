//
//  RemindersView.swift
//  LongevityMaster
//
//  Created by Lulin Yang on 2025/6/30.
//

import SwiftUI

struct RemindersView: View {
    @State private var dailyReminderEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Top info box
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    Text("To receive timely reminders, please set notification method on your phone to \"Immediate Push.\"")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow))
                .padding(.horizontal)

                // 2. Toggle reminder setting
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Remind me to log daily")
                            .font(.headline)

                        Spacer()

                        Toggle("", isOn: $dailyReminderEnabled)
                            .labelsHidden()
                    }

                    if dailyReminderEnabled {
                        HStack {
                            Label("21:18 Reminder", systemImage: "clock")
                            Spacer()
                            Button("Change Time") {
                                // TODO: Add time picker or action
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.orange)
                            .font(.subheadline)
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                .padding(.horizontal)

                // 3. Add Reminder Button
                Button(action: {
                    // TODO: Show add reminder UI
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add a Reminder")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // 4. Reminder Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Everyday")
                        .font(.headline)
                        .padding(.horizontal)

                    // Placeholder for reminders
                    reminderRow(time: "15:50", habitName: "Drink Water", iconName: "drop")
                }
                .padding(.top)

                // 5. Info Footer
                Text("At most 64 notifications allowed. Currently 4 set.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Reminder Row Placeholder
    private func reminderRow(time: String, habitName: String, iconName: String) -> some View {
        HStack {
            Label(time, systemImage: "alarm")
                .foregroundColor(.blue)

            Divider()

            Image(systemName: iconName)
                .resizable()
                .frame(width: 24, height: 24)
                .padding(6)
                .background(Circle().fill(Color.yellow.opacity(0.3)))

            Text(habitName)
                .font(.body)

            Spacer()

            Text("Everyday")
                .font(.caption)
                .padding(6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 2)
        .padding(.horizontal)
    }
}
