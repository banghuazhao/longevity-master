//
//  Haptics.swift
//  LongevityMaster
//
//  Created by Lulin Yang on 2025/7/1.
//

import UIKit

struct Haptics {
    static func vibrateIfEnabled() {
        let isEnabled = UserDefaults.standard.bool(forKey: "vibrateEnabled")
        print("Vibration setting is \(isEnabled ? "ON" : "OFF")") // debug
        if isEnabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }
}
