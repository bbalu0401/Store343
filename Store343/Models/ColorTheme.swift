// ColorTheme.swift
// Lidl brand colors and adaptive color system

import SwiftUI

extension Color {
    // MARK: - Lidl Brand Colors
    static let lidlBlue = Color(red: 0/255, green: 80/255, blue: 170/255) // #0050AA
    static let lidlYellow = Color(red: 255/255, green: 237/255, blue: 0/255) // #FFED00
    static let lidlRed = Color(red: 226/255, green: 7/255, blue: 20/255) // #E20714

    // MARK: - Adaptive Colors (Dark/Light Mode)
    static func adaptiveBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    static func adaptiveCardBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6)
    }

    static func adaptiveText(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    static func adaptiveSecondaryText(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(.systemGray) : Color(.darkGray)
    }

    // MARK: - Hex Color Support
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
