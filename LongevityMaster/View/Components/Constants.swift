//
//  Constants.swift
//  LongevityMaster
//
//  Created by Lulin Yang on 2025/6/27.
//

import Foundation
import UIKit

struct Constants {
    static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
    static let isMac = UIDevice.current.userInterfaceIdiom == .mac
}

extension String {
    struct Symbol {
        static let route = "🧭"
        static let place = "📍"
        static let accommodation = "🏨"
        static let restaurant = "🍔"
    }
}

let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    return formatter
}()
