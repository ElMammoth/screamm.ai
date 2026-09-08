import SwiftUI

/// Rolling window of recent audio levels that drives the waveform bars.
@MainActor
final class WaveformModel: ObservableObject {
    @Published var levels: [CGFloat]
    @Published var isTranscribing: Bool = false
    /// Drives the spring pop-in / pop-out.
    @Published var appear: Bool = false
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
    }
}

/// The pill: a compact brand-orange capsule of live audio bars, Dynamic-Island sized,
/// with a playful spring pop (Duolingo-style micro-interaction).
struct WaveformView: View {
    @ObservedObject var model: WaveformModel

    private let barWidth: CGFloat = 2.5
    private let barSpacing: CGFloat = 2.5
    private let maxBarHeight: CGFloat = 24
    private let capsuleHeight: CGFloat = 40

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(Array(model.levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(Theme.content.opacity(model.isTranscribing ? 0.55 : 0.95))
                    .frame(width: barWidth, height: 4 + level * maxBarHeight)
            }
        }
        .frame(height: capsuleHeight)
        .padding(.horizontal, 14)
        .background(
            Capsule(style: .continuous)
                .fill(model.isTranscribing ? Theme.brandDeep : Theme.brand)
                .shadow(color: Theme.brand.opacity(0.5), radius: 16, y: 2)
        )
        .animation(.easeOut(duration: 0.09), value: model.levels)
        .animation(.easeInOut(duration: 0.2), value: model.isTranscribing)
        // Playful spring pop-in / pop-out.
        .scaleEffect(model.appear ? 1 : 0.8)
        .opacity(model.appear ? 1 : 0)
        .animation(.spring(response: 0.32, dampingFraction: 0.62), value: model.appear)
        .fixedSize()
        // Generous transparent margin so the soft glow fades fully to zero inside the
        // panel instead of being clipped into a visible rectangle. Must exceed the
        // shadow radius (16) + offset.
        .padding(30)
    }
}
