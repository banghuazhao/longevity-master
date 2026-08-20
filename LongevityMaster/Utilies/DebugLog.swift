//
// Created by Banghua Zhao on 20/08/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// Developer diagnostics that compile away in Release.
///
/// A bare `print` ships: it costs a string interpolation and a console write on every call —
/// including paths as hot as tapping a habit — and it puts consent, ad and purchase details
/// into a log that anyone attached to the device can read. The `@autoclosure` means the
/// message is not even built unless it is going to be printed.
func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
        print(message())
    #endif
}
