import SwiftUI
import ScreammKit

/// The menu-bar stats card: streak, week row, lifetime metrics, time saved. A fully rounded
/// card (hosted in a borderless transparent window — no system arrow), with a spring entrance.
struct StatsPanel: View {
    let data: StatsData
    var calendar: Calendar = .current
    var onQuit: () -> Void = { NSApp.terminate(nil) }
    var onOpenSettings: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    private var isEmpty: Bool { data.totalDictations == 0 }

    var body: some View {
        VStack(spacing: 0) {
            streakHeader
            metrics
            footer
        }
        .frame(width: 300)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(.white.opacity(0.06), lineWidth: 1))
        .scaleEffect(appear || reduceMotion ? 1 : 0.97, anchor: .top)
        .opacity(appear || reduceMotion ? 1 : 0)
        .onAppear {
            if reduceMotion { appear = true }
            else { withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { appear = true } }
        }
    }

    // MARK: Streak header

    private var streakHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                AnimatedFlame(size: 42)
                Text("\(data.currentStreak)")
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .scaleEffect(appear || reduceMotion ? 1 : 0.7)
            .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.6), value: appear)
            // Deliberately NOT personalized: it's your Mac, you know whose streak it is.
            Text(isEmpty ? "Start your streak" : "day streak")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .textCase(.uppercase)
                .tracking(0.5)
            weekRow.padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(LinearGradient(colors: [Theme.brand, Theme.brandDeep],
                                   startPoint: .top, endPoint: .bottom))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isEmpty ? "No streak yet"
            : "\(data.currentStreak) day streak, \(data.totalWords) words dictated")
    }

    private var weekRow: some View {
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        return HStack(spacing: 9) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let active = data.wasActive(on: day, calendar: calendar)
                let isToday = calendar.isDateInToday(day)
                VStack(spacing: 5) {
                    Text(dayLetter(day))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(isToday ? 1 : 0.85))
                    ZStack {
                        Circle()
                            .fill(active ? .white : .white.opacity(0.12))
                            .overlay(Circle().strokeBorder(.white.opacity(isToday ? 0.9 : 0.35),
                                                           lineWidth: isToday ? 2 : 1.5))
                            .frame(width: 24, height: 24)
                        if active {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(Theme.brand)
                        }
                    }
                    .scaleEffect(appear || reduceMotion ? 1 : 0.4)
                    .opacity(appear || reduceMotion ? 1 : 0)
                    .animation(reduceMotion ? nil
                        : .spring(response: 0.4, dampingFraction: 0.7).delay(0.06 + Double(index) * 0.04),
                        value: appear)
                }
            }
        }
    }

    // MARK: Metrics (clean aligned row, Ahead/pushr style — no tinted background)

    private var metrics: some View {
        HStack(alignment: .top, spacing: 8) {
            metric(value: isEmpty ? "—" : compactWords, label: "words")
            divider
            metric(value: isEmpty ? "—" : "\(data.perDay.count)", label: "days")
            divider
            metric(value: isEmpty ? "—" : savedValue, label: "saved")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var divider: some View {
        Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1, height: 28)
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.4)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    /// Words: exact under 10k, compact "24.8k" above.
    private var compactWords: String {
        let w = data.totalWords
        if w >= 10_000 { return String(format: "%.1fk", Double(w) / 1000) }
        return w.formatted()
    }

    /// Estimated time saved. "~" reads as approximate; no cryptic "est".
    private var savedValue: String {
        let minutes = data.timeSavedMinutes
        if minutes >= 60 { return "~" + String(format: "%.1f", minutes / 60) + "h" }
        return "~\(Int(minutes.rounded()))m"
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button("Settings", action: onOpenSettings)
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.brand)
                Spacer()
                Button("Quit", action: onQuit)
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
        }
    }

    private func dayLetter(_ date: Date) -> String {
        let idx = calendar.component(.weekday, from: date) - 1
        let symbols = calendar.veryShortWeekdaySymbols
        return idx >= 0 && idx < symbols.count ? symbols[idx] : "?"
    }
}
