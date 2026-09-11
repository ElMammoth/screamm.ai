import SwiftUI

/// Screammy's expression. Driven by the recording state — he only exists while you dictate.
enum ScreammyMood { case idle, listening, thinking, success }

/// Screammy: the orange squid who sits on top of the waveform pill and wraps it with his
/// tentacles. Flat vector style (Duolingo-adjacent): thick rounded shapes, one bold orange,
/// a darker orange underside on every limb for depth, big eyes, teal handlebar moustache.
///
/// **Everything is drawn in ONE `Canvas`.** That's deliberate, not stylistic: a Canvas is a
/// single draw pass with no view-tree diffing, so ~14 animated shapes cost roughly what one
/// costs. This runs *while Whisper is decoding on the ANE*, and the decode budget (~1.83s warm)
/// must not move. For the same reason the timeline ticks at 30fps, not display rate — a gentle
/// sway reads identically at 30 and costs half as much on a 120Hz panel.
///
/// Reduced motion → a static pose per mood (never one frozen frame that reads as broken).
struct ScreammyView: View {
    let mood: ScreammyMood
    /// Live mic level 0...1 — makes the tentacles pulse with your voice while listening.
    let level: CGFloat
    /// The pill's measured rect. The squid is laid out around it.
    let pillSize: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let m = Screammy.Metrics(pillSize: pillSize)
        Group {
            if reduceMotion {
                Canvas { ctx, size in
                    Screammy.draw(ctx, size: size, m: m, mood: mood, level: level,
                                  t: Screammy.staticPose, animated: false)
                }
            } else {
                // 30fps: enough for a sway, half the work of display-rate on ProMotion.
                TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { ctx, size in
                        Screammy.draw(ctx, size: size, m: m, mood: mood, level: level,
                                      t: t, animated: true)
                    }
                }
            }
        }
        .frame(width: m.canvas.width, height: m.canvas.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Drawing

enum Screammy {

    /// A pose that reads as "alive but still" for the reduced-motion path.
    static let staticPose: TimeInterval = 0.8

    // Palette, sampled from the reference art.
    static let shell = Theme.brand                                              // #F48C02
    static let shade = Color(red: 0.855, green: 0.376, blue: 0.047)             // #DA600C underside
    static let gloss = Color(red: 0.980, green: 0.702, blue: 0.427)             // #FAB36D highlight
    static let ink   = Color(red: 0.137, green: 0.373, blue: 0.420)             // #235F6B moustache
    static let pupil = Color(red: 0.169, green: 0.227, blue: 0.259)             // #2B3A42
    /// The reference art puts an orange squid on a PALE pill. Ours sits on the brand-orange
    /// pill, so figure and ground share a hue and the tentacles disappear into it. This deep
    /// contour is what buys the separation back — and it reads as deliberate flat-vector
    /// linework rather than a workaround.
    static let outline = Color(red: 0.639, green: 0.278, blue: 0.008)           // #A34702

    /// All geometry derives from the pill, so the squid scales with it and — critically — the
    /// vertical space he needs depends only on the pill HEIGHT, which is a compile-time
    /// constant. That's what lets the panel reserve his space without measuring first.
    struct Metrics {
        let pillSize: CGSize
        /// How far the tentacles reach past each end of the pill.
        let overhang: CGFloat
        /// Empty space reserved above the pill for the head.
        let headSpace: CGFloat
        let headR: CGFloat

        init(pillSize: CGSize) {
            self.pillSize = pillSize
            self.headR = Self.headRadius(pillHeight: pillSize.height)
            self.overhang = Self.overhang(pillHeight: pillSize.height)
            self.headSpace = Self.headSpace(pillHeight: pillSize.height)
        }

        /// Reference ratio: the head is ~0.40 of the pill's width. Tying it to the pill HEIGHT
        /// instead keeps it constant regardless of how many waveform bars are showing.
        static func headRadius(pillHeight: CGFloat) -> CGFloat { pillHeight * 0.82 }
        static func overhang(pillHeight: CGFloat) -> CGFloat { pillHeight * 0.46 }
        /// Head diameter + a little breathing room at the very top.
        static func headSpace(pillHeight: CGFloat) -> CGFloat { headRadius(pillHeight: pillHeight) * 2 + 9 }

        var canvas: CGSize {
            CGSize(width: pillSize.width + overhang * 2, height: headSpace + pillSize.height)
        }

        // Landmarks in canvas coordinates.
        var pillLeft: CGFloat { overhang }
        var pillRight: CGFloat { overhang + pillSize.width }
        var pillTop: CGFloat { headSpace }
        var pillMidY: CGFloat { pillTop + pillSize.height / 2 }
        var cx: CGFloat { overhang + pillSize.width / 2 }
        /// The head dips slightly behind the pill's top edge so the tentacle roots are hidden.
        var headBottomY: CGFloat { pillTop + 1 }
        var headCY: CGFloat { headBottomY - headR }
    }

    static func draw(_ ctx: GraphicsContext, size: CGSize, m: Metrics,
                     mood: ScreammyMood, level: CGFloat, t: TimeInterval, animated: Bool) {

        // Sway amplitude: idle breathes, listening pulses with your voice, success bounces.
        let amp: CGFloat = {
            guard animated else { return 1.4 }
            switch mood {
            case .idle:      return 2.0
            case .listening: return 2.2 + min(1, max(0, level)) * 5.0
            case .thinking:  return 3.0
            case .success:   return 4.0
            }
        }()
        let wave = { (phase: Double) -> CGFloat in
            animated ? amp * CGFloat(sin(t * 1.7 + phase)) : amp * CGFloat(sin(phase))
        }
        // A little lift on success, and a slow "pondering" rise while thinking.
        let bob: CGFloat = {
            guard animated else { return 0 }
            switch mood {
            case .success:  return -3.5
            case .thinking: return CGFloat(sin(t * 1.15)) * 1.6
            default:        return CGFloat(sin(t * 0.9)) * 0.9
            }
        }()

        // Tentacles first — the head is drawn over their roots.
        drawTentacles(ctx, m: m, mood: mood, wave: wave, bob: bob)
        drawHead(ctx, m: m, bob: bob)
        drawFace(ctx, m: m, mood: mood, t: t, bob: bob, animated: animated)
    }

    // MARK: Tentacles

    /// Three passes per limb: the deep contour, the bright shell, then a thin darker line hugging
    /// the underside. The contour is what makes an orange tentacle legible on an orange pill;
    /// the underside line is what stops it looking like a flat noodle.
    private static func limb(_ ctx: GraphicsContext, _ path: Path, width: CGFloat) {
        func style(_ w: CGFloat) -> StrokeStyle {
            StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round)
        }
        ctx.stroke(path, with: .color(outline), style: style(width + 3.0))
        ctx.stroke(path, with: .color(shell), style: style(width))
        ctx.stroke(path.offsetBy(dx: 0, dy: width * 0.30),
                   with: .color(shade), style: style(width * 0.34))
    }

    private static func drawTentacles(_ ctx: GraphicsContext, m: Metrics, mood: ScreammyMood,
                                      wave: (Double) -> CGFloat, bob: CGFloat) {
        let r = m.headR
        let pillH = m.pillSize.height
        let pillW = m.pillSize.width
        // Thinking curls the tips inward, like he's mulling it over.
        let curl: CGFloat = mood == .thinking ? 5 : 0

        for side in [CGFloat(-1), 1] {
            let x = { (v: CGFloat) in m.cx + side * v }

            // 1. The long outer arm: sweeps out along the pill's top edge, hooks down around the
            //    end, and curls back under. This is the "englobing" move from the reference.
            let a = wave(side > 0 ? 0.9 : 0)
            let end = pillW * 0.5 + m.overhang * 0.60
            var outer = Path()
            outer.move(to: CGPoint(x: x(r * 0.50), y: m.headBottomY - 9 + bob))
            outer.addCurve(
                to: CGPoint(x: x(pillW * 0.34), y: m.pillTop + 1),
                control1: CGPoint(x: x(r * 1.15), y: m.headBottomY - 2 + bob),
                control2: CGPoint(x: x(pillW * 0.24), y: m.pillTop - 2 + a))
            outer.addCurve(
                to: CGPoint(x: x(end), y: m.pillMidY + 5 + a - curl),
                control1: CGPoint(x: x(pillW * 0.49), y: m.pillTop + 1),
                control2: CGPoint(x: x(end + 2), y: m.pillTop + 6))
            // The tip curls back inward so it reads as a tentacle, not a drip.
            outer.addQuadCurve(
                to: CGPoint(x: x(end - m.overhang * 0.38), y: m.pillMidY + 12 + a),
                control: CGPoint(x: x(end + m.overhang * 0.05), y: m.pillMidY + 15 + a))
            limb(ctx, outer, width: r * 0.21)

            // 2. A shorter mid arm resting on the pill, curling down onto its face.
            let b = wave(side > 0 ? 2.1 : 1.4)
            var mid = Path()
            mid.move(to: CGPoint(x: x(r * 0.26), y: m.headBottomY - 5 + bob))
            mid.addCurve(
                to: CGPoint(x: x(pillW * 0.32), y: m.pillTop + pillH * 0.17 + b * 0.5 - curl * 0.4),
                control1: CGPoint(x: x(r * 0.85), y: m.headBottomY + 3 + bob),
                control2: CGPoint(x: x(pillW * 0.33), y: m.pillTop + 1))
            limb(ctx, mid, width: r * 0.185)

            // 3. The pair that hangs straight down in front of the pill.
            let c = wave(side > 0 ? 3.3 : 2.7)
            var front = Path()
            front.move(to: CGPoint(x: x(r * 0.09), y: m.headBottomY - 8 + bob))
            front.addCurve(
                to: CGPoint(x: x(r * 0.40 + c * 0.4), y: m.pillTop + pillH * 0.26 + curl * 0.3),
                control1: CGPoint(x: x(r * 0.12), y: m.headBottomY + 4 + bob),
                control2: CGPoint(x: x(r * 0.16 + c), y: m.pillTop + pillH * 0.22))
            limb(ctx, front, width: r * 0.17)
        }
    }

    // MARK: Head

    private static func drawHead(_ ctx: GraphicsContext, m: Metrics, bob: CGFloat) {
        let r = m.headR
        let cy = m.headCY + bob
        // Very slightly taller than wide, like the reference dome.
        let rect = CGRect(x: m.cx - r, y: cy - r * 1.04, width: r * 2, height: r * 2.08)
        ctx.fill(Path(ellipseIn: rect.insetBy(dx: -1.6, dy: -1.6)), with: .color(outline))
        ctx.fill(Path(ellipseIn: rect), with: .color(shell))

        // Glossy highlight, top-left, tilted.
        let c = CGPoint(x: m.cx - r * 0.46, y: cy - r * 0.58)
        var hl = Path(ellipseIn: CGRect(x: c.x - r * 0.24, y: c.y - r * 0.13,
                                        width: r * 0.48, height: r * 0.26))
        hl = hl.applying(CGAffineTransform(translationX: -c.x, y: -c.y)
            .concatenating(CGAffineTransform(rotationAngle: -0.55))
            .concatenating(CGAffineTransform(translationX: c.x, y: c.y)))
        ctx.fill(hl, with: .color(gloss))
    }

    // MARK: Face

    private static func drawFace(_ ctx: GraphicsContext, m: Metrics, mood: ScreammyMood,
                                 t: TimeInterval, bob: CGFloat, animated: Bool) {
        let r = m.headR
        let hx = m.cx
        let cy = m.headCY + bob

        // Where he's looking. Up while thinking, slightly up-left otherwise (as in the ref).
        let look: CGPoint = {
            switch mood {
            case .thinking:  return CGPoint(x: 0.10, y: -0.48)
            case .listening: return CGPoint(x: -0.14, y: -0.26)
            default:         return CGPoint(x: -0.20, y: -0.22)
            }
        }()

        // Blink: a quick close/open every ~3.6s. 1 = wide open.
        let openness: CGFloat = {
            guard animated else { return 1 }
            let cycle = t.truncatingRemainder(dividingBy: 3.6)
            guard cycle < 0.13 else { return 1 }
            return max(0.10, CGFloat(abs(cycle - 0.065) / 0.065))
        }()

        let eyeY = cy - r * 0.22
        // The left eye is a touch larger — the asymmetry is what makes him read as drawn
        // rather than generated.
        let eyes: [(x: CGFloat, rx: CGFloat, ry: CGFloat)] = [
            (hx - r * 0.37, r * 0.35, r * 0.40),
            (hx + r * 0.35, r * 0.31, r * 0.36)
        ]

        for e in eyes {
            if mood == .success {
                // Happy squint: a rising arc instead of an eye.
                var arc = Path()
                arc.move(to: CGPoint(x: e.x - e.rx, y: eyeY + e.ry * 0.30))
                arc.addQuadCurve(to: CGPoint(x: e.x + e.rx, y: eyeY + e.ry * 0.30),
                                 control: CGPoint(x: e.x, y: eyeY - e.ry * 0.95))
                ctx.stroke(arc, with: .color(pupil),
                           style: StrokeStyle(lineWidth: r * 0.13, lineCap: .round))
                continue
            }

            let ry = e.ry * openness
            ctx.fill(Path(ellipseIn: CGRect(x: e.x - e.rx, y: eyeY - ry,
                                            width: e.rx * 2, height: ry * 2)),
                     with: .color(.white))

            // Pupil rides toward the look direction, and squashes with the blink.
            let pr = min(e.rx, ry) * 0.56
            guard pr > 0.4 else { continue }
            let px = e.x + look.x * (e.rx - pr) * 1.1
            let py = eyeY + look.y * (ry - pr) * 1.1
            ctx.fill(Path(ellipseIn: CGRect(x: px - pr, y: py - pr * min(1, openness * 1.6),
                                            width: pr * 2, height: pr * 2 * min(1, openness * 1.6))),
                     with: .color(pupil))
        }

        // Eyebrows — thin, raised, expressive. They do most of the emotional work.
        let browLift: CGFloat = mood == .thinking ? r * 0.07 : 0
        for (i, e) in eyes.enumerated() {
            var brow = Path()
            let tilt = (i == 0 ? -1.0 : 1.0) * (mood == .thinking ? r * 0.05 : 0)
            brow.move(to: CGPoint(x: e.x - e.rx * 0.92, y: eyeY - e.ry * 1.24 - browLift + tilt))
            brow.addQuadCurve(
                to: CGPoint(x: e.x + e.rx * 0.86, y: eyeY - e.ry * 1.32 - browLift - tilt),
                control: CGPoint(x: e.x, y: eyeY - e.ry * 1.70 - browLift))
            ctx.stroke(brow, with: .color(shade),
                       style: StrokeStyle(lineWidth: r * 0.10, lineCap: .round))
        }

        // The moustache. Two curled arms + a centre lobe — his whole identity, really.
        let mY = cy + r * 0.56
        let mW = r * 0.56
        for side in [CGFloat(-1), 1] {
            var arm = Path()
            arm.move(to: CGPoint(x: hx + side * r * 0.04, y: mY + r * 0.07))
            // Sweep outward, staying low...
            arm.addCurve(
                to: CGPoint(x: hx + side * mW, y: mY - r * 0.01),
                control1: CGPoint(x: hx + side * mW * 0.40, y: mY + r * 0.15),
                control2: CGPoint(x: hx + side * mW * 0.84, y: mY + r * 0.11))
            // ...then hook up and back in. That upturned tip is what makes it a handlebar
            // and not a smile.
            arm.addQuadCurve(
                to: CGPoint(x: hx + side * mW * 0.78, y: mY - r * 0.24),
                control: CGPoint(x: hx + side * mW * 1.16, y: mY - r * 0.19))
            ctx.stroke(arm, with: .color(ink),
                       style: StrokeStyle(lineWidth: r * 0.155, lineCap: .round))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: hx - r * 0.12, y: mY - r * 0.02,
                                        width: r * 0.24, height: r * 0.19)),
                 with: .color(ink))

        // Little mouth peeking out below the moustache. Opens while he listens.
        let openMouth = (mood == .listening && animated)
        let mh = openMouth ? r * 0.24 : r * 0.17
        ctx.fill(Path(ellipseIn: CGRect(x: hx - r * 0.10, y: mY + r * 0.19,
                                        width: r * 0.20, height: mh)),
                 with: .color(ink))
    }
}
