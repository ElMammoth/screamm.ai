import SwiftUI
import Foundation

/// A living flame: the SF `flame.fill` licking up from its base with an organic, irregular
/// flicker (mixed sine frequencies), a gentle sway, and a soft pulsing heat-glow behind it.
/// Reduced motion → a static flame.
struct AnimatedFlame: View {
    var size: CGFloat = 36
    var color: Color = .white
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            flame(color)
        } else {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                // Irregular flicker: two frequencies so it never looks like a clean sine.
                let flick = sin(t * 9.0) * 0.6 + sin(t * 14.3) * 0.4          // -1...1
                let scaleY = 1.0 + 0.11 * flick                               // licks up/down
                let scaleX = 1.0 - 0.05 * flick                               // squash when tall
                let sway = 3.5 * sin(t * 4.2)                                 // degrees
                let glow = 0.35 + 0.35 * (0.5 + 0.5 * sin(t * 7.3))

                ZStack {
                    flame(.white)
                        .blur(radius: 7)
                        .opacity(glow)
                        .scaleEffect(x: scaleX * 1.05, y: scaleY * 1.08, anchor: .bottom)
                    flame(color)
                        .scaleEffect(x: scaleX, y: scaleY, anchor: .bottom)
                        .rotationEffect(.degrees(sway), anchor: .bottom)
                }
            }
        }
    }

    private func flame(_ c: Color) -> some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size))
            .foregroundStyle(c)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
    }
}
