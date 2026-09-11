import Foundation
import ScreammKit

/// Drives the 4-card onboarding flow. Value-first: finishing is NEVER gated on the model
/// download (eng review) — only the optional "try it" waits for `.ready`.
@MainActor
final class OnboardingModel: ObservableObject {
    enum Card: Int, CaseIterable { case welcome, name, mic, accessibility, tryIt }

    @Published var card: Card = .welcome
    @Published var micGranted = false
    @Published var axGranted = false
    @Published var loadState: LoadState = .idle
    @Published var didDictate = false

    /// What the user typed on the name card. Optional the whole way through.
    @Published var name: String = ""

    /// Called once when the user leaves the welcome card — kick off the background download.
    var onKickoffLoad: () -> Void = {}
    /// Persists the name as soon as the user leaves the name card, so quitting mid-onboarding
    /// doesn't lose it.
    var onSaveName: (String) -> Void = { _ in }
    /// Called when onboarding is finished or skipped.
    var onFinish: () -> Void = {}

    /// The typed name, or nil — the single place the UI asks "do we have a name?"
    var trimmedName: String? {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private var kickedOff = false

    var progress: Double { Double(card.rawValue + 1) / Double(Card.allCases.count) }

    var modelReady: Bool { if case .ready = loadState { return true }; return false }

    var downloadFraction: Double? {
        if case .downloading(let f) = loadState { return f }
        return modelReady ? 1 : nil
    }

    var modelFailed: Bool { if case .failed = loadState { return true }; return false }

    func startLoadIfNeeded() {
        guard !kickedOff else { return }
        kickedOff = true
        onKickoffLoad()
    }

    func advance() {
        if card == .name { onSaveName(name) }
        if let next = Card(rawValue: card.rawValue + 1) {
            card = next
        } else {
            onFinish()
        }
    }

    func finish() {
        if card == .name { onSaveName(name) }   // "Maybe later" from the name card still keeps it
        onFinish()
    }
}
