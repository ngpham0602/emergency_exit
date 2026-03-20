import SwiftUI

enum AppTheme {
    // Backgrounds
    static let bg       = Color.black
    static let cardBg   = Color(white: 0.09)
    static let cardBg2  = Color(white: 0.13)
    static let cardBg3  = Color(white: 0.16)

    // Accents
    static let green    = Color(red: 0.22, green: 0.96, blue: 0.29)   // neon lime
    static let greenDim = Color(red: 0.22, green: 0.96, blue: 0.29).opacity(0.12)
    static let red      = Color(red: 0.90, green: 0.25, blue: 0.25)
    static let redDim   = Color(red: 0.90, green: 0.25, blue: 0.25).opacity(0.15)
    static let amber    = Color(red: 0.96, green: 0.62, blue: 0.04)

    // Typography
    static let textPri  = Color.white
    static let textSec  = Color(white: 0.50)
    static let textDim  = Color(white: 0.32)

    // UI chrome
    static let border   = Color.white.opacity(0.08)
    static let divider  = Color.white.opacity(0.06)

    // Emergency red palette
    static let emergencyBg     = Color(red: 0.91, green: 0.38, blue: 0.34)
    static let emergencyCard   = Color(red: 0.15, green: 0.06, blue: 0.06).opacity(0.85)
    static let emergencyBorder = Color.white.opacity(0.18)
}
