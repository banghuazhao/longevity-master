# Longevity Master 🏃‍♂️

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)

A modern habit-tracking iOS app built with SwiftUI and GRDB, designed to help users build and maintain habits that promote long-term health and longevity. Longevity Master focuses on evidence-based habits that contribute to healthy aging and overall well-being.

## 📱 Screenshots

<div align="center">
  <img src="screenshots/1.png" alt="Longevity Master Screenshot 1" width="250"/>
  <img src="screenshots/2.png" alt="Longevity Master Screenshot 2" width="250"/>
  <img src="screenshots/3.png" alt="Longevity Master Screenshot 3" width="250"/>
</div>

*The app features a clean, modern interface with habit cards, tracking views, and intuitive navigation designed to help users build lasting health habits.*

## ✨ Features

### 🎯 Core Functionality
- **Habit Tracking**: Create, edit, and track daily habits with customizable frequencies
- **Anti-Aging Rating System**: Each habit includes a 1-5 star rating based on scientific evidence for longevity benefits
- **Smart Categories**: Organized into 5 key areas:
  - 🍎 **Diet**: Nutrition and eating habits
  - 🏋️ **Exercise**: Physical activity and fitness
  - 😴 **Sleep**: Sleep quality and patterns
  - 🩺 **Preventive Health**: Medical checkups and screenings
  - 🧘 **Mental Health**: Stress management and cognitive health

### 🎨 User Experience
- **Modern SwiftUI Interface**: Clean, intuitive design following iOS design guidelines
- **Context Menus**: Quick access to edit, share, and delete actions
- **Customizable Habit Cards**: Color-coded with emoji icons and visual indicators
- **Flexible Scheduling**: Support for various frequency patterns:
  - Fixed days per week
  - N days each week
  - Fixed days per month
  - N days each month

### 💾 Data Management
- **GRDB Database**: Robust local data storage with SQLite
- **Real-time Updates**: Live data synchronization across the app
- **Data Persistence**: Reliable habit tracking history

## 🏗️ Architecture

### Tech Stack
- **SwiftUI 5.0**: Modern declarative UI framework
- **GRDB**: SQLite database with Swift integration
- **Observation Framework**: Reactive data binding
- **SwiftUINavigation**: Type-safe navigation handling

### Project Structure
```
LongevityMaster/
├── App/
│   └── LongevityMasterApp.swift          # App entry point
├── Components/
│   ├── Common/                           # Reusable UI components
│   │   ├── HabitCardView.swift
│   │   └── HabitItemView.swift
│   ├── Habits/                           # Habit management views
│   │   ├── HabitForm.swift
│   │   ├── HabitIconEdit.swift
│   │   ├── HabitsGallery.swift
│   │   └── HabitsList.swift
│   ├── Me/                               # User profile and settings
│   │   ├── AppItem.swift
│   │   ├── MeFeature.swift
│   │   └── MoreAppsView.swift
│   └── Today/                            # Daily habit tracking
│       ├── TodayView.swift
│       └── TodayViewModel.swift
├── Model/                                # Data models
│   ├── CheckIn.swift
│   ├── Habit.swift
│   └── TodayHabit.swift
├── Service/                              # Business logic and data services
│   ├── HabitIconColorDataSource.swift
│   ├── HabitIconDataSource.swift
│   └── HabitsDataStore.swift
└── Utilities/                            # Helper functions and extensions
    ├── Constants.swift
    ├── Extension/
    │   ├── Color+Extensions.swift
    │   ├── Date+Extension.swift
    │   └── Habit+Extension.swift
    ├── HashableObject.swift
    └── Schema.swift
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- macOS 14.0+ (for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/banghuazhao/longevity-master.git
   cd longevity-master
   ```

2. **Open in Xcode**
   ```bash
   open LongevityMaster.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run the app

### Development Setup

The project uses several key dependencies managed through Swift Package Manager:

- **GRDB**: Database layer
- **SwiftUINavigation**: Navigation handling
- **Observation**: Reactive programming

## 🔧 Configuration

### Database Setup
The app uses GRDB for local data storage. The database is automatically initialized when the app launches.

### Customization
- **Habit Categories**: Easily extend the `HabitCategory` enum to add new categories
- **Frequency Types**: Modify `HabitFrequency` to support different scheduling patterns
- **UI Themes**: Customize colors and styling in the `Constants.swift` file

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### Development Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Swift style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure all code compiles without warnings

### Testing
- Test on both iPhone and iPad simulators
- Verify functionality across different iOS versions
- Test edge cases and error scenarios

## 📄 License

This project is licensed under the **Creative Commons Attribution-NonCommercial 4.0 International License** ([CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/)).

This means you can:
- ✅ Use, share, and modify the code for non-commercial purposes
- ✅ Distribute the code with proper attribution
- ❌ Use the code for commercial purposes without permission

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/banghuazhao/longevity-master/issues)
- **Discussions**: [GitHub Discussions](https://github.com/banghuazhao/longevity-master/discussions)
- **Email**: Open an issue for direct contact

## 🗺️ Roadmap

### Upcoming Features
- [ ] Habit streak tracking and statistics
- [ ] Reminder notifications
- [ ] Data export and backup
- [ ] Social sharing of achievements
- [ ] Integration with HealthKit
- [ ] Dark mode support
- [ ] iPad optimization

### Long-term Goals
- [ ] Achievements
- [ ] AI powered scientific habit recommendations
- [ ] Community features

## 🙏 Acknowledgments

- Built with ❤️ using SwiftUI and modern iOS development practices
- Inspired by scientific research on longevity and healthy aging
- Thanks to the open-source community for amazing tools and libraries

---

**Made with ❤️ by [Banghua Zhao](https://github.com/banghuazhao)**

*Empowering users to build habits that last a lifetime* 🌟
