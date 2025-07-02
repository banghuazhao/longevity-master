//
//  SettingView.swift
//  LongevityMaster
//
//  Created by Lulin Yang on 2025/7/1.
//
import SwiftUI

struct SettingView: View {
    @AppStorage("startWeekOnMonday") private var startWeekOnMonday: Bool = true
    @AppStorage("buttonSoundEnabled") private var buttonSoundEnabled: Bool = true
    @AppStorage("vibrateEnabled") private var vibrateEnabled: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false //

    var body: some View {
        Form {
            // Week Start Selection
            Section(header: Text("Week Starts On")) {
                HStack {
                    Spacer()
                    Picker("Week Start", selection: $startWeekOnMonday) {
                        Text("Monday").tag(true)
                        Text("Sunday").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    Spacer()
                }
            }

            // Sound & Vibration
            Section(header: Text("Feedback")) {
                Toggle("Checkin Sound", isOn: $buttonSoundEnabled)
                Toggle("Vibrate", isOn: $vibrateEnabled)
            }

            // Appearance
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
            }
        }
        .navigationTitle("Settings")
        .preferredColorScheme(darkModeEnabled ? .dark : .light) //
    }
}
