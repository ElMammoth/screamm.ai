import SwiftUI
import ScreammKit

/// A short confetti burst + a badge for a milestone. Reduced-motion → static badge, no confetti.
struct CelebrationView: View {
    let milestone: Milestone
    var profile: Profile = Profile()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    var body: some View {
        ZStack {
            if !reduceMotion {
                ConfettiView().allowsHitTesting(false)
            }
            badge
                .scaleEffect(reduceMotion ? 1 : (appear ? 1 : 0.6))
                .opacity(reduceMotion ? 1 : (appear ? 1 : 0))
        }
        .frame(width: 320, height: 220)
        .onAppear {
            if reduceMotion { appear = true }
            else { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { appear = true } }
        }
    }

    private var badge: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 66, height: 66)
                .background(Circle().fill(Theme.brand)
                    .shadow(color: Theme.brand.opacity(0.5), radius: 12, y: 3))
            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                // "Nice work, Alex" / "Nice work!" — nil-safe, never a dangling comma.
                Text(profile.addressed("Nice work"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18).padding(.vertical, 9)
            .background(Capsule().fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 3))
        }
    }

    private var symbol: String {
        switch milestone {
        case .firstDictation: return "sparkles"
        case .words1k, .words10k: return "checkmark.seal.fill"
        case .streak7, .streak30: return "flame.fill"
        }
    }

    private var title: String {
        switch milestone {
        case .firstDictation: return "First dictation!"
        case .words1k: return "1,000 words!"
        case .words10k: return "10,000 words!"
        case .streak7: return "7-day streak!"
        case .streak30: return "30-day streak!"
        }
    }
}

/// Lightweight confetti via Canvas + TimelineView. Bounded particle count; stops when the
/// hosting panel is removed.
private struct ConfettiView: View {
    private struct Particle {
        let x0: CGFloat, vx: CGFloat, vy: CGFloat, size: CGFloat, color: Color, spin: Double
    }
    private let start = Date()
    private let particles: [Particle]

    init() {
        let colors: [Color] = [Theme.brand, .white, Color(red: 0.2, green: 0.78, blue: 0.35),
                               .yellow, .pink]
        particles = (0..<70).map { _ in
            Particle(
                x0: .random(in: -30...30),
                vx: .random(in: -150...150),
                vy: .random(in: -280 ... -120),
                size: .random(in: 5...9),
                color: colors.randomElement()!,
                spin: .random(in: -6...6))
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { ctx, size in
                let cx = size.width / 2, cy = size.height / 2
                for p in particles {
                    let x = cx + p.x0 + p.vx * t
                    let y = cy + p.vy * t + 320 * t * t   // gravity
                    let opacity = max(0, 1 - t / 1.7)
                    guard opacity > 0 else { continue }
                    ctx.opacity = opacity
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(p.spin * t))
                    let rect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size * 0.6)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(p.color))
                    ctx.rotate(by: .radians(-p.spin * t))
                    ctx.translateBy(x: -x, y: -y)
                }
            }
        }
    }
}
