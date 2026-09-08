import SwiftUI

/// Screamm brand palette. Duolingo-inspired: one bold, saturated brand color, high
/// white-on-color contrast, chunky rounded shapes, playful spring motion.
enum Theme {
    /// Primary brand orange — #F48C02
    static let brand = Color(red: 244.0 / 255.0, green: 140.0 / 255.0, blue: 2.0 / 255.0)
    /// A slightly deeper orange for the "thinking" state.
    static let brandDeep = Color(red: 214.0 / 255.0, green: 118.0 / 255.0, blue: 2.0 / 255.0)
    /// Bars / content sit white on the brand color.
    static let content = Color.white
}
