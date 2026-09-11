import SwiftUI
import Foundation

/// Rolling window of recent audio levels that drives the waveform bars.
@MainActor
final class WaveformModel: ObservableObject {
    @Published var levels: [CGFloat]
    @Published var isTranscribing: Bool = false
    /// Drives the spring pop-in / pop-out.
    @Published var appear: Bool = false
    /// Brief green ✓ micro-reward after a successful dictation.
    @Published var success: Bool = false
    let barCount: Int

    init(barCount: Int = 24) {
        self.barCount = barCount
        self.levels = Array(repeating: 0.06, count: barCount)
    }

    /// Push the newest level; scrolls the window left (like a real-time scope).
    func push(_ level: CGFloat) {
        var next = levels
        next.removeFirst()
        next.append(max(0.06, min(1, level)))
        levels = next
    }

    func reset() {
        levels = Array(repeating: 0.06, count: barCount)
        isTranscribing = false
        success = false
    }
}

/// The pill: a compact brand-orange capsule of live audio bars, Dynamic-Island sized,
/// with a playful spring pop (Duolingo-style micro-interaction).
struct WaveformView: View {
    @ObservedObject var model: WaveformModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let barWidth: CGFloat = 2.5
    private let barSpacing: CGFloat = 2.5
    private let maxBarHeight: CGFloat = 24
    private let capsuleHeight: CGFloat = 40
    private let successGreen = Color(red: 0.20, green: 0.78, blue: 0.35)

    private var fillColor: Color {
        if model.success { return successGreen }
        return model.isTranscribing ? Theme.brandDeep : Theme.brand
    }

    var body: some View {
        Group {
            if model.success {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Theme.content)
                    .frame(minWidth: 56)
            } else if model.isTranscribing {
                thinkingBars     // looping wave so processing never looks frozen
            } else {
                liveBars         // driven by live mic levels
            }
        }
        .frame(height: capsuleHeight)
        .padding(.horizontal, 14)
        .background(
            Capsule(style: .continuous)
                .fill(fillColor)
                .shadow(color: fillColor.opacity(0.5), radius: 16, y: 2)
        )
        .animation(.easeOut(duration: 0.09), value: model.levels)
        .animation(.easeInOut(duration: 0.2), value: model.isTranscribing)
        .animation(.easeInOut(duration: 0.15), value: model.success)
        // Playful spring pop-in / pop-out.
        .scaleEffect(model.appear ? 1 : 0.8)
        .opacity(model.appear ? 1 : 0)
        .animation(reduceMotion ? .easeOut(duration: 0.12)
            : .spring(response: 0.32, dampingFraction: 0.62), value: model.appear)
        .fixedSize()
        // Generous transparent margin so the soft glow fades fully to zero inside the
        // panel instead of being clipped into a visible rectangle. Must exceed the
        // shadow radius (16) + offset.
        .padding(30)
    }

    /// Bars driven by live mic levels (while recording).
    private var liveBars: some View {
        HStack(spacing: barSpacing) {
            ForEach(Array(model.levels.enumerated()), id: \.offset) { _, level in
                Capsule().fill(Theme.content.opacity(0.95))
                    .frame(width: barWidth, height: 4 + level * maxBarHeight)
            }
        }
    }

    /// A continuously looping wave (Claude-pill style) so the processing phase never freezes.
    /// Reduced motion → a stable, non-animating processing indicator instead.
    @ViewBuilder private var thinkingBars: some View {
        if reduceMotion {
            HStack(spacing: barSpacing) {
                ForEach(0..<model.barCount, id: \.self) { _ in
                    Capsule().fill(Theme.content.opacity(0.8))
                        .frame(width: barWidth, height: 4 + maxBarHeight * 0.45)
                }
            }
        } else {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                HStack(spacing: barSpacing) {
                    ForEach(0..<model.barCount, id: \.self) { i in
                        let norm = 0.5 + 0.5 * sin(t * 3.2 + Double(i) * 0.34)
                        Capsule().fill(Theme.content.opacity(0.9))
                            .frame(width: barWidth, height: 4 + norm * maxBarHeight * 0.75)
                    }
                }
            }
        }
    }
}
