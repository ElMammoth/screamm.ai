import SwiftUI
import ScreammKit

struct OnboardingView: View {
    @ObservedObject var model: OnboardingModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let axTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            Spacer(minLength: 0)
            content
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
            skip
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.82), value: model.card)
        .onReceive(axTimer) { _ in
            if !model.axGranted && Permissions.isAccessibilityTrusted {
                model.axGranted = true
                if model.card == .accessibility { model.advance() }
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule().fill(Theme.brand).frame(width: geo.size.width * model.progress)
            }
        }
        .frame(height: 8)
        .padding(.horizontal, 20).padding(.top, 20)
    }

    @ViewBuilder private var content: some View {
        switch model.card {
        case .welcome:       welcomeCard
        case .mic:           micCard
        case .accessibility: axCard
        case .tryIt:         tryCard
        }
    }

    // MARK: Cards

    private var welcomeCard: some View {
        VStack(spacing: 22) {
            pill
            Text("Talk. It types.\nEverywhere on your Mac.")
                .multilineTextAlignment(.center)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
            Text("100% on-device. Your voice never leaves this Mac.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            primaryButton("Get started") {
                model.startLoadIfNeeded()
                model.advance()
            }
        }
    }

    private var micCard: some View {
        permissionCard(
            symbol: "mic.fill",
            title: "Let Screamm hear you",
            body: "Screamm needs your microphone to turn speech into text. Nothing is recorded or uploaded.",
            granted: model.micGranted,
            grantedTitle: "Continue",
            ungrantedTitle: "Enable microphone"
        ) {
            if model.micGranted { model.advance(); return }
            Task {
                let ok = await Permissions.requestMicrophone()
                model.micGranted = ok
                if ok { model.advance() }
            }
        }
        .onAppear {
            if Permissions.microphoneStatus == .authorized { model.micGranted = true }
        }
    }

    private var axCard: some View {
        permissionCard(
            symbol: "accessibility",
            title: "Let it type for you",
            body: "So your words land in any app, Screamm needs Accessibility. Grant it in System Settings and come back.",
            granted: model.axGranted,
            grantedTitle: "Continue",
            ungrantedTitle: "Open Settings"
        ) {
            if model.axGranted { model.advance(); return }
            Permissions.promptAccessibility()
            Permissions.openAccessibilitySettings()
        }
        .onAppear { if Permissions.isAccessibilityTrusted { model.axGranted = true } }
    }

    private var tryCard: some View {
        VStack(spacing: 22) {
            if model.didDictate {
                circle(symbol: "checkmark", tint: Color(red: 0.2, green: 0.78, blue: 0.35))
                Text("Nice! You're all set.")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
            } else if model.modelReady {
                pill
                (Text("Hold ") + Text("Right ⌘").foregroundColor(Theme.brandDeep) + Text(" and say anything"))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("Then let go. Your text lands where your cursor is.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                circle(symbol: "arrow.down.circle", tint: Theme.brand)
                Text(model.modelFailed ? "Model download failed" : "Warming up the engine…")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                warmingProgress
            }
            primaryButton("Start using Screamm") { model.finish() }
        }
    }

    private var warmingProgress: some View {
        VStack(spacing: 8) {
            if let f = model.downloadFraction {
                ProgressView(value: f).tint(Theme.brand).frame(width: 220)
                Text("\(Int(f * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary).monospacedDigit()
            } else {
                ProgressView().controlSize(.small)
            }
            Text("One-time download (~1 min). You can finish now and try it later.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
    }

    // MARK: Pieces

    private var pill: some View {
        HStack(spacing: 3) {
            ForEach(0..<16, id: \.self) { i in
                Capsule().fill(.white)
                    .frame(width: 3, height: [10, 22, 34, 18, 28, 12, 24, 16][i % 8])
            }
        }
        .frame(height: 44).padding(.horizontal, 18)
        .background(Capsule().fill(LinearGradient(colors: [Theme.brand, Theme.brandDeep],
                                                  startPoint: .top, endPoint: .bottom))
            .shadow(color: Theme.brand.opacity(0.5), radius: 14, y: 3))
    }

    private func circle(symbol: String, tint: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 76, height: 76)
            .background(Circle().fill(tint))
    }

    private func permissionCard(symbol: String, title: String, body: String, granted: Bool,
                                grantedTitle: String, ungrantedTitle: String,
                                action: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            circle(symbol: granted ? "checkmark" : symbol,
                   tint: granted ? Color(red: 0.2, green: 0.78, blue: 0.35) : Theme.brand)
            Text(title).font(.system(size: 24, weight: .heavy, design: .rounded))
            Text(body)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            primaryButton(granted ? grantedTitle : ungrantedTitle, action: action)
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.brand)
                    .shadow(color: Theme.brand.opacity(0.4), radius: 8, y: 3))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.defaultAction)
        .frame(maxWidth: 300)
    }

    private var skip: some View {
        Button("Maybe later") { model.finish() }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .keyboardShortcut(.cancelAction)
            .padding(.bottom, 18)
    }
}
