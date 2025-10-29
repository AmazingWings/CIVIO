import SwiftUI

struct ColorTheme {
    // Primary green-blue environmental colors
    static let primaryGreen = Color(red: 0.0, green: 0.6, blue: 0.4) // Teal green
    static let primaryBlue = Color(red: 0.0, green: 0.4, blue: 0.8) // Ocean blue
    
    // Secondary colors
    static let lightGreen = Color(red: 0.4, green: 0.8, blue: 0.6) // Light mint
    static let lightBlue = Color(red: 0.6, green: 0.8, blue: 1.0) // Light sky blue
    
    // Background colors
    static let backgroundGradientStart = Color(red: 0.95, green: 0.98, blue: 0.97) // Very light mint
    static let backgroundGradientEnd = Color(red: 0.95, green: 0.97, blue: 1.0) // Very light blue
    
    // Text colors
    static let primaryText = Color(red: 0.2, green: 0.3, blue: 0.3) // Dark green-blue
    static let secondaryText = Color(red: 0.4, green: 0.5, blue: 0.5) // Medium green-blue
    
    // Accent colors
    static let accent = Color(red: 0.0, green: 0.7, blue: 0.5) // Bright teal
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4) // Bright green
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
    
    // Background gradient
    static let backgroundGradient = LinearGradient(
        colors: [backgroundGradientStart, backgroundGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Card background
    static let cardBackground = Color.white.opacity(0.8)
    
    // Shadow color
    static let shadow = Color.black.opacity(0.1)
}
