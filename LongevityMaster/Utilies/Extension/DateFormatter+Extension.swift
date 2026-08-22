//
// Created by Banghua Zhao on 20/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

extension DateFormatter {
    /// A shared medium-style date formatter.
    ///
    /// `DateFormatter` is one of the more expensive Foundation objects to build, and these were
    /// being constructed inside computed properties and view bodies — once per render, and in
    /// the yearly calendar once per month cell. Formatting off a shared instance is safe; only
    /// mutating one is not, and nothing here mutates it after setup.
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
