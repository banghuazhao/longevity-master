import SwiftUI
import Dependencies
import Sharing

// MARK: - Theme Protocol
protocol AppTheme {
    var primaryColor: Color { get }
    var secondaryGray: Color { get }
    var background: Color { get }
    var card: Color { get }
    var accent: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
}

// MARK: - Default Theme
struct DefaultTheme: AppTheme {
    let primaryColor = Color(red: 1.0, green: 0.47, blue: 0.18) // #FF772F
    let secondaryGray = Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
    let background = Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
    let card = Color.white
    let accent = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500
    let success = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
    let warning = Color(red: 1.0, green: 0.80, blue: 0.0) // #FFCC00
    let error = Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30
    let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E
    let textSecondary = Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
}

struct DarkTheme: AppTheme {
    let primaryColor = Color(red: 1.0, green: 0.47, blue: 0.18) // #FF772F
    let secondaryGray = Color(red: 0.56, green: 0.56, blue: 0.58)
    let background = Color(red: 0.10, green: 0.10, blue: 0.12) // #1A1A1F
    let card = Color(red: 0.16, green: 0.16, blue: 0.18) // #29292E
    let accent = Color(red: 1.0, green: 0.58, blue: 0.0)
    let success = Color(red: 0.20, green: 0.78, blue: 0.35)
    let warning = Color(red: 1.0, green: 0.80, blue: 0.0)
    let error = Color(red: 1.0, green: 0.23, blue: 0.19)
    let textPrimary = Color.white
    let textSecondary = Color(red: 0.7, green: 0.7, blue: 0.75)
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var current: AppTheme = DefaultTheme()
    @Shared(.appStorage("darkModeEnabled")) private var darkModeEnabled: Bool = false
    
    init() {
        current = darkModeEnabled ? DarkTheme() : DefaultTheme()
    }

    func updateTheme(darkMode: Bool) {
        withAnimation {
            self.current = darkMode ? DarkTheme() : DefaultTheme()
        }
    }
}

// MARK: - DependencyKey for ThemeManager
private enum ThemeManagerKey: DependencyKey {
    static let liveValue = ThemeManager()
}

extension DependencyValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - Typography
struct AppFont {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title = Font.system(size: 28, weight: .semibold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let footnote = Font.system(size: 12, weight: .regular)
}

// MARK: - Spacing & Layout
struct AppSpacing {
    static let small: CGFloat = 8
    static let smallMedium: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
}

struct AppCornerRadius {
    static let card: CGFloat = 16
    static let button: CGFloat = 12
    static let avatar: CGFloat = 25
}

// MARK: - Shadows
struct AppShadow {
    static let card = ShadowStyle(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Reusable Modifiers
extension View {
    func appCardStyle(theme: AppTheme) -> some View {
        self
            .background(theme.card)
            .cornerRadius(AppCornerRadius.card)
            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
    }
    
    func appSectionHeader(theme: AppTheme) -> some View {
        self
            .font(AppFont.headline)
            .foregroundColor(theme.textPrimary)
            .padding(.vertical, AppSpacing.small)
    }
    
    func appButtonStyle(theme: AppTheme, filled: Bool = true) -> some View {
        self
            .font(AppFont.headline)
            .padding(.vertical, AppSpacing.small)
            .padding(.horizontal, AppSpacing.large)
            .background(filled ? theme.primaryColor : Color.clear)
            .foregroundColor(filled ? .white : theme.primaryColor)
            .cornerRadius(AppCornerRadius.button)
    }
} 
