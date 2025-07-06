# MoreApps

A Swift Package Manager module that provides a reusable `MoreAppsView` for displaying a list of apps with localization support.

## Features

- **Localized Strings**: Supports English and Chinese (Simplified) localization
- **Reusable View**: Easy to integrate into any SwiftUI app
- **Customizable**: Can be initialized with custom app items
- **App Store Integration**: Direct links to App Store pages

## Usage

### Basic Usage

```swift
import MoreApps
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            MoreAppsView()
        }
    }
}
```

### Custom App Items

```swift
import MoreApps
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            MoreAppsView(apps: [
                AppItem(
                    title: "My App",
                    detail: "My App Description",
                    icon: UIImage(named: "myAppIcon"),
                    url: URL(string: "https://apps.apple.com/app/myapp")
                )
            ])
        }
    }
}
```

## Localization

The module includes localization for:
- English (en)
- Chinese Simplified (zh-Hans)

To add more languages, create additional `.lproj` folders in the `Resources` directory with corresponding `Localizable.strings` files.

## Requirements

- iOS 15.0+
- macOS 12.0+
- Swift 5.9+

## Installation

Add this package to your Xcode project:

1. In Xcode, go to File > Add Package Dependencies
2. Enter the package URL or select from your local file system
3. Choose the version you want to use
4. Click Add Package

## License

This module is part of the LongevityMaster project. 